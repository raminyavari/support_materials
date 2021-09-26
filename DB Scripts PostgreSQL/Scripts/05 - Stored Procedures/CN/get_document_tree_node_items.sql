DROP FUNCTION IF EXISTS cn_get_document_tree_node_items;

CREATE OR REPLACE FUNCTION cn_get_document_tree_node_items
(
	vr_application_id	UUID,
	vr_tree_node_id		UUID,
	vr_current_user_id	UUID,
	vr_check_privacy 	BOOLEAN,
	vr_now		 		TIMESTAMP,
	vr_default_privacy 	VARCHAR(20),
	vr_count		 	INTEGER,
	vr_lower_boundary 	INTEGER
)
RETURNS SETOF cn_node_ret_composite
AS
$$
DECLARE
	vr_ret_ids			UUID[];
	vr_permission_types string_pair_table_type[];
BEGIN
	vr_ret_ids := ARRAY(
		SELECT DISTINCT "t".node_id
		FROM cn_nodes AS nd
			RIGHT JOIN (
				SELECT nd.node_id
				FROM cn_nodes AS nd
				WHERE nd.application_id = vr_application_id AND nd.document_tree_node_id = vr_tree_node_id AND	
					nd.deleted = FALSE AND COALESCE(nd.searchable, TRUE) = TRUE AND
					(COALESCE(nd.status, '') = '' OR nd.status = 'Accepted')
			) AS "t"
			ON nd.application_id = vr_application_id AND "t".node_id = nd.previous_version_id AND 
				nd.deleted = FALSE AND COALESCE(nd.searchable, TRUE) = TRUE AND
				(COALESCE(nd.status, '') = '' OR nd.status = 'Accepted')
		WHERE nd.node_id IS NULL
	);
	
	IF vr_check_privacy = TRUE THEN
		vr_permission_types := ARRAY(
			SELECT ROW('View', vr_default_privacy)
		);
	
		vr_ret_ids := ARRAY(
			SELECT rf.id
			FROM prvc_fn_check_access(vr_application_id, vr_current_user_id, 
				vr_ret_ids, 'Node', vr_now, vr_permission_types) AS rf
		);
	END IF;
	
	vr_ret_ids := ARRAY(
		SELECT x.id
		FROM (
				SELECT	ROW_NUMBER() OVER(ORDER BY v.seq ASC) AS "row_number",
						v.id
				FROM UNNEST(vr_ret_ids) WITH ORDINALITY AS v("id", seq)
			) AS x
		WHERE x.row_number >= COALESCE(vr_lower_boundary, 0)
		ORDER BY x.row_number ASC
		LIMIT COALESCE(vr_count, 1000)
	);
	
	RETURN QUERY
	SELECT *
	FROM cn_p_get_nodes_by_ids(vr_application_id, vr_ret_ids, NULL, NULL);
END;
$$ LANGUAGE plpgsql;
