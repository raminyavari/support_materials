DROP FUNCTION IF EXISTS cn_arithmetic_delete_relations;

CREATE OR REPLACE FUNCTION cn_arithmetic_delete_relations
(
	vr_application_id	UUID,
	vr_pair_node_ids	guid_pair_table_type[],
    vr_relation_type_id UUID,
    vr_current_user_id	UUID,
    vr_now				TIMESTAMP,
    vr_reverse_also		BOOLEAN
)
RETURNS INTEGER
AS
$$
BEGIN
	return cn_p_arithmetic_delete_relations(vr_application_id, vr_pair_node_ids, vr_relation_type_id,
										   vr_current_user_id, vr_now, vr_reverse_also);
END;
$$ LANGUAGE plpgsql;

