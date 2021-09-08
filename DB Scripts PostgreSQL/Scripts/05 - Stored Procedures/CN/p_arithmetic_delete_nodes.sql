DROP PROCEDURE IF EXISTS _cn_p_arithmetic_delete_nodes;

CREATE OR REPLACE PROCEDURE _cn_p_arithmetic_delete_nodes
(
	vr_application_id	UUID,
    vr_node_ids			UUID[],
    vr_remove_hierarchy	BOOLEAN,
    vr_current_user_id	UUID,
    vr_now 				TIMESTAMP,
	INOUT vr_result		INTEGER
)
AS
$$
BEGIN
	IF COALESCE(vr_remove_hierarchy, FALSE) = FALSE THEN
		UPDATE cn_nodes
		SET deleted = TRUE,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
		FROM UNNEST(vr_node_ids) AS rf
			INNER JOIN cn_nodes AS nd
			ON nd.application_id = vr_application_id AND nd.node_id = rf AND nd.deleted = FALSE;
		
		GET DIAGNOSTICS vr_result := ROW_COUNT;
			
		UPDATE cn_nodes AS x
		SET parent_node_id = NULL
		WHERE x.application_id = vr_application_id AND x.parent_node_id IN (SELECT UNNEST(vr_node_ids));
	ELSE
		UPDATE cn_nodes
		SET deleted = TRUE,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
		FROM cn_fn_get_child_nodes_hierarchy(vr_application_id, vr_node_ids) AS rf
			INNER JOIN cn_nodes AS nd
			ON nd.application_id = vr_application_id AND nd.node_id = rf.node_id;
			
		GET DIAGNOSTICS vr_result := ROW_COUNT;
	END IF;
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS cn_p_arithmetic_delete_nodes;

CREATE OR REPLACE FUNCTION cn_p_arithmetic_delete_nodes
(
	vr_application_id	UUID,
    vr_node_ids			UUID[],
    vr_remove_hierarchy	BOOLEAN,
    vr_current_user_id	UUID,
    vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER = 0;
BEGIN	
	CALL _cn_p_arithmetic_delete_nodes(vr_application_id, vr_node_ids, vr_remove_hierarchy, 
									   vr_current_user_id, vr_now, vr_result);
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

