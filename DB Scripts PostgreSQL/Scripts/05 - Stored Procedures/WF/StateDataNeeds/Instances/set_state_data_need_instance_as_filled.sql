DROP FUNCTION IF EXISTS wf_set_state_data_need_instance_as_filled;

CREATE OR REPLACE FUNCTION wf_set_state_data_need_instance_as_filled
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
	vr_form_instance_id	UUID;
	vr_result			INTEGER;
BEGIN
	UPDATE wf_state_data_need_instances AS d
	SET filled = TRUE,
		filling_date = vr_last_modification_date,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE d.application_id = vr_application_id AND 
		d.instance_id = vr_instance_id AND d.filled = FALSE;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN -1::INTEGER;
	END IF;
	
	SELECT 	fi.instance_id
	INTO 	vr_form_instance_id
	FROM wf_state_data_need_instances AS dn
		INNER JOIN fg_form_instances AS fi
		ON fi.application_id = vr_application_id AND fi.owner_id = dn.instance_id
	WHERE dn.application_id = vr_application_id AND 
		dn.instance_id = vr_instance_id AND fi.filled = FALSE AND fi.deleted = FALSE
	LIMIT 1;
	
	IF vr_form_instance_id IS NOT NULL THEN	
		vr_result := fg_p_set_form_instance_as_filled(vr_application_id, vr_form_instance_id, 
													  vr_now, vr_current_user_id);
		
		IF vr_result <= 0 THEN
			EXECUTE gfn_raise_exception(-1::INTEGER);
			RETURN -1::INTEGER;
		END IF;
	END IF;
	
	vr_result := ntfn_p_set_dashboards_as_done(vr_application_id, NULL, NULL, 
											   vr_instance_id, 'WorkFlow', NULL, vr_now);

	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN -1::INTEGER;
	END IF;
	
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

