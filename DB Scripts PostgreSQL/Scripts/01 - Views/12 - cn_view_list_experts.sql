DROP VIEW IF EXISTS cn_view_list_experts;

CREATE VIEW cn_view_list_experts
AS
SELECT  l.application_id,
		l.list_id,
		ex.user_id,
		nd.node_id,
		nd.node_type_id,
		l.name AS list_name,
		nd.name AS node_name
FROM    cn_lists AS l
		INNER JOIN cn_list_nodes AS ln
		ON ln.application_id = l.application_id AND ln.node_id = l.list_id
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = ln.application_id AND nd.node_id = ln.node_id
		INNER JOIN cn_experts AS ex
		ON nd.application_id = ex.application_id AND nd.node_id = ex.node_id
		INNER JOIN rv_membership AS m
		ON m.user_id = ex.user_id
WHERE	ln.deleted = FALSE AND nd.deleted = FALSE AND 
		(ex.approved = TRUE OR ex.social_approved = TRUE) AND m.is_approved = TRUE;