DROP FUNCTION IF EXISTS cn_set_service_description;

CREATE OR REPLACE FUNCTION cn_set_service_description
(
	vr_application_id	UUID,
	vr_node_type_id		UUID,
	vr_description		 	VARCHAR(512)
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE cn_services AS s
	SET service_description = gfn_verify_string(vr_description)
	WHERE s.application_id = vr_application_id AND s.node_type_id = vr_node_type_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
