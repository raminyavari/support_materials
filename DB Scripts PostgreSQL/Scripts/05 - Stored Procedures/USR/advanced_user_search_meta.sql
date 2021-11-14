DROP FUNCTION IF EXISTS usr_advanced_user_search_meta;

CREATE OR REPLACE FUNCTION usr_advanced_user_search_meta
(
	vr_application_id	UUID,
	vr_user_id			UUID,
	vr_search_text  	VARCHAR(1000),
	vr_node_type_ids 	guid_table_type[],
	vr_node_ids			guid_table_type[],
	vr_members	 		BOOLEAN,
	vr_experts	 		BOOLEAN,
	vr_contributors 	BOOLEAN,
	vr_property_owners 	BOOLEAN
)
RETURNS TABLE (
	node_id			UUID, 
	"rank"			FLOAT,
	is_member		BOOLEAN,
	is_expert		BOOLEAN,
	is_contributor	BOOLEAN,
	has_property	BOOLEAN
)
AS
$$
DECLARE
	vr_node_count		INTEGER;
	vr_node_type_count	INTEGER;
BEGIN
	vr_search_text := gfn_verify_string(COALESCE(vr_search_text, ''));
	vr_node_count := COALESCE(ARRAY_LENGTH(vr_node_ids, 1), 0)::INTEGER;
	
	IF vr_node_count > 0 THEN
		vr_search_text = '';
		vr_node_type_ids := ARRAY[];
	END IF;
	
	vr_node_type_count := COALESCE(ARRAY_LENGTH(vr_node_type_ids, 1), 0)::INTEGER;
	
	RETURN QUERY
	WITH dt_nodes (node_id, "rank") AS 
	(
		SELECT rf.value AS node_id, 1::FLOAT AS "rank"
		FROM UNNEST(vr_node_ids) AS rf
		WHERE vr_node_count > 0
		
		UNION ALL
		
		SELECT	nd.node_id,
				(ROW_NUMBER() OVER (ORDER BY pgroonga_score(nd.tableoid, nd.ctid)::FLOAT DESC, nd.node_id ASC))::FLOAT AS "rank"
		FROM cn_nodes AS nd
		WHERE vr_node_count = 0 AND nd.application_id = vr_application_id AND
			nd.deleted = FALSE AND COALESCE(nd.searchable, TRUE) = TRUE AND 
			(vr_search_text = '' OR nd.name &@~ vr_search_text) AND
			(vr_node_type_count = 0 OR nd.node_type_id IN (SELECT x.value FROM UNNEST(vr_node_type_ids) AS x))
	)
	SELECT	nodes.node_id,
			SUM(nodes.rank)::FLOAT AS "rank",
			MAX(nodes.is_member)::BOOLEAN AS is_member,
			MAX(nodes.is_expert)::BOOLEAN AS is_expert,
			MAX(nodes.is_contributor)::BOOLEAN AS is_contributor,
			MAX(nodes.has_property)::BOOLEAN AS has_property
	FROM (
			SELECT	"m".user_id,
					nodes.rank,
					1::INTEGER AS is_member,
					0::INTEGER AS is_expert,
					0::INTEGER AS is_contributor,
					0::INTEGER AS has_property
			FROM dt_nodes AS nodes 
				INNER JOIN cn_view_node_members AS "m"
				ON "m".application_id = vr_application_id AND 
					"m".node_id = nodes.node_id AND "m".is_pending = FALSE
			WHERE vr_members = TRUE AND "m".user_id = vr_user_id

			UNION ALL

			SELECT	e.user_id,
					nodes.rank,
					0::INTEGER AS is_member,
					1::INTEGER AS is_expert,
					0::INTEGER AS is_contributor,
					0::INTEGER AS has_property
			FROM dt_nodes AS nodes 
				INNER JOIN cn_view_experts AS e
				ON e.application_id = vr_application_id AND e.node_id = nodes.node_id
			WHERE vr_experts = TRUE AND e.user_id = vr_user_id

			UNION ALL

			SELECT	"c".user_id,
					nodes.rank,
					0::INTEGER AS is_member,
					0::INTEGER AS is_expert,
					1::INTEGER AS is_contributor,
					0::INTEGER AS has_property
			FROM dt_nodes AS nodes 
				INNER JOIN cn_node_creators AS "c"
				ON "c".application_id = vr_application_id AND 
					"c".node_id = nodes.node_id AND "c".deleted = FALSE
			WHERE vr_contributors = TRUE AND "c".user_id = vr_user_id

			UNION ALL

			SELECT	x.base_node_id AS node_id,
					MAX(x.seq_no)::FLOAT AS "rank",
					0::INTEGER AS is_member,
					0::INTEGER AS is_expert,
					0::INTEGER AS is_contributor,
					1::INTEGER AS has_property
			FROM (
					SELECT	n.node_id, 
							MAX(n.base_node_id::VARCHAR(50))::UUID AS base_node_id, 
							MAX(n.rank)::FLOAT AS seq_no
					FROM (
							SELECT	i.node_id AS base_node_id, 
									i.related_node_id AS node_id, 
									nodes.rank
							FROM dt_nodes AS nodes 
								INNER JOIN cn_view_in_related_nodes AS i
								ON i.application_id = vr_application_id AND i.node_id = nodes.node_id
								
							UNION ALL
							
							SELECT	o.node_id AS base_node_id,
									o.related_node_id AS node_id, 
									nodes.rank
							FROM dt_nodes AS nodes 
								INNER JOIN cn_view_out_related_nodes AS o
								ON o.application_id = vr_application_id AND o.node_id = nodes.node_id
						) AS n
					GROUP BY n.node_id
				) AS x
				INNER JOIN cn_node_creators AS "c"
				ON "c".application_id = vr_application_id AND 
					"c".node_id = x.node_id AND "c".deleted = FALSE
			WHERE vr_property_owners = TRUE AND "c".user_id = vr_user_id
			GROUP BY x.base_node_id
		) AS results
	GROUP BY results.node_id;
END;
$$ LANGUAGE plpgsql;


