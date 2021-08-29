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
	SELECT property_id AS relation_type_id,
		   "name",
		   additional_id
	FROM cn_properties
	WHERE application_id = vr_application_id AND deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

