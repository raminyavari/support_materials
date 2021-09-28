DROP FUNCTION IF EXISTS cn_p_add_nodes_to_list;

CREATE OR REPLACE FUNCTION cn_p_add_nodes_to_list
(
	vr_application_id	UUID,
	vr_list_id			UUID,
    vr_node_ids			UUID[],
    vr_current_user_id	UUID,
    vr_now				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_upd_result 	INTEGER;
	vr_ins_result	INTEGER;
BEGIN
	UPDATE cn_list_nodes
	SET last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now,
		deleted = FALSE
	FROM UNNEST(vr_node_ids) AS x
		INNER JOIN cn_list_nodes AS l
		ON l.application_id = vr_application_id AND l.list_id = vr_list_id AND l.node_id = x;
		
	GET DIAGNOSTICS vr_upd_result := ROW_COUNT;

	INSERT INTO cn_list_nodes (
		application_id,
		list_id,
		node_id,
		creator_user_id,
		creation_date,
		deleted
	)
	SELECT vr_application_id, vr_list_id, x, vr_current_user_id, vr_now, FALSE
	FROM UNNEST(vr_node_ids) AS x
		LEFT JOIN cn_list_nodes AS l
		ON l.application_id = vr_application_id AND l.list_id = vr_list_id AND l.node_id = x
	WHERE l.list_id IS NULL;
		
	GET DIAGNOSTICS vr_ins_result := ROW_COUNT;
	
	RETURN vr_upd_result + vr_ins_result;
END;
$$ LANGUAGE plpgsql;
