DROP FUNCTION IF EXISTS wf_set_workflow_state_tag;

CREATE OR REPLACE FUNCTION wf_set_workflow_state_tag
(
	vr_application_id	UUID,
    vr_workflow_id		UUID,
	vr_state_id			UUID,
	vr_tag		 		VARCHAR(450),
	vr_current_user_id	UUID,
	vr_now	 			TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_tag_id 	UUID;
	vr_tags 	VARCHAR[];
	vr_result	INTEGER DEFAULT 0;
BEGIN
	vr_tags := ARRAY(
		SELECT vr_tag
	);
	
	vr_tag_id := cn_p_add_tags(vr_application_id, vr_tags, vr_current_user_id, vr_now);
	
	UPDATE wf_workflow_states AS s
	SET tag_id = vr_tag_id
	WHERE s.application_id = vr_application_id AND 
		s.workflow_id = vr_workflow_id AND s.state_id = vr_state_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

