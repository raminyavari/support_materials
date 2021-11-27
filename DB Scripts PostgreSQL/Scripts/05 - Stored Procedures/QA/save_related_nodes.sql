DROP FUNCTION IF EXISTS qa_save_related_nodes;

CREATE OR REPLACE FUNCTION qa_save_related_nodes
(
	vr_application_id	UUID,
    vr_question_id		UUID,
    vr_node_ids			guid_table_type[],
    vr_current_user_id	UUID,
    vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
BEGIN
	UPDATE qa_related_nodes
	SET deleted = CASE WHEN n.value IS NULL THEN TRUE ELSE FALSE END::BOOLEAN,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM UNNEST(vr_node_ids) AS n
		RIGHT JOIN qa_related_nodes AS r
		ON r.node_id = n.value
	WHERE r.application_id = vr_application_id AND r.question_id = vr_question_id;
			
	INSERT INTO qa_related_nodes (
		application_id, 
		question_id, 
		node_id,
		creator_user_id,
		creation_date,
		deleted
	)
	SELECT 	vr_application_id, 
			vr_question_id, 
			n.value, 
			vr_current_user_id, 
			vr_now, 
			FALSE
	FROM UNNEST(vr_node_ids) AS n
		LEFT JOIN qa_related_nodes AS r
		ON r.application_id = vr_application_id AND 
			r.question_id = vr_question_id AND r.node_id = n.value
	WHERE r.node_id IS NULL;
	
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

