DROP FUNCTION IF EXISTS cn_set_max_acceptable_admin_level;

CREATE OR REPLACE FUNCTION cn_set_max_acceptable_admin_level
(
	vr_application_id				UUID,
	vr_node_type_id					UUID,
	vr_max_acceptable_admin_level	INTEGER
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE cn_services AS s
	SET max_acceptable_admin_level = vr_max_acceptable_admin_level
	WHERE s.application_id = vr_application_id AND s.node_type_id = vr_node_type_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
