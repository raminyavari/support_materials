DROP FUNCTION IF EXISTS cn_get_extensions;

CREATE OR REPLACE FUNCTION cn_get_extensions
(
	vr_application_id	UUID,
	vr_owner_id			UUID
)
RETURNS TABLE (
	owner_id	UUID,
	"extension"	VARCHAR,
	title		VARCHAR,
	disabled	BOOLEAN
)
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
	
	RETURN QUERY
	SELECT ex.owner_id,
		   ex.extension,
		   ex.title,
		   ex.deleted AS disabled
	FROM cn_extensions AS ex
	WHERE ex.application_id = vr_application_id AND ex.owner_id = vr_owner_id
	ORDER BY ex.sequence_number ASC;
END;
$$ LANGUAGE plpgsql;
