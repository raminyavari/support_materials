DROP FUNCTION IF EXISTS cn_fn_get_user_related_node_ids;

CREATE OR REPLACE FUNCTION cn_fn_get_user_related_node_ids
(
	vr_application_id			UUID,
	vr_user_ids					UUID[],
	vr_related_node_type_ids	UUID[]
)
RETURNS TABLE 
(
	node_id 		UUID,
	related_node_id	UUID
)
AS
$$
DECLARE
	vr_related_types_count	INTEGER;
BEGIN
	vr_related_types_count := COALESCE(ARRAY_LENGTH(vr_related_node_type_ids), 0);

	RETURN QUERY
	SELECT DISTINCT "t".tagged_id, "t".context_id
	FROM UNNEST(vr_user_ids) AS "id"
		INNER JOIN rv_tagged_items AS "t"
		ON "t".application_id = vr_application_id AND "t".tagged_id = "id"
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = "t".context_id AND nd.deleted = FALSE AND (
			vr_related_types_count = 0 OR 
			nd.node_type_id IN (SELECT UNNEST(vr_related_node_type_ids))
		)
	WHERE t.context_id <> t.tagged_id;
END;
$$ LANGUAGE PLPGSQL;