DROP FUNCTION IF EXISTS wf_set_state_data_need_instance_as_not_filled;

CREATE OR REPLACE FUNCTION wf_set_state_data_need_instance_as_not_filled
(
	vr_application_id	UUID,
    vr_instance_id		UUID,
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS SETOF REFCURSOR
AS
$$
DECLARE
	vr_form_instance_id	UUID;
	vr_result			INTEGER;
	vr_cur_result		REFCURSOR;
	vr_cur_dash			REFCURSOR;
BEGIN
	UPDATE wf_state_data_need_instances AS d
	SET filled = FALSE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE d.application_id = vr_application_id AND 
		d.instance_id = vr_instance_id AND d.filled = TRUE;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN;
	END IF;
	
	SELECT 	fi.instance_id
	INTO 	vr_form_instance_id
	FROM wf_state_data_need_instances AS dn
		INNER JOIN fg_form_instances AS fi
		ON fi.application_id = vr_application_id AND fi.owner_id = dn.instance_id
	WHERE dn.application_id = vr_application_id AND
		dn.instance_id = vr_instanceID AND fi.filled = 1 AND fi.deleted = FALSE
	LIMIT 1;
	
	IF vr_form_instance_id IS NOT NULL THEN
		vr_result := fg_p_set_form_instance_as_not_filled(vr_application_id, 
														  vr_form_instance_id, vr_current_user_id);
		
		IF vr_result <= 0 THEN
			EXECUTE gfn_raise_exception(-1::INTEGER);
			RETURN;
		END IF;
	END IF;
	
	SELECT 	x.result, x.dashboards
	INTO	vr_result, vr_cur_dash
	FROM wf_p_send_dashboards(vr_application_id, NULL, NULL, NULL, NULL, 
							  NULL, NULL, vr_instance_id, vr_now) AS x;
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER, 'CannotDetermineDirector');
		RETURN;
	END IF;
	
	OPEN vr_cur_result FOR
	SELECT 1::INTEGER;
	
	RETURN NEXT vr_cur_dash;
	RETURN NEXT vr_cur_result;
END;
$$ LANGUAGE plpgsql;

