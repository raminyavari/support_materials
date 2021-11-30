DROP FUNCTION IF EXISTS wk_add_paragraph;

CREATE OR REPLACE FUNCTION wk_add_paragraph
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
    vr_has_admin		BOOLEAN,
	vr_admin_user_ids	guid_table_type[]
)
RETURNS SETOF REFCURSOR
AS
$$
DECLARE
	vr_user_ids		UUID[];
	vr_owner_id 	UUID;
	vr_dashboards	dashboard_table_type[];
	vr_result		INTEGER;
	vr_cursor_1		REFCURSOR;
	vr_cursor_2		REFCURSOR;
BEGIN
	vr_result := wk_p_add_paragraph(vr_application_id, vr_paragraph_id, vr_title_id, vr_title, 
									vr_body_text, vr_sequence_no, vr_current_user_id, vr_now, 
									vr_is_rich_text, vr_send_to_admins, vr_has_admin);
	
	-- Send Dashboards
	vr_user_ids := ARRAY(
		SELECT rf.value
		FROM UNNEST(vr_admin_user_ids) AS rf
		WHERE rf.value <> vr_current_user_id
	);
	
	IF vr_send_to_admins = TRUE AND COALESCE(ARRAY_LENGTH(vr_user_ids, 1), 0) > 0 THEN
		SELECT vr_owner_id = tt.owner_id
		FROM wk_titles AS tt
		WHERE tt.application_id = vr_application_id AND tt.title_id = vr_title_id
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

