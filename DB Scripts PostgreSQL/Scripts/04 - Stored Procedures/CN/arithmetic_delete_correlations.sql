DROP FUNCTION IF EXISTS cn_arithmetic_delete_correlations;

CREATE OR REPLACE FUNCTION cn_arithmetic_delete_correlations
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
	vr_related_relation_type_id	UUID;
BEGIN
	vr_related_relation_type_id := cn_fn_get_related_relation_type_id(vr_application_id);

	return cn_p_arithmetic_delete_relations(vr_application_id, vr_pair_node_ids, vr_related_relation_type_id,
										   vr_current_user_id, vr_now, TRUE);
END;
$$ LANGUAGE plpgsql;

