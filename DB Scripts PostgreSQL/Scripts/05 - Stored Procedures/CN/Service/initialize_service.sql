DROP FUNCTION IF EXISTS cn_initialize_service;

CREATE OR REPLACE FUNCTION cn_initialize_service
(
	vr_application_id	UUID,
	vr_node_type_id		UUID
)
RETURNS INTEGER
AS
$$
BEGIN
	RETURN cn_p_initialize_service(vr_application_id, vr_node_type_id);
END;
$$ LANGUAGE plpgsql;
