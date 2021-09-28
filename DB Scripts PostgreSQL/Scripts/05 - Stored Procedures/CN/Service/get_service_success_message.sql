DROP FUNCTION IF EXISTS cn_get_service_success_message;

CREATE OR REPLACE FUNCTION cn_get_service_success_message
(
	vr_application_id	UUID,
	vr_node_type_id		UUID
)
RETURNS VARCHAR
AS
$$
BEGIN
	RETURN (
		SELECT s.success_message
		FROM cn_services AS s
		WHERE s.application_id = vr_application_id AND s.node_type_id = vr_node_type_id
		LIMIT 1
	);
END;
$$ LANGUAGE plpgsql;
