DROP FUNCTION IF EXISTS wf_modify_auto_message;

CREATE OR REPLACE FUNCTION wf_modify_auto_message
(
	vr_application_id	UUID,
	vr_auto_message_id	UUID,
	vr_body_text	 	VARCHAR(4000),
	vr_audience_type	VARCHAR(20),
	vr_ref_state_id		UUID,
	vr_node_id			UUID,
	vr_admin		 	BOOLEAN,
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	vr_body_text := gfn_verify_string(vr_body_text);
	vr_admin := COALESCE(vr_admin, FALSE)::BOOLEAN;
	
	UPDATE wf_auto_messages AS "m"
	SET	body_text = vr_body_text,
		audience_type = vr_audience_type,
		ref_state_id = vr_ref_state_id,
		node_id = vr_node_id,
		"admin" = vr_admin,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE "m".application_id = vr_application_id AND "m".auto_message_id = vr_auto_message_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

