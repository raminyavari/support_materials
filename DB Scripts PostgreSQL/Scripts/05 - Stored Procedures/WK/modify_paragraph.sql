DROP FUNCTION IF EXISTS wk_modify_paragraph;

CREATE OR REPLACE FUNCTION wk_modify_paragraph
(
	vr_application_id		UUID,
    vr_paragraph_id 		UUID,
	vr_change_id_to_accept	UUID,
    vr_title				VARCHAR(500),
    vr_body_text			VARCHAR,
    vr_current_user_id		UUID,
    vr_now					TIMESTAMP,
	vr_citation_needed		BOOLEAN,
    vr_apply				BOOLEAN,
    vr_accept				BOOLEAN,
    vr_has_admin			BOOLEAN,
	vr_admin_user_ids		guid_table_type[]
)
RETURNS SETOF REFCURSOR
AS
$$
DECLARE
	vr_acception_date 	TIMESTAMP DEFAULT NULL; 
	vr_applied 			BOOLEAN DEFAULT FALSE; 
	vr_change_status 	VARCHAR(20) DEFAULT 'Pending';
	vr_change_id		UUID;
	vr_subject_status 	VARCHAR(20) DEFAULT 'Accepted';
	vr_user_ids			UUID;
	vr_dashboards		dashboard_table_type[];
	vr_result			INTEGER;
	vr_cursor_1			REFCURSOR;
	vr_cursor_2			REFCURSOR;
BEGIN
	vr_title := gfn_verify_string(vr_title);
	vr_body_text := gfn_verify_string(vr_body_text);
	
	vr_has_admin := COALESCE(vr_has_admin, FALSE)::BOOLEAN;
	
	IF vr_accept = TRUE THEN 
		vr_acception_date := vr_now;
	END IF;
	
	IF vr_apply = TRUE THEN 
		vr_applied := TRUE;
		vr_change_status := 'Accepted';
	END IF;
	
	SELECT vr_change_id = ch.change_id 
	FROM wk_changes AS ch
	WHERE ch.application_id = vr_application_id AND ch.paragraph_id = vr_paragraph_id AND 
		ch.user_id = vr_current_user_id AND ch.status = 'Pending' AND ch.deleted = FALSE
	LIMIT 1;
	
	IF vr_change_id IS NOT NULL THEN
		UPDATE wk_changes AS ch
		SET title = vr_title,
			body_text = vr_body_text,
			last_modification_date = vr_now,
			status = vr_change_status
		WHERE ch.application_id = vr_application_id AND ch.change_id = vr_change_id;
	ELSE
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
			application_date,
			status,
			acception_date,
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
			vr_applied,
			vr_now,
			vr_change_status,
			vr_acception_date,
			FALSE
		);
	END IF;
	
	IF vr_apply = TRUE THEN
		IF vr_change_id_to_accept IS NOT NULL THEN
			vr_result := wk_p_accept_change(vr_application_id, vr_change_id_to_accept, 
											vr_current_user_id, vr_now);
				
			IF vr_result <= 0 THEN
				EXECUTE gfn_raise_exception(-1::INTEGER);
				RETURN;
			END IF;
		END IF;
	
		IF vr_citation_needed = TRUE THEN 
			vr_subject_status := 'CitationNeeded';
		END IF;
		
		UPDATE wk_paragraphs AS pg
		SET title = vr_title,
			body_text = vr_body_text,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now,
			status = vr_subject_status
		WHERE pg.application_id = vr_application_id AND pg.paragraph_id = vr_paragraph_id;
		
		GET DIAGNOSTICS vr_result := ROW_COUNT;
		
		IF vr_result <= 0 THEN
			EXECUTE gfn_raise_exception(-1::INTEGER);
			RETURN;
		END IF;
	END IF;
	
	-- Send Dashboards
	vr_user_ids := ARRAY(
		SELECT rf.value
		FROM UNNEST(vr_admin_user_ids) AS rf
		WHERE rf.value <> vr_current_user_id
	);
	
	IF COALESCE(vr_apply, FALSE)::BOOLEAN = FALSE AND vr_has_admin = TRUE AND 
		COALESCE(ARRAY_LENGTH(vr_user_ids, 1), 0) > 0 THEN
		
		SELECT vr_owner_id = tt.owner_id
		FROM wk_paragraphs AS pg
			INNER JOIN wk_titles AS tt
			ON tt.application_id = vr_application_id AND tt.title_id = pg.title_id
		WHERE pg.application_id = vr_application_id AND pg.paragraph_id = vr_paragraph_id
		LIMIT 1;
		
		SELECT	vr_result = x.result,
				vr_dashboards = x.dashboards
		FROM wk_p_send_dashboards(vr_application_id, vr_paragraph_id, vr_owner_id, vr_user_ids, vr_now) AS x
		LIMIT 1;
		
		IF vr_result <= 0 THEN
			EXECUTE gfn_raise_exception(-1::INTEGER);
			RETURN;
		END IF;
		
		OPEN vr_cursor_1 FOR
		SELECT x.*
		FROM UNNEST(vr_dashboards) AS x;
		
		RETURN NEXT vr_cursor_1;
	END IF;
	-- end of Send Dashboards
	
	OPEN vr_cursor_2 FOR
	SELECT 1::INTEGER;
	
	RETURN NEXT vr_cursor_2;
END;
$$ LANGUAGE plpgsql;

