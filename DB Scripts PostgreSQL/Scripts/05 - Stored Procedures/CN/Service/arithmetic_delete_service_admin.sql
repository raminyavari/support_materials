DROP FUNCTION IF EXISTS cn_arithmetic_delete_service_admin;

CREATE OR REPLACE FUNCTION cn_arithmetic_delete_service_admin
(
	vr_application_id	UUID,
	vr_node_type_id		UUID,
	vr_user_id			UUID,
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE cn_service_admins AS s
	SET deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE s.application_id = vr_application_id AND 
		s.node_type_id = vr_node_type_id AND s.user_id = vr_user_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
