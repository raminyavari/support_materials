DROP FUNCTION IF EXISTS rv_get_tagged_items;

CREATE OR REPLACE FUNCTION rv_get_tagged_items
(
	vr_application_id	UUID,
	vr_context_id		UUID,
	vr_tagged_types		string_table_type[]
)
RETURNS TABLE (
	"id"	UUID,
	"type"	VARCHAR
)
AS
$$
DECLARE
	vr_tagged_types_count	INTEGER;
BEGIN
	vr_tagged_types_count := COALESCE(ARRAY_LENGTH(vr_tagged_types, 1), 0)::INTEGER;
	
	RETURN QUERY
	SELECT	ti.tagged_id AS "id",
			ti.tagged_type AS "type"
	FROM rv_tagged_items AS ti
	WHERE ti.application_id = vr_application_id AND ti.context_id = vr_context_id AND
		(vr_tagged_types_count = 0 OR ti.tagged_type IN (SELECT x.value FROM UNNEST(vr_tagged_types) AS x));
END;
$$ LANGUAGE plpgsql;

