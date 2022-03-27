DROP FUNCTION IF EXISTS wf_arithmetic_delete_state_data_need_instance;

CREATE OR REPLACE FUNCTION wf_arithmetic_delete_state_data_need_instance
(
	vr_application_id	UUID,
    vr_instance_id		UUID,
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result			INTEGER;
BEGIN
	UPDATE wf_state_data_need_instances AS d
	SET deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE d.application_id = vr_application_id AND 
		d.instance_id = vr_instance_id AND d.deleted = FALSE;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN -1::INTEGER;
	END IF;
	
	vr_result := ntfn_p_arithmetic_delete_dashboards(vr_application_id, NULL, NULL, vr_instance_id, 'WorkFlow');

	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN -1::INTEGER;
	END IF;
	
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

