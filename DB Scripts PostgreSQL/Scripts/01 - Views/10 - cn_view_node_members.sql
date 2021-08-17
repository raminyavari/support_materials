DROP VIEW IF EXISTS cn_view_node_members;

CREATE VIEW cn_view_node_members
AS
SELECT  nm.application_id,
		nm.node_id,
		nm.user_id,
		nd.node_type_id,
		nd.name AS node_name,
		nm.is_admin,
		CAST((CASE WHEN nm.status = 'Pending' THEN 1 ELSE 0 END) AS BOOLEAN) AS is_pending
FROM    cn_node_members AS nm
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = nm.application_id AND nd.node_id = nm.node_id
		INNER JOIN rv_membership AS m
		ON m.user_id = nm.user_id
WHERE	nm.deleted = FALSE AND nd.deleted = FALSE AND m.is_approved = TRUE;