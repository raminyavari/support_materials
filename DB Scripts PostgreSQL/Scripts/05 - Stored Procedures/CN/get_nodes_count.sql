DROP FUNCTION IF EXISTS cn_get_nodes_count;

CREATE OR REPLACE FUNCTION cn_get_nodes_count
(
	vr_application_id				UUID,
    vr_node_type_ids				guid_table_type[],
    vr_node_type_addtional_id 		VARCHAR(255),
    vr_lower_creation_date_limit	TIMESTAMP,
    vr_upper_creation_date_limit 	TIMESTAMP,
    vr_root				 			BOOLEAN,
    vr_archive			 			BOOLEAN
)
RETURNS TABLE (
	node_type_id			UUID, 
	node_type_additional_id	VARCHAR, 
	type_name				VARCHAR,
	nodes_count				BIGINT
)
AS
$$
DECLARE
	vr_nt_ids	UUID[];
BEGIN
	IF vr_root = FALSE THEN
		vr_root := NULL;
	END IF;
	
	vr_nt_ids := ARRAY(
		SELECT DISTINCT x.value
		FROM UNNEST(vr_node_type_ids) AS x
	);
	
	IF vr_node_type_addtional_id IS NOT NULL AND COALESCE(ARRAY_LENGTH(vr_nt_ids, 1), 0) = 0 THEN
		vr_nt_ids := ARRAY(
			SELECT x.val
			FROM (
					SELECT cn_fn_get_node_type_id(vr_application_id, vr_node_type_addtional_id) AS val
				) AS x
			WHERE x.val IS NOT NULL
		);
	END IF;
	
	IF COALESCE(ARRAY_LENGTH(vr_nt_ids, 1), 0) = 0 THEN
		vr_nt_ids := ARRAY(
			SELECT nt.node_type_id
			FROM cn_node_types as nt
			WHERE application_id = vr_application_id AND deleted = FALSE
		);
	END IF;
	
	RETURN QUERY
	SELECT rf.node_type_id, 
		   COALESCE(nt.additional_id, N'') AS node_type_additional_id, 
		   nt.name AS type_name,
		   rf.nodes_count::BIGINT
	FROM (
			SELECT cvn.node_type_id, 
				COUNT(cvn.node_id) AS nodes_count
			FROM UNNEST(vr_nt_ids) AS x
				INNER JOIN cn_nodes AS cvn
				ON cvn.application_id = vr_application_id AND cvn.node_type_id = x
			WHERE (vr_lower_creation_date_limit IS NULL OR 
				cvn.creation_date >= vr_lower_creation_date_limit) AND
				(vr_upper_creation_date_limit IS NULL OR 
				cvn.creation_date <= vr_upper_creation_date_limit) AND
				(vr_root IS NULL OR cvn.parent_node_id IS NULL) AND
				(vr_archive IS NULL OR cvn.deleted = vr_archive)
			GROUP BY cvn.node_type_id
		) AS rf
		LEFT JOIN cn_node_types AS nt
		ON nt.application_id = vr_application_id AND nt.node_type_id = rf.node_type_id;
END;
$$ LANGUAGE plpgsql;
