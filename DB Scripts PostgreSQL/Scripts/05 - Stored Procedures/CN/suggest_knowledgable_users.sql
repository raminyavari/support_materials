DROP FUNCTION IF EXISTS cn_suggest_knowledgable_users;

CREATE OR REPLACE FUNCTION cn_suggest_knowledgable_users
(
	vr_application_id	UUID,
	vr_node_id			UUID,
	vr_count		 	INTEGER
)
RETURNS TABLE (
	user_id						UUID, 
	"rank"						FLOAT,
	expert						BOOLEAN,
	contributor					BOOLEAN,
	wiki_editor					BOOLEAN,
	"member"					BOOLEAN,
	expert_of_related_node		BOOLEAN,
	contributor_of_related_node	BOOLEAN,
	member_of_related_node		BOOLEAN
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT rf.*
	FROM (
			SELECT	ids.user_id, 
					((8 * SUM(ids.expert)) + (8 * SUM(ids.contributor)) + 
						(4 * SUM(ids.wiki_editor)) + (4 * SUM(ids.member)) + 
						(2 * SUM(ids.expert_of_related_node)) + 
						(2 * SUM(ids.contributor_of_related_node)) + 
						(1 * SUM(ids.member_of_related_node)))::FLOAT AS "rank",
					CASE WHEN SUM(ids.expert) > 0 THEN TRUE ELSE FALSE END::BOOLEAN AS expert,
					CASE WHEN SUM(ids.contributor) > 0 THEN TRUE ELSE FALSE END::BOOLEAN AS contributor,
					CASE WHEN SUM(ids.wiki_editor) > 0 THEN TRUE ELSE FALSE END::BOOLEAN AS wiki_editor,
					CASE WHEN SUM(ids.member) > 0 THEN TRUE ELSE FALSE END::BOOLEAN AS member,
					CASE WHEN SUM(ids.expert_of_related_node) > 0 THEN TRUE ELSE FALSE END::BOOLEAN AS expert_of_related_node,
					CASE WHEN SUM(ids.contributor_of_related_node) > 0 THEN TRUE ELSE FALSE END::BOOLEAN AS contributor_of_related_node,
					CASE WHEN SUM(ids.member_of_related_node) > 0 THEN TRUE ELSE FALSE END::BOOLEAN AS member_of_related_node
			FROM (
					-- experts
					SELECT	dst.user_id, 
							1::INTEGER AS expert,
							0::INTEGER AS contributor,
							0::INTEGER AS wiki_editor,
							0::INTEGER AS "member",
							0::INTEGER AS expert_of_related_node,
							0::INTEGER AS contributor_of_related_node,
							0::INTEGER AS member_of_related_node
					FROM cn_view_experts AS dst
					WHERE dst.application_id = vr_application_id AND dst.node_id = vr_node_id
					-- end of experts

					UNION ALL

					-- contributors
					SELECT	dst.user_id, 
							0::INTEGER AS expert,
							1::INTEGER AS contributor,
							0::INTEGER AS wiki_editor,
							0::INTEGER AS "member",
							0::INTEGER AS expert_of_related_node,
							0::INTEGER AS contributor_of_related_node,
							0::INTEGER AS member_of_related_node
					FROM cn_node_creators AS dst
					WHERE dst.application_id = vr_application_id AND 
						dst.node_id = vr_node_id AND dst.deleted = FALSE
					-- end of contributors

					UNION ALL

					-- wiki editors
					SELECT	"c".user_id, 
							0::INTEGER AS expert,
							0::INTEGER AS contributor,
							COUNT(DISTINCT "p".paragraph_id) AS wiki_editor,
							0::INTEGER AS "member",
							0::INTEGER AS expert_of_related_node,
							0::INTEGER AS contributor_of_related_node,
							0::INTEGER AS member_of_related_node
					FROM wk_titles AS "t"
						INNER JOIN wk_paragraphs AS "p"
						ON "p".application_id = vr_application_id AND "p".title_id = "t".title_id
						INNER JOIN wk_changes AS "c"
						ON "c".application_id = vr_application_id AND 
							"c".paragraph_id = "p".paragraph_id AND "c".applied = TRUE
					WHERE "t".application_id = vr_application_id AND "t".owner_id = vr_node_id
					GROUP BY "c".user_id
					-- end of wiki editors
					
					UNION ALL
					
					-- experts
					SELECT	dst.user_id, 
							0::INTEGER AS expert,
							0::INTEGER AS contributor,
							0::INTEGER AS wiki_editor,
							1::INTEGER AS "member",
							0::INTEGER AS expert_of_related_node,
							0::INTEGER AS contributor_of_related_node,
							0::INTEGER AS member_of_related_node
					FROM cn_view_node_members AS dst
					WHERE dst.application_id = vr_application_id AND 
						dst.node_id = vr_node_id AND dst.is_pending = FALSE
					-- end of experts

					UNION ALL

					-- experts of related nodes
					SELECT	dst.user_id, 
							0::INTEGER AS expert,
							0::INTEGER AS contributor,
							0::INTEGER AS wiki_editor,
							0::INTEGER AS "member",
							COUNT(dst.node_id) AS expert_of_related_node,
							0::INTEGER AS contributor_of_related_node,
							0::INTEGER AS member_of_related_node
					FROM cn_view_out_related_nodes AS x
						INNER JOIN cn_view_experts AS dst
						ON dst.application_id = vr_application_id AND dst.node_id = x.related_node_id
					WHERE x.application_id = vr_application_id AND x.node_id = vr_node_id
					GROUP BY dst.user_id
					-- end of experts of related nodes

					UNION ALL

					-- contributors of related nodes
					SELECT	dst.user_id, 
							0::INTEGER AS expert,
							0::INTEGER AS contributor,
							0::INTEGER AS wiki_editor,
							0::INTEGER AS "member",
							0::INTEGER AS expert_of_related_node,
							COUNT(dst.node_id) AS contributor_of_related_node,
							0::INTEGER AS member_of_related_node
					FROM cn_view_out_related_nodes AS x
						INNER JOIN cn_node_creators AS dst
						ON dst.application_id = vr_application_id AND dst.node_id = x.related_node_id
					WHERE x.application_id = vr_application_id AND x.node_id = vr_node_id
					GROUP BY dst.user_id
					-- end of contributors of related nodes

					UNION ALL

					-- members of related nodes
					SELECT	dst.user_id, 
							0::INTEGER AS expert,
							0::INTEGER AS contributor,
							0::INTEGER AS wiki_editor,
							0::INTEGER AS "member",
							0::INTEGER AS expert_of_related_node,
							0::INTEGER AS contributor_of_related_node,
							COUNT(dst.node_id) AS member_of_related_node
					FROM cn_view_out_related_nodes AS x
						INNER JOIN cn_view_node_members AS dst
						ON dst.application_id = vr_application_id AND dst.node_id = x.related_node_id
					WHERE x.application_id = vr_application_id AND 
						x.node_id = vr_node_id AND dst.is_pending = FALSE
					GROUP BY dst.user_id
					-- end of members of related nodes
				) AS ids
			GROUP BY ids.user_id
		) AS rf
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND 
			un.user_id = rf.user_id AND un.is_approved = TRUE
	ORDER BY rf.rank DESC
	LIMIT COALESCE(vr_count, 20);
END;
$$ LANGUAGE plpgsql;

