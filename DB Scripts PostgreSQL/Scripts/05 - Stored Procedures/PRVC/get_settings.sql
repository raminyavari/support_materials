DROP FUNCTION IF EXISTS prvc_get_settings;

CREATE OR REPLACE FUNCTION prvc_get_settings
(
	vr_application_id	UUID,
	vr_object_ids		guid_table_type[]
)
RETURNS TABLE (
	object_id			UUID,
	calculate_hierarchy	BOOLEAN, 
	confidentiality_id	UUID, 
	level_id			INTEGER, 
	"level"				VARCHAR
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
	SELECT 	ids.value AS object_id, 
			s.calculate_hierarchy, 
			s.confidentiality_id, 
			cl.level_id, 
			cl.title AS "level"
	FROM UNNEST(vr_ids) AS ids
		LEFT JOIN prvc_settings AS s
		ON s.application_id = vr_application_id AND s.object_id = ids.value
		LEFT JOIN prvc_confidentiality_levels AS cl
		ON cl.application_id = vr_application_id AND cl.id = s.confidentiality_id AND cl.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

