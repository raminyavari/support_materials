DROP PROCEDURE IF EXISTS _cn_set_nodes_order;

CREATE OR REPLACE PROCEDURE _cn_set_nodes_order
(
	vr_application_id	UUID,
	vr_ids				UUID[],
	INOUT vr_result		INTEGER
)
AS
$$
DECLARE
	vr_type_id		UUID = NULL;
	vr_parent_id	UUID = NULL;
BEGIN
	SELECT 	vr_type_id = node_type_id,
			vr_parent_id = parent_node_id
	FROM cn_nodes AS x
	WHERE x.application_id = vr_application_id AND 
		x.node_id = (SELECT rf FROM UNNEST(vr_ids) AS rf LIMIT 1)
	LIMIT 1;
	
	vr_ids := ARRAY(
		SELECT UNNEST(vr_ids)
		
		UNION ALL
	
		SELECT nd.node_id
		FROM UNNEST(vr_ids) AS rf
			RIGHT JOIN cn_nodes AS nd
			ON nd.application_id = vr_application_id AND nd.node_id = rf
		WHERE nd.application_id = vr_application_id AND (
				(nd.parent_node_id IS NULL AND vr_parent_id IS NULL) OR 
				nd.parent_node_id = vr_parent_id
			) AND rf IS NULL
		ORDER BY nd.sequence_number
	);
	
	UPDATE cn_nodes
	SET sequence_number = (rf.num)::INTEGER
	FROM UNNEST(vr_ids) WITH ORDINALITY AS rf(val, num)
		INNER JOIN cn_nodes AS nd
		ON nd.node_id = rf.val
	WHERE nd.application_id = vr_application_id AND (
			(nd.parent_node_id IS NULL AND vr_parent_id IS NULL) OR 
			nd.parent_node_id = vr_parent_id
		);
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS cn_set_nodes_order;

CREATE OR REPLACE FUNCTION cn_set_nodes_order
(
	vr_application_id	UUID,
	vr_ids				guid_table_type[]
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_nids		UUID[];
	vr_result	INTEGER = 0;
BEGIN
	vr_nids := ARRAY(
		SELECT x.value
		FROM UNNEST(vr_ids) AS x
	);
	
	CALL _cn_set_nodes_order(vr_application_id, vr_nids, vr_result);
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

