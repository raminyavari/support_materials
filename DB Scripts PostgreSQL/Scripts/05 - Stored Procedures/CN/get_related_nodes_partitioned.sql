DROP FUNCTION IF EXISTS cn_get_related_nodes_partitioned;

CREATE OR REPLACE FUNCTION cn_get_related_nodes_partitioned
(
	vr_application_id	UUID,
	vr_node_id			UUID,
	vr_node_type_ids	guid_table_type[],
	vr_in				BOOLEAN,
	vr_out			 	BOOLEAN,
	vr_in_tags			BOOLEAN,
	vr_out_tags		 	BOOLEAN,
	vr_count			INTEGER
)
RETURNS SETOF cn_node_ret_composite
AS
$$
DECLARE
	vr_has_node_type_id BOOLEAN DEFAULT FALSE;
	vr_ids				UUID[];
BEGIN
	SELECT vr_has_node_type_id = TRUE 
	FROM UNNEST(vr_node_type_ids)
	LIMIT 1;
	
	vr_ids := ARRAY(
		SELECT *
		FROM cn_p_get_related_node_ids(vr_application_id, vr_node_id, NULL, 
			NULL, vr_in, vr_out, vr_in_tags, vr_out_tags, 1000000, NULL)
	);
	
	vr_ids := ARRAY(
		SELECT x.node_id
		FROM (
				SELECT	ROW_NUMBER() OVER (PARTITION BY n.node_type_id ORDER BY n.creation_date DESC, n.node_id DESC) AS "number",
						n.node_id
				FROM UNNEST(vr_ids) AS "id"
					INNER JOIN cn_view_nodes_normal AS n
					ON n.application_id = vr_application_id AND n.node_id = "id"
				WHERE vr_has_node_type_id = FALSE OR n.node_type_id IN (SELECT "t".value FROM UNNEST(vr_node_type_ids) AS "t")
			) AS x
		WHERE x.number <= COALESCE(vr_count, 5)
	);
	
	RETURN QUERY
	SELECT *
	FROM cn_p_get_nodes_by_ids(vr_application_id, vr_ids, FALSE, NULL);
END;
$$ LANGUAGE plpgsql;
