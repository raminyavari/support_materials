DROP PROCEDURE IF EXISTS _cn_unparent;

CREATE OR REPLACE PROCEDURE _cn_unparent
(
	vr_application_id	UUID,
	vr_pair_node_ids	guid_pair_table_type[],
    vr_current_user_id	UUID,
    vr_now				TIMESTAMP,
	INOUT vr_result		INTEGER
)
AS
$$
DECLARE
	vr_node_ids					guid_pair_table_type[];
	vr_parent_relation_type_id	UUID;
	vr_child_relation_type_id 	UUID;
	vr_first_result				INTEGER = -1;
	vr_second_result			INTEGER = -1;
BEGIN	
	vr_parent_relation_type_id := cn_fn_get_parent_relation_type_id(vr_application_id);
	vr_child_relation_type_id := cn_fn_get_child_relation_type_id(vr_application_id);
	
	vr_node_ids := ARRAY(
		SELECT ROW(r.first_value, r.second_value)
		FROM UNNEST(vr_pair_node_ids) AS r
	);
	
	vr_first_result := cn_p_arithmetic_delete_relations(vr_application_id, vr_node_ids, 
							vr_parent_relation_type_id, vr_current_user_id, vr_now, FALSE);
							
	vr_node_ids := ARRAY(
		SELECT ROW(r.second_value, r.first_value)
		FROM UNNEST(vr_pair_node_ids) AS r
	);
	
	vr_second_result := cn_p_arithmetic_delete_relations(vr_application_id, vr_node_ids, 
							vr_child_relation_type_id, vr_current_user_id, vr_now, FALSE);
							
	IF vr_first_result <= 0 OR vr_second_result <= 0 THEN
		vr_result := -1;
		CALL gfn_raise_exception(vr_result, NULL);
	ELSE
		vr_result := vr_first_result + vr_second_result;
	END IF;
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS cn_unparent;

CREATE OR REPLACE FUNCTION cn_unparent
(
	vr_application_id	UUID,
	vr_pair_node_ids	guid_pair_table_type[],
    vr_current_user_id	UUID,
    vr_now				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER = 0;
BEGIN	
	CALL _cn_unparent(vr_application_id, vr_pair_node_ids, vr_current_user_id, vr_now, vr_result);
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

