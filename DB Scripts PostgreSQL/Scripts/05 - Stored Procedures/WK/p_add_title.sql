DROP FUNCTION IF EXISTS wk_p_add_title;

CREATE OR REPLACE FUNCTION wk_p_add_title
(
	vr_application_id	UUID,
    vr_title_id	 		UUID,
    vr_owner_id			UUID,
    vr_title			VARCHAR(500),
    vr_sequence_no		INTEGER,
    vr_current_user_id	UUID,
    vr_now				TIMESTAMP,
    vr_owner_type		VARCHAR(20),
    vr_accept			BOOLEAN
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_status 	VARCHAR(20);
	vr_result	INTEGER;
BEGIN
	vr_title := gfn_verify_string(LTRIM(RTRIM(vr_title)));
	
	IF COALESCE(vr_title, '') = '' THEN
		RETURN -1::INTEGER;
	END IF;
	
	IF vr_accept = TRUE THEN
		vr_status := 'Accepted';
	ELSE
		vr_status := 'CitationNeeded';
	END IF;
	
	-- Update All Sequence Numbers
	UPDATE wk_titles
	SET sequence_no = rf.sequence_no::INTEGER
	FROM (
			SELECT	"t".title_id,
					ROW_NUMBER() OVER (ORDER BY "t".deleted ASC, "t".sequence_no ASC) * 2 AS sequence_no
			FROM wk_titles AS "t"
			WHERE "t".application_id = vr_application_id AND "t".owner_id = vr_owner_id
		) AS rf
		INNER JOIN wk_titles AS tt
		ON tt.application_id = vr_application_id AND tt.title_id = rf.title_id;
		
	IF COALESCE(vr_sequence_no, 0) <= 0 THEN
		vr_sequence_no := 1;
	END IF;
	
	vr_sequence_no := (vr_sequence_no * 2) - 1;
	-- end of Update All Sequence Numbers
	
	INSERT INTO wk_titles (
		application_id,
		title_id,
		owner_id,
		creator_user_id,
		creation_date,
		sequence_no,
		title,
		status,
		owner_type,
		deleted
	)
	VALUES (
		vr_application_id,
		vr_title_id,
		vr_owner_id,
		vr_current_user_id,
		vr_now,
		vr_sequence_no,
		vr_title,
		vr_status,
		vr_owner_type,
		FALSE
	);
	
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

