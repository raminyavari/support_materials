DROP FUNCTION IF EXISTS cn_p_get_services_by_ids;

CREATE OR REPLACE FUNCTION cn_p_get_services_by_ids
(
	vr_application_id	UUID,
	vr_node_type_ids	UUID[],
	vr_total_count		INTEGER DEFAULT 0
)
RETURNS SETOF cn_service_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT s.node_type_id,
		   nt.name AS node_type,
		   s.service_title,
		   s.service_description,
		   s.admin_type,
		   s.admin_node_id,
		   s.max_acceptable_admin_level,
		   s.limit_attached_files_to,
		   s.max_attached_file_size,
		   s.max_attached_files_count,
		   s.enable_contribution,
		   s.no_content,
		   s.is_document,
		   s.enable_previous_version_select,
		   s.is_knowledge,
		   s.is_tree,
		   s.unique_membership,
		   s.unique_admin_member,
		   s.disable_abstract_and_keywords,
		   s.disable_file_upload,
		   s.disable_related_nodes_select,
		   s.editable_for_admin,
		   s.editable_for_creator,
		   s.editable_for_owners,
		   s.editable_for_experts,
		   s.editable_for_members,
		   COALESCE(s.edit_suggestion, TRUE)::BOOLEAN AS edit_suggestion,
		   vr_total_count
	FROM UNNEST(vr_node_type_ids) WITH ORDINALITY AS x("id", seq)
		INNER JOIN cn_services AS s
		ON s.application_id = vr_application_id AND s.node_type_id = x.id
		INNER JOIN cn_node_types AS nt
		ON nt.application_id = vr_application_id AND nt.node_type_id = s.node_type_id
	ORDER BY x.seq ASC;
END;
$$ LANGUAGE plpgsql;
