DROP FUNCTION IF EXISTS qa_remove_related_nodes;

CREATE OR REPLACE FUNCTION qa_remove_related_nodes
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
	SET deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM UNNEST(vr_node_ids) AS n
		INNER JOIN qa_related_nodes AS r
		ON r.application_id = vr_application_id AND r.question_id = vr_question_id AND r.node_id = n.value;
	
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

