DROP FUNCTION IF EXISTS wk_p_add_paragraph;

CREATE OR REPLACE FUNCTION wk_p_add_paragraph
(
	vr_application_id	UUID,
    vr_paragraph_id 	UUID,
    vr_title_id	 		UUID,
    vr_title			VARCHAR(500),
    vr_body_text		VARCHAR,
    vr_sequence_no		INTEGER,
    vr_current_user_id	UUID,
    vr_now				TIMESTAMP,
    vr_is_rich_text		BOOLEAN,
    vr_send_To_Admins	BOOLEAN,
    vr_has_admin		BOOLEAN
)
RETURNS INTEGER
AS
$$
DECLARE 
	vr_status		VARCHAR(20);
	vr_change_id 	UUID;
BEGIN
	vr_title := gfn_verify_string(vr_title);
	vr_body_text := gfn_verify_string(vr_body_text);
	
	vr_has_admin := COALESCE(vr_has_admin, FALSE)::BOOLEAN;
	
	IF COALESCE(vr_send_to_admins, FALSE)::BOOLEAN = FALSE THEN 
		vr_status := 'Accepted';
	ELSEIF vr_has_admin = FALSE THEN 
		vr_status := 'CitationNeeded';
	ELSE 
		vr_status := 'Pending';
	END IF;
	
	-- Update All Sequence Numbers
	UPDATE wk_paragraphs
	SET sequence_no = rf.sequence_no::INTEGER
	FROM (
			SELECT	"p".paragraph_id,
					(ROW_NUMBER() OVER (ORDER BY "p".deleted ASC, "p".sequence_no ASC)) * 2 AS sequence_no
			FROM wk_paragraphs AS "p"
			WHERE "p".application_id = vr_application_id AND "p".title_id = vr_title_id
		) AS rf
		INNER JOIN wk_paragraphs AS "p"
		ON "p".application_id = vr_application_id AND "p".paragraph_id = rf.paragraph_id;
		
	IF COALESCE(vr_sequence_no, 0) <= 0 THEN
		vr_sequence_no := 1::INTEGER;
	END IF;
	
	vr_sequence_no := (vr_sequence_no * 2) - 1;
	-- end of Update All Sequence Numbers
	
	INSERT INTO wk_paragraphs (
		application_id,
		paragraph_id,
		title_id,
		creator_user_id,
		creation_date,
		title,
		body_text,
		sequence_no,
		is_rich_text,
		status,
		deleted
	)
	VALUES (
		vr_application_id,
		vr_paragraph_id,
		vr_title_id,
		vr_current_user_id,
		vr_now,
		vr_title,
		vr_body_text,
		vr_sequence_no,
		vr_is_rich_text,
		vr_status,
		FALSE
	);
	
	vr_change_id := gen_random_uuid();
	
	INSERT INTO wk_changes (
		application_id,
		change_id,
		paragraph_id,
		user_id,
		send_date,
		title,
		body_text,
		applied,
		status,
		deleted
	)
	VALUES (
		vr_application_id,
		vr_change_id,
		vr_paragraph_id,
		vr_current_user_id,
		vr_now,
		vr_title,
		vr_body_text,
		CASE WHEN vr_status = 'CitationNeeded' OR vr_status = 'Accepted' THEN TRUE ELSE FALSE END::BOOLEAN,
		CASE WHEN vr_status = 'CitationNeeded' OR vr_status = 'Accepted' THEN 'Accepted' ELSE 'Pending' END,
		FALSE
	);
	
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

