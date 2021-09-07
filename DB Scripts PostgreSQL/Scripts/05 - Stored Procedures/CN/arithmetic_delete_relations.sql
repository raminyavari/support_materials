DROP PROCEDURE IF EXISTS _cn_arithmetic_delete_relations;

CREATE OR REPLACE PROCEDURE _cn_arithmetic_delete_relations
(
	vr_application_id	UUID,
	vr_pair_node_ids	guid_pair_table_type[],
    vr_relation_type_id UUID,
    vr_current_user_id	UUID,
    vr_now				TIMESTAMP,
    vr_reverse_also		BOOLEAN,
	INOUT vr_result		INTEGER
)
AS
$$
BEGIN
	vr_result := cn_p_arithmetic_delete_relations(vr_application_id, vr_pair_node_ids, vr_relation_type_id,
										   vr_current_user_id, vr_now, vr_reverse_also);
										   
	IF vr_result <= 0 THEN
		CALL gfn_raise_exception(vr_result, NULL);
	END IF;
END;
$$ LANGUAGE plpgsql;



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
DECLARE
	vr_result	INTEGER;
BEGIN
	CALL _cn_arithmetic_delete_relations(vr_application_id, vr_pair_node_ids, vr_relation_type_id,
										   vr_current_user_id, vr_now, vr_reverse_also, vr_result);
										   
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

