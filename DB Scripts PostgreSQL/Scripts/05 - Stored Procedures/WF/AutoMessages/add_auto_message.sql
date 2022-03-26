DROP FUNCTION IF EXISTS wf_add_auto_message;

CREATE OR REPLACE FUNCTION wf_add_auto_message
(
	vr_application_id	UUID,
	vr_auto_message_id	UUID,
	vr_owner_id			UUID,
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
	
	INSERT INTO wf_auto_messages (
		application_id,
		auto_message_id,
		owner_id,
		body_text,
		audience_type,
		ref_state_id,
		node_id,
		"admin",
		creatorUser_id,
		creation_date,
		deleted
	)
	VALUES (
		vr_application_id,
		vr_auto_message_id,
		vr_owner_id,
		vr_body_text,
		vr_audience_type,
		vr_ref_state_id,
		vr_node_id,
		vr_admin,
		vr_current_user_id,
		vr_now,
		FALSE
	);
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

