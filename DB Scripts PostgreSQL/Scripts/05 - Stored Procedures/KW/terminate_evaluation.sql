DROP FUNCTION IF EXISTS kw_terminate_evaluation;

CREATE OR REPLACE FUNCTION kw_terminate_evaluation
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_current_user_id	UUID,
    vr_description 		VARCHAR(2000),
    vr_now		 		TIMESTAMP
)
RETURNS TABLE (
	"result"				INTEGER, 
	accepted				BOOLEAN, 
	searchability_activated	BOOLEAN
)
AS
$$
DECLARE
	vr_accepted 				BOOLEAN; 
	vr_searchability_activated 	BOOLEAN;
	vr_result					INTEGER;
BEGIN
	vr_result := ntfn_p_arithmetic_delete_dashboards(vr_application_id, NULL, vr_node_id, 
													 NULL, 'Knowledge', NULL);
		
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN;
	END IF;
	
	
	SELECT 	vr_searchability_activated = x.searchability_activated, 
			vr_accepted = x.accepted, 
			vr_result = x.result
	FROM kw_p_auto_set_knowledge_status(vr_application_id, vr_node_id, vr_now) AS x
	LIMIT 1;
		
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN;
	END IF;
	
	
	-- Create history
	INSERT INTO kw_history (
		application_id,
		knowledge_id,
		"action",
		description,
		actor_user_id,
		action_date,
		wf_version_id,
		unique_id
	)
	VALUES (
		vr_application_id,
		vr_node_id,
		'TerminateEvaluation',
		vr_description,
		vr_current_user_id,
		vr_now,
		kw_fn_get_wf_version_id(vr_application_id, vr_node_id),
		gen_random_uuid()
	);
	-- end of create history
	
	RETURN QUERY
	SELECT 	1::INTEGER AS "result", 
			vr_accepted AS accepted, 
			vr_searchability_activated AS searchability_activated;
END;
$$ LANGUAGE plpgsql;

