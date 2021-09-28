DROP FUNCTION IF EXISTS cn_get_services;

CREATE OR REPLACE FUNCTION cn_get_services
(
	vr_application_id	UUID,
	vr_node_type_id		UUID,
	vr_current_user_id	UUID,
	vr_is_document	 	BOOLEAN,
	vr_is_knowledge 	BOOLEAN,
	vr_check_privacy 	BOOLEAN,
	vr_now		 		TIMESTAMP,
	vr_default_privacy 	VARCHAR(20)
)
RETURNS SETOF cn_service_ret_composite
AS
$$
DECLARE
	vr_permission_types string_pair_table_type[];
	vr_ret_ids			UUID[];
BEGIN
	IF vr_node_type_id IS NOT NULL THEN
		vr_node_type_id = COALESCE((
			SELECT nd.node_type_id 
			FROM cn_nodes AS nd 
			WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_type_id
			LIMIT 1
		), vr_node_type_id);
	END IF;
	
	vr_ret_ids := ARRAY(
		SELECT s.node_type_id
		FROM cn_services AS s
			INNER JOIN cn_node_types AS nt
			ON nt.application_id = vr_application_id AND 
				nt.node_type_id = s.node_type_id AND COALESCE(nt.deleted, FALSE) = FALSE
		WHERE s.application_id = vr_application_id AND
			(vr_node_type_id IS NULL OR s.node_type_id = vr_node_type_id) AND
			(vr_is_document IS NULL OR s.is_document = vr_is_document) AND
			(vr_is_knowledge IS NULL OR s.is_knowledge = vr_is_knowledge) AND
			(vr_node_type_id IS NOT NULL OR (s.service_title IS NOT NULL AND s.service_title <> '')) AND 
			s.deleted = FALSE
		ORDER BY nt.sequence_number ASC, nt.creation_date DESC
	);
	
	IF vr_node_type_id IS NULL AND vr_check_privacy = TRUE THEN
		vr_permission_types := ARRAY(
			SELECT ROW('Create', vr_default_privacy)
		);

		vr_ret_ids := ARRAY(
			SELECT rf.id
			FROM prvc_fn_check_access(vr_application_id, vr_current_user_id, 
					vr_ret_ids, 'NodeType', vr_now, vr_permission_types) AS rf
				INNER JOIN UNNEST(vr_ret_ids) WITH ORDINALITY AS x("id", seq)
				ON x.id = rf.id
			ORDER BY x.seq ASC
		);
	END IF;
	
	RETURN QUERY
	SELECT *
	FROM cn_p_get_services_by_ids(vr_application_id, vr_ret_ids);
END;
$$ LANGUAGE plpgsql;
