DROP FUNCTION IF EXISTS cn_has_extension;

CREATE OR REPLACE FUNCTION cn_has_extension
(
	vr_application_id	UUID,
	vr_owner_id			UUID,
	vr_extension		VARCHAR(50)
)
RETURNS BOOLEAN
AS
$$
DECLARE
	vr_node_type_id	UUID;
BEGIN
	SELECT vr_node_type_id = nd.node_type_id
	FROM cn_nodes AS nd
	WHERE nd.application_id = vr_application_id AND nd.node_id = vr_owner_id;
	
	IF vr_node_type_id IS NOT NULL THEN
		vr_owner_id := vr_node_type_id;
	END IF;
	
	RETURN COALESCE((
		SELECT TRUE
		FROM cn_extensions AS ex
		WHERE ex.application_id = vr_application_id AND ex.owner_id = vr_owner_id AND 
			ex.extension = vr_extension AND ex.deleted = FALSE
	), FALSE)::BOOLEAN;
END;
$$ LANGUAGE plpgsql;
