DROP FUNCTION IF EXISTS wk_arithmetic_delete_title;

CREATE OR REPLACE FUNCTION wk_arithmetic_delete_title
(
	vr_application_id	UUID,
    vr_title_id 		UUID,
    vr_current_user_id	UUID,
    vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE wk_titles AS tt
	SET deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE tt.application_id = vr_application_id AND tt.title_id = vr_title_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

