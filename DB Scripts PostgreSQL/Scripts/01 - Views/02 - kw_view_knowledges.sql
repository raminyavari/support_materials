DROP VIEW IF EXISTS kw_view_content_file_extensions;

DROP VIEW IF EXISTS kw_view_knowledges;

CREATE VIEW kw_view_knowledges
AS
SELECT  nd.node_id AS knowledge_id,
		nd.application_id,
		nd.additional_id,
		nt.node_type_id AS knowledge_type_id,
		nt.additional_id AS type_additional_id,
		nt.name AS knowledge_type,
		nd.area_id,
		nd.owner_id,
		nd.document_tree_node_id AS tree_node_id,
		nd.previous_version_id,
		nd.name AS title,
		nd.creator_user_id,
		nd.creation_date,
		nd.status,
		nd.score,
		nd.searchable,
		nd.publication_date,
		nd.deleted
FROM    cn_nodes AS nd
		INNER JOIN cn_services AS s
		INNER JOIN cn_node_types AS nt
		ON nt.application_id = s.application_id AND nt.node_type_id = s.node_type_id
		ON nt.application_id = nd.application_id AND nt.node_type_id = nd.node_type_id
WHERE s.is_knowledge = TRUE;