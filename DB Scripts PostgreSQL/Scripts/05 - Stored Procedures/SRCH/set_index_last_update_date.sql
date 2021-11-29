DROP FUNCTION IF EXISTS srch_set_index_last_update_date;

CREATE OR REPLACE FUNCTION srch_set_index_last_update_date
(
	vr_application_id	UUID,
	vr_item_type		VARCHAR(20),
	vr_ids				guid_table_type[],
	vr_date		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF vr_item_type = 'Node' THEN
		UPDATE cn_nodes
		SET index_last_update_date = vr_date
		FROM UNNEST(vr_ids) AS ids
			INNER JOIN cn_nodes AS rf
			ON rf.application_id = vr_application_id AND rf.node_id = ids.value;
	ELSEIF vr_item_type = 'NodeType' THEN
		UPDATE cn_node_types
		SET index_last_update_date = vr_date
		FROM UNNEST(vr_ids) AS ids
			INNER JOIN cn_node_types AS rf
			ON rf.application_id = vr_application_id AND rf.node_type_id = ids.value;
	ELSEIF vr_item_type = 'Question' THEN
		UPDATE qa_questions
		SET index_last_update_date = vr_date
		FROM UNNEST(vr_ids) AS ids
			INNER JOIN qa_questions AS rf
			ON rf.application_id = vr_application_id AND rf.question_id = ids.value;
	ELSEIF vr_item_type = 'File' THEN
		UPDATE dct_file_contents
		SET index_last_update_date = vr_date
		FROM UNNEST(vr_ids) AS ids
			INNER JOIN dct_file_contents AS rf
			ON rf.application_id = vr_application_id AND rf.file_id = ids.value;
	ELSEIF vr_item_type = 'User' THEN
		UPDATE usr_profile
		SET index_last_update_date = vr_date
		FROM UNNEST(vr_ids) AS ids
			INNER JOIN usr_profile AS rf
			ON rf.user_id = ids.value;
	END IF;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

