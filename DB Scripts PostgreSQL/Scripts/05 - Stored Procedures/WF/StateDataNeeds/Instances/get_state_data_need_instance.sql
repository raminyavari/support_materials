DROP FUNCTION IF EXISTS wf_get_state_data_need_instance;

CREATE OR REPLACE FUNCTION wf_get_state_data_need_instance
(
	vr_application_id	UUID,
    vr_instance_id		UUID
)
RETURNS SETOF wf_state_data_need_instance_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT *
	FROM wf_p_get_state_data_need_instances(vr_application_id, ARRAY(SELECT vr_instance_id));
END;
$$ LANGUAGE plpgsql;

