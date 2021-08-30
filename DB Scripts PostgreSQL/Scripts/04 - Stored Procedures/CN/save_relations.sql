DROP PROCEDURE IF EXISTS _cn_save_relations;

CREATE OR REPLACE PROCEDURE _cn_save_relations
(
	vr_application_id	UUID,
	vr_node_id			UUID,
	vr_related_node_ids	UUID[],
    vr_creator_user_id	UUID,
    vr_creation_date	TIMESTAMP,
	INOUT vr_result		INTEGER
)
AS
$$
DECLARE
	vr_related_relation_type_id	UUID;
	vr_relations				guid_triple_table_type;
BEGIN
	UPDATE cn_node_relations
	SET deleted = TRUE
	WHERE application_id = vr_application_id AND source_node_id = vr_node_id AND deleted = FALSE;
	
	vr_related_relation_type_id := cn_fn_get_related_relation_type_id(vr_application_id);
	
	vr_relations = ARRAY(
		SELECT ROW(vr_node_id, "id", vr_related_relation_type_id)
		FROM UNNEST(vr_related_node_ids) AS "id"
	);
	
	vr_result := cn_p_add_relation(vr_application_id, vr_relations, vr_creator_user_id, vr_creation_date, TRUE);
	
	IF vr_result <= 0 THEN
		ROLLBACK;
	ELSE
		COMMIT;
	END IF;
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS cn_save_relations;

CREATE OR REPLACE FUNCTION cn_save_relations
(
	vr_application_id	UUID,
	vr_node_id			UUID,
	vr_related_node_ids	UUID[],
    vr_creator_user_id	UUID,
    vr_creation_date	TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER = 0;
BEGIN
	CALL _cn_save_relations(vr_application_id, vr_node_id, vr_related_node_ids,
								   vr_creator_user_id, vr_creation_date, vr_result);
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

