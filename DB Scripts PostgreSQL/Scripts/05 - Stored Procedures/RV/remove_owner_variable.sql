DROP FUNCTION IF EXISTS rv_remove_owner_variable;

CREATE OR REPLACE FUNCTION rv_remove_owner_variable
(
	vr_application_id	UUID,
	vr_id				BIGINT,
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE rv_variables_with_owner AS v
	SET deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE v.application_id = vr_application_id AND v.id = vr_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

