DROP VIEW IF EXISTS cn_view_list_admins;

CREATE VIEW cn_view_list_admins
AS
SELECT  l.application_id,
		l.list_id,
		la.user_id,
		nd.node_id,
		l.name AS list_name
FROM    cn_lists AS l
		INNER JOIN cn_list_nodes AS ln
		ON ln.application_id = l.application_id AND ln.list_id = l.list_id
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = ln.application_id AND nd.node_id = ln.node_id
		INNER JOIN cn_list_admins AS la
		ON la.application_id = l.application_id AND la.list_id = l.list_id
		INNER JOIN rv_membership AS m
		ON m.user_id = la.user_id
WHERE	ln.deleted = FALSE AND nd.deleted = FALSE AND la.deleted = FALSE AND m.is_approved = TRUE;