DROP FUNCTION IF EXISTS kw_remove_evaluator;

CREATE OR REPLACE FUNCTION kw_remove_evaluator
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_user_id			UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
	vr_result2	INTEGER;
BEGIN
	vr_result := ntfn_p_arithmetic_delete_dashboards(vr_application_id, vr_user_id, 
													 vr_node_id, NULL, 'Knowledge', 'Evaluator');
		
	UPDATE kw_question_answers AS qa
	SET deleted = TRUE
	WHERE qa.application_id = vr_application_id AND 
		qa.knowledge_id = vr_node_id AND qa.user_id = vr_user_id;
	
	GET DIAGNOSTICS vr_result2 := ROW_COUNT;
	
	RETURN vr_result + vr_result2;
END;
$$ LANGUAGE plpgsql;

