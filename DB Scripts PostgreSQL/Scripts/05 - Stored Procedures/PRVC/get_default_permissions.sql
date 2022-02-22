DROP FUNCTION IF EXISTS prvc_get_default_permissions;

CREATE OR REPLACE FUNCTION prvc_get_default_permissions
(
	vr_application_id	UUID,
	vr_object_ids		guid_table_type[]
)
RETURNS TABLE (
	"id"			UUID, 
	permission_type VARCHAR, 
	default_value	VARCHAR
)
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT DISTINCT x.value
		FROM UNNEST(vr_object_ids) AS x
	);
	
	RETURN QUERY
	SELECT 	"p".object_id AS "id", 
			"p".permission_type AS "type", 
			"p".default_value
	FROM UNNEST(vr_ids) AS ids
		INNER JOIN prvc_default_permissions AS "p"
		ON "p".application_id = vr_application_id AND "p".object_id = ids.value;
END;
$$ LANGUAGE plpgsql;

