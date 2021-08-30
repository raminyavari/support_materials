DROP PROCEDURE IF EXISTS _cn_arithmetic_delete_node_types;

CREATE OR REPLACE PROCEDURE _cn_arithmetic_delete_node_types
(
	vr_application_id	UUID,
    vr_node_type_ids 	UUID[],
    vr_remove_hierarchy	BOOLEAN,
    vr_current_user_id	UUID,
    vr_now 				TIMESTAMP,
	INOUT vr_result		INTEGER
)
AS
$$
BEGIN
	vr_result := 0;

	IF COALESCE(vr_remove_hierarchy, FALSE) = FALSE THEN
		UPDATE nt
		SET deleted = TRUE,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
		FROM UNNEST(vr_node_type_ids) AS rf
			INNER JOIN cn_node_types AS nt
			ON nt.application_id = vr_application_id AND 
				nt.node_type_id = rf AND nt.deleted = FALSE;
		
		GET DIAGNOSTICS vr_result := ROW_COUNT;
			
		UPDATE cn_node_types
			SET parent_id = NULL
		WHERE application_id = vr_application_id AND parent_id IN (SELECT UNNEST(vr_node_type_ids));
	ELSE
		UPDATE NT
		SET deleted = TRUE,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
		FROM cn_fn_get_child_node_types_hierarchy(vr_application_id, vr_node_type_ids) AS rf
			INNER JOIN cn_node_types AS nt
			ON nt.application_id = vr_application_id AND nt.node_type_id = rf.node_type_id;
			
		GET DIAGNOSTICS vr_result := ROW_COUNT;
	END IF;
	
	COMMIT;
END;
$$ LANGUAGE plpgsql;



DROP FUNCTION IF EXISTS cn_arithmetic_delete_node_types;

CREATE OR REPLACE FUNCTION cn_arithmetic_delete_node_types
(
	vr_application_id	UUID,
    vr_node_type_ids 	guid_table_type[],
    vr_remove_hierarchy	BOOLEAN,
    vr_current_user_id	UUID,
    vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_nt_ids	UUID[];
	vr_result	INTEGER;
BEGIN
	vr_nt_ids := ARRAY(
		SELECT x.value
		FROM UNNEST(vr_node_type_ids) AS x
	);

	CALL _cn_arithmetic_delete_node_types(vr_application_id, vr_nt_ids, vr_remove_hierarchy,
										  vr_current_user_id, vr_now, vr_result);
							
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

