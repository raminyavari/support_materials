DROP FUNCTION IF EXISTS cn_get_relation_types;

CREATE OR REPLACE FUNCTION cn_get_relation_types
(
	vr_application_id	UUID
)
RETURNS TABLE (
	relation_type_id	UUID,
	"name"				VARCHAR,
	additional_id		VARCHAR
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT x.property_id AS relation_type_id,
		   x.name,
		   x.additional_id
	FROM cn_properties AS x
	WHERE x.application_id = vr_application_id AND x.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

