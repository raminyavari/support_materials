DROP VIEW IF EXISTS cn_view_experts;

CREATE VIEW cn_view_experts
AS
SELECT  ex.application_id,
		ex.node_id,
		ex.user_id,
		nd.node_type_id,
		nd.name AS node_name
FROM    cn_experts AS ex
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = ex.application_id AND nd.node_id = ex.node_id
		INNER JOIN rv_membership AS m
		ON m.user_id = ex.user_id
WHERE	(ex.approved = TRUE OR ex.social_approved = TRUE) AND 
		nd.deleted = FALSE AND m.is_approved = TRUE;