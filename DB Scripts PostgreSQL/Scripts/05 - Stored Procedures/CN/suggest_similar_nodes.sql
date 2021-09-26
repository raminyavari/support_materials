DROP FUNCTION IF EXISTS cn_suggest_similar_nodes;

CREATE OR REPLACE FUNCTION cn_suggest_similar_nodes
(
	vr_application_id	UUID,
	vr_node_id			UUID,
	vr_count		 	INTEGER
)
RETURNS TABLE (
	node_id		UUID, 
	"rank"		FLOAT,
	tags		BOOLEAN,
	favorites	BOOLEAN,
	relations	BOOLEAN,
	experts		BOOLEAN
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT rf.*
	FROM (
			SELECT	ids.node_id, 
					((8 * SUM(ids.tags)) + (5 * SUM(ids.relations)) + 
						(4 * SUM(ids.experts)) + (1 * SUM(ids.favorites)))::FLOAT AS "rank",
					CASE WHEN SUM(ids.tags) > 0 THEN TRUE ELSE FALSE END::BOOLEAN AS tags,
					CASE WHEN SUM(ids.favorites) > 0 THEN TRUE ELSE FALSE END::BOOLEAN AS favorites,
					CASE WHEN SUM(ids.relations) > 0 THEN TRUE ELSE FALSE END::BOOLEAN AS relations,
					CASE WHEN SUM(ids.experts) > 0 THEN TRUE ELSE FALSE END::BOOLEAN AS experts
			FROM (
					-- tagged together
					SELECT	dst.tagged_id AS node_id, 
							COUNT(dst.context_id) AS tags,
							0::INTEGER AS favorites,
							0::INTEGER AS relations,
							0::INTEGER AS experts
					FROM rv_tagged_items AS x
						INNER JOIN rv_tagged_items AS dst
						ON dst.application_id = vr_application_id AND dst.context_id = x.context_id
					WHERE x.application_id = vr_application_id AND 
						x.tagged_id = vr_node_id AND dst.tagged_type = N'Node'
					GROUP BY dst.tagged_id
					-- end of tagged together

					UNION ALL

					-- favorites
					SELECT	dst.node_id, 
							0::INTEGER AS tags,
							COUNT(dst.user_id) AS favorites,
							0::INTEGER AS relations,
							0::INTEGER AS experts
					FROM cn_node_likes AS x
						INNER JOIN cn_node_likes AS dst
						ON dst.application_id = vr_application_id AND dst.user_id = x.user_id
					WHERE x.application_id = vr_application_id AND 
						x.node_id = vr_node_id AND x.deleted = FALSE AND dst.deleted = FALSE
					GROUP BY dst.node_id
					-- end of favorites

					UNION ALL

					-- related nodes
					SELECT	dst.related_node_id AS node_id, 
							0::INTEGER AS tags,
							0::INTEGER AS favorites,
							COUNT(dst.node_id) AS relations,
							0::INTEGER AS experts
					FROM cn_view_out_related_nodes AS x
						INNER JOIN cn_view_out_related_nodes AS dst
						ON dst.application_id = vr_application_id AND dst.node_id = x.node_id
					WHERE x.application_id = vr_application_id AND x.related_node_id = vr_node_id
					GROUP BY dst.related_node_id
					-- end of related nodes

					UNION ALL

					-- experts
					SELECT	dst.node_id,
							0::INTEGER AS tags,
							0::INTEGER AS favorites,
							0::INTEGER AS relations,
							COUNT(dst.user_id) AS experts
					FROM cn_view_experts AS x
						INNER JOIN cn_view_experts AS dst
						ON dst.application_id = vr_application_id AND dst.user_id = x.user_id
					WHERE x.application_id = vr_application_id AND x.node_id = vr_node_id
					GROUP BY dst.node_id
					-- end of experts
				) AS ids
			GROUP BY ids.node_id
		) AS rf
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = rf.node_id AND nd.deleted = FALSE
	WHERE rf.node_id <> vr_node_id
	ORDER BY rf.rank DESC
	LIMIT COALESCE(vr_count, 20);
END;
$$ LANGUAGE plpgsql;

