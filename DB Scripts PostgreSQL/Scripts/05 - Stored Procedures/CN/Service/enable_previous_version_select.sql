DROP FUNCTION IF EXISTS cn_enable_previous_version_select;

CREATE OR REPLACE FUNCTION cn_enable_previous_version_select
(
	vr_application_id			UUID,
	vr_node_type_id_or_node_id	UUID,
	vr_value			 		BOOLEAN
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	vr_node_type_id_or_node_id = COALESCE((
		SELECT nd.node_type_id 
		FROM cn_nodes AS nd
		WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_type_id_or_node_id
		LIMIT 1
	), vr_node_type_id_or_node_id);
	
	IF vr_value IS NULL THEN
		RETURN COALESCE((
			SELECT s.enable_previous_version_select
			FROM cn_services AS s
			WHERE s.application_id = vr_application_id AND s.node_type_id = vr_node_type_id_or_node_id
			LIMIT 1
		), FALSE)::INTEGER;
	ELSE
		UPDATE cn_services AS s
		SET enable_previous_version_select = vr_value
		WHERE s.application_id = vr_application_id AND s.node_type_id = vr_node_type_id_or_node_id;
		
		GET DIAGNOSTICS vr_result := ROW_COUNT;
		
		RETURN vr_result;
	END IF;
END;
$$ LANGUAGE plpgsql;
