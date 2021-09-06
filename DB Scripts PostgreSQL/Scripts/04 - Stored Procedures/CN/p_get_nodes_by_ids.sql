DROP FUNCTION IF EXISTS cn_p_get_nodes_by_ids;

CREATE OR REPLACE FUNCTION cn_p_get_nodes_by_ids
(
	vr_application_id	UUID,
    vr_node_ids			UUID[],
    vr_full		 		BOOLEAN,
    vr_viewer_user_id	UUID
)
RETURNS SETOF cn_node_ret_composite
AS
$$
BEGIN
	IF COALESCE(vr_full, FALSE)::BOOLEAN = FALSE THEN
		RETURN QUERY
		SELECT	nd.node_id, 
				nd.node_name AS "name",
				nd.node_additional_id_main AS additional_id_main,
				nd.node_additional_id AS additional_id,
				nd.document_tree_node_id,
				NULL::UUID AS document_tree_id,
				NULL::VARCHAR AS document_tree_name,
				NULL::UUID AS previous_version_id,
				NULL::VARCHAR AS previous_version_name,
				NULL::VARCHAR AS description,
				NULL::VARCHAR AS public_description,
				NULL::VARCHAR AS tags,
				nd.node_type_id,
				nd.type_name AS node_type,
				nd.type_additional_id AS node_type_additional_id,
				nd.creator_user_id,
				NULL::VARCHAR AS creator_username,
				NULL::VARCHAR AS creator_first_name,
				NULL::VARCHAR AS creator_last_name,
				nd.creation_date,
				nd.parent_node_id,
				nd.status,
				nd.wf_state,
				nd.searchable,
				nd.hide_creators,
				NULL::TIMESTAMP AS publication_date,
				NULL::TIMESTAMP AS expiration_date,
				NULL::FLOAT AS score,
				nd.area_id AS admin_area_id,
				NULL::VARCHAR AS admin_area_name,
			    NULL::VARCHAR AS admin_area_type,
				NULL::UUID AS confidentiality_level_id,
				NULL::INTEGER AS confidentiality_level_num,
			    NULL::VARCHAR AS confidentiality_level,
				NULL::UUID AS owner_id,
				NULL::VARCHAR AS owner_name,
				nd.deleted AS archive,
				NULL::INTEGER AS likes_count,
				NULL::BOOLEAN AS like_status,
				NULL::VARCHAR AS membership_status,
				NULL::INTEGER AS visits_count,
				NULL::BOOLEAN AS is_free_user,
				NULL::BOOLEAN AS has_wiki_content,
				NULL::BOOLEAN AS has_form_content
		FROM	UNNEST(vr_node_ids) WITH ORDINALITY AS rf("id", seq)
				INNER JOIN cn_view_nodes_normal AS nd 
				ON nd.application_id = vr_application_id AND nd.node_id = rf.id
		ORDER BY rf.seq ASC;
	ELSE
		RETURN QUERY
		SELECT	node.node_id, 
				node.name,
				node.additional_id_main,
				node.additional_id,
				node.document_tree_node_id,
				tr.tree_id AS document_tree_id,
				tr.name AS document_tree_name,
				p_version.node_id AS previous_version_id,
				p_version.name AS previous_version_name,
				node.description,
				node.public_description,
				node.tags,
				node.node_type_id,
				ny.name AS node_type,
				ny.additional_id AS node_type_additional_id,
				node.creator_user_id,
				usr.username AS creator_username,
				usr.first_name AS creator_first_name,
				usr.last_name AS creator_last_name,
				node.creation_date AS creation_date,
				node.parent_node_id,
				node.status,
				node.wf_state,
				COALESCE(node.searchable, TRUE) AS searchable,
				COALESCE(node.hide_creators, FALSE) AS hide_creators,
				node.publication_date,
				node.expiration_date,
				node.score,
				area.node_id AS admin_area_id,
			    area.node_name AS admin_area_name,
			    area.type_name AS admin_area_type,
				cl.id AS confidentiality_level_id,
				cl.level_id AS confidentiality_level_num,
			    cl.title AS confidentiality_level,
				ow.node_id AS owner_id,
				ow.name AS owner_name,
				node.deleted AS archive,
				(
					SELECT COUNT(*) 
					FROM cn_node_likes AS nl
					WHERE nl.application_id = vr_application_id AND 
						nl.node_id = external_ids.value AND nl.deleted = FALSE
				) AS likes_count,
				(
					SELECT TRUE
					FROM cn_node_likes AS nl
					WHERE nl.application_id = vr_application_id AND 
						nl.node_id = external_ids.value AND 
						nl.user_id = vr_viewer_user_id AND nl.deleted = FALSE
				) AS like_status,
				(
					SELECT status
					FROM cn_node_members AS nm
					WHERE nm.application_id = vr_application_id AND 
						nm.node_id = external_ids.value AND
						nm.user_id = vr_viewer_user_id AND nm.deleted = FALSE
				) AS membership_status,
				(
					SELECT COUNT(*) 
					FROM usr_item_visits AS iv
					WHERE iv.application_id = vr_application_id AND iv.item_id = external_ids.value
				) AS visits_count,
				(
					SELECT TRUE
					FROM cn_free_users AS fu 
					WHERE fu.application_id = vr_application_id AND 
						fu.node_type_id = node.node_type_id AND 
						fu.user_id = vr_viewer_user_id AND fu.deleted = FALSE
					LIMIT 1
				) AS is_free_user,
				wk_fn_has_wiki_content(vr_application_id, node.node_id) AS has_wiki_content,
				fg_fn_has_form_content(vr_application_id, node.node_id) AS has_form_content
		FROM	UNNEST(vr_node_ids) WITH ORDINALITY AS external_ids("value", seq)
				INNER JOIN cn_nodes AS node
				ON node.application_id = vr_application_id AND node.node_id = external_ids.value
				INNER JOIN cn_node_types AS ny
				ON ny.application_id = vr_application_id AND ny.node_type_id = node.node_type_id
				LEFT JOIN users_normal AS usr
				ON usr.application_id = vr_application_id AND usr.user_id = node.creator_user_id
				LEFT JOIN cn_view_nodes_normal AS area
				ON area.application_id = vr_application_id AND area.node_id = node.area_id
				LEFT JOIN prvc_settings AS conf
				INNER JOIN prvc_confidentiality_levels AS cl
				ON cl.application_id = vr_application_id AND cl.id = conf.confidentiality_id
				ON conf.application_id = vr_application_id AND conf.object_id = node.node_id
				LEFT JOIN cn_nodes AS ow
				ON ow.application_id = vr_application_id AND ow.node_id = node.owner_id
				LEFT JOIN dct_tree_nodes AS tn
				INNER JOIN dct_trees AS tr
				ON tr.application_id = vr_application_id AND 
					tr.tree_id = tn.tree_id AND tr.deleted = FALSE
				ON tn.application_id = vr_application_id AND 
					node.document_tree_node_id IS NOT NULL AND 
					tn.tree_node_id = node.document_tree_node_id AND tn.deleted = FALSE
				LEFT JOIN cn_nodes AS p_version
				ON p_version.application_id = vr_application_id AND 
					node.previous_version_id IS NOT NULL AND 
					p_version.node_id = node.previous_version_id
			ORDER BY external_ids.seq ASC;
	END IF;
END;
$$ LANGUAGE plpgsql;
