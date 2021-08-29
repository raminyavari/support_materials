DROP FUNCTION IF EXISTS cn_p_make_parent;

CREATE OR REPLACE FUNCTION cn_p_make_parent
(
	vr_application_id	UUID,
	vr_pair_node_ids	guid_pair_table_type[],
    vr_creator_user_id	UUID,
    vr_creation_date	TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_parent_relation_type_id	UUID;
	vr_child_relation_type_id 	UUID;
	vr_relations 				guid_triple_table_type[];
	vr_result 					INTEGER = -1;
BEGIN
	vr_parent_relation_type_id := cn_fn_get_parent_relation_type_id(vr_application_id);
	vr_child_relation_type_id := cn_fn_get_child_relation_type_id(vr_application_id);
	
	vr_relations := ARRAY(
		SELECT ROW(r.first_value, r.second_value, vr_parent_relation_type_id)
		FROM UNNEST(vr_pair_node_ids) AS r
		
		UNION ALL
		
		SELECT ROW(r.second_value, r.first_value, vr_child_relation_type_id)
		FROM UNNEST(vr_pair_node_ids) AS r
	);
	
	RETURN cn_p_add_relation(vr_application_id, vr_relations, 
		vr_creator_user_id, vr_creation_date, FALSE);
END;
$$ LANGUAGE plpgsql;

