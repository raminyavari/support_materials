
DROP PROCEDURE IF EXISTS _cn_recover_node_type;

CREATE OR REPLACE PROCEDURE _cn_recover_node_type
(
	vr_application_id	UUID,
    vr_node_type_id 	UUID,
    vr_current_user_id	UUID,
    vr_now 				TIMESTAMP,
	INOUT vr_result		INTEGER
)
AS
$$
DECLARE
	vr_parent_deleted	BOOLEAN;
BEGIN
	vr_result := 0;

	UPDATE cn_node_types
	SET deleted = FALSE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE application_id = vr_application_id AND node_type_id = vr_node_type_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	vr_parent_deleted := (
		SELECT "p".deleted
		FROM cn_node_types AS nt
			INNER JOIN cn_node_types AS "p"
			ON "p".application_id = vr_application_id AND "p".node_type_id = nt.parent_id
		WHERE nt.application_id = vr_application_id AND 
			nt.node_type_id = vr_node_type_id AND nt.parent_id IS NOT NULL
		LIMIT 1
	)::BOOLEAN;
	
	IF COALESCE(vr_parent_deleted, FALSE) = TRUE THEN
		UPDATE cn_node_types
		SET parent_id = NULL
		WHERE application_id = vr_application_id AND node_type_id = vr_node_type_id;
	END IF;
END;
$$ LANGUAGE plpgsql;



DROP FUNCTION IF EXISTS cn_recover_node_type;

CREATE OR REPLACE FUNCTION cn_recover_node_type
(
	vr_application_id	UUID,
    vr_node_type_id 	UUID,
    vr_current_user_id	UUID,
    vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	CALL _cn_recover_node_type(vr_application_id, vr_node_type_id, vr_current_user_id, vr_now, vr_result);
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

