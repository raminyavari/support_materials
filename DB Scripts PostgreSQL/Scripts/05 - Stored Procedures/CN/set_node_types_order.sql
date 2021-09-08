DROP PROCEDURE IF EXISTS _cn_set_node_types_order;

CREATE OR REPLACE PROCEDURE _cn_set_node_types_order
(
	vr_application_id	UUID,
	vr_ids				UUID[],
	INOUT vr_result		INTEGER
)
AS
$$
DECLARE
	vr_parent_id	UUID = NULL;
BEGIN
	SELECT vr_parent_id = x.parent_id
	FROM cn_node_types AS x
	WHERE x.application_id = vr_application_id AND 
		x.node_type_id = (SELECT rf FROM UNNEST(vr_ids) AS rf LIMIT 1)
	LIMIT 1;
	
	vr_ids := ARRAY(
		SELECT UNNEST(vr_ids)
		
		UNION ALL
	
		SELECT nt.node_type_id
		FROM UNNEST(vr_ids) AS rf
			RIGHT JOIN cn_node_types AS nt
			ON nt.application_id = vr_application_id AND nt.node_type_id = rf
		WHERE nt.application_id = vr_application_id AND (
				(nt.parent_id IS NULL AND vr_parent_id IS NULL) OR 
				nt.parent_id = vr_parent_id
			) AND rf IS NULL
		ORDER BY nt.sequence_number
	);
	
	UPDATE cn_node_types
	SET sequence_number = (rf.num)::INTEGER
	FROM UNNEST(vr_ids) WITH ORDINALITY AS rf(val, num)
		INNER JOIN cn_node_types AS nt
		ON nt.node_type_id = rf.val
	WHERE nt.application_id = vr_application_id AND (
			(nt.parent_id IS NULL AND vr_parent_id IS NULL) OR 
			nt.parent_id = vr_parent_id
		);
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS cn_set_node_types_order;

CREATE OR REPLACE FUNCTION cn_set_node_types_order
(
	vr_application_id	UUID,
	vr_ids				guid_table_type[]
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_nt_ids	UUID[];
	vr_result	INTEGER = 0;
BEGIN
	vr_nt_ids := ARRAY(
		SELECT x.value
		FROM UNNEST(vr_ids) AS x
	);
	
	CALL _cn_set_node_types_order(vr_application_id, vr_nt_ids, vr_result);
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

