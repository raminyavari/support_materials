DROP FUNCTION IF EXISTS wf_fn_get_dashboard_info;

CREATE OR REPLACE FUNCTION wf_fn_get_dashboard_info
(
	vr_workflow_name	 		VARCHAR(1000),
	vr_stateTitle		 		VARCHAR(1000),
	vr_data_need_instance_id	UUID
)
RETURNS VARCHAR
AS
$$
BEGIN
	RETURN '{"WorkFlowName":"' || COALESCE(gfn_base64_encode(vr_workflow_name), '') ||
		'","WorkFlowState":"' || COALESCE(gfn_base64_encode(vr_stateTitle), '') ||
		(
			CASE
				WHEN vr_data_need_instance_id IS NULL THEN ''
				ELSE '","DataNeedInstanceID":"' || vr_data_need_instance_id::VARCHAR(50)
			END
		) ||
		'"}';
END;
$$ LANGUAGE PLPGSQL;