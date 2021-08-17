DROP VIEW IF EXISTS wf_view_current_states;

DROP VIEW IF EXISTS cn_view_nodes_normal;

CREATE VIEW cn_view_nodes_normal
AS
SELECT  nd.node_id, 
		nd.application_id,
		nd.name AS node_name, 
		nd.description,
		nd.additional_id_main AS node_additional_id_main, 
		nd.additional_id AS node_additional_id, 
		nd.node_type_id,
		nt.name AS type_name, 
		nt.additional_id AS type_additional_id, 
        nd.parent_node_id,
        nd.deleted, 
        COALESCE(nd.searchable, FALSE)::BOOLEAN AS searchable,
        COALESCE(nd.hide_creators, FALSE)::BOOLEAN AS hide_creators,
        nt.deleted AS type_deleted,
        nd.tags, 
        nd.creation_date,
        nd.publication_date,
        nd.creator_user_id,
        nd.owner_id,
        nd.area_id,
        nd.document_tree_node_id,
        nd.score,
        nd.status,
        nd.wf_state,
        nd.sequence_number,
        nd.index_last_update_date
FROM cn_nodes AS nd
	INNER JOIN cn_node_types AS nt
	ON nt.application_id = nd.application_id AND nd.node_type_id = nt.node_type_id;