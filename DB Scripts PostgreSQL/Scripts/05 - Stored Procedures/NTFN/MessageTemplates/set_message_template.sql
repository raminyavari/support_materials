DROP FUNCTION IF EXISTS ntfn_set_message_template;

CREATE OR REPLACE FUNCTION ntfn_set_message_template
(
	vr_application_id			UUID,
	vr_template_id				UUID,
	vr_owner_id					UUID,
	vr_body_text		 		VARCHAR(4000),
	vr_audience_type			varchar(20),
	vr_audience_ref_owner_id	UUID,
	vr_audience_node_id			UUID,
	vr_audience_node_admin 		BOOLEAN,
	vr_current_user_id			UUID,
	vr_now	 					TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF EXISTS (
		SELECT 1
		FROM ntfn_message_templates AS mt
		WHERE mt.application_id = vr_application_id AND mt.template_id = vr_template_id
		LIMIT 1
	) THEN
		UPDATE ntfn_message_templates AS mt
		SET	body_text = gfn_verify_string(vr_body_text),
			audience_type = vr_audience_type,
			audience_ref_owner_id = vr_audience_ref_owner_id,
			audience_node_id = vr_audience_node_id,
			audience_node_admin = COALESCE(vr_audience_node_admin, FALSE)::BOOLEAN,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
		WHERE mt.application_id = vr_application_id AND mt.template_id = vr_template_id;
	ELSE
		INSERT INTO ntfn_message_templates (
			application_id,
			template_id,
			owner_id,
			nody_text,
			audience_type,
			audience_ref_owner_id,
			audience_node_id,
			audience_node_admin,
			creator_user_id,
			creation_date,
			deleted
		)
		VALUES(
			vr_application_id,
			vr_template_id,
			vr_owner_id,
			gfn_verify_string(vr_body_text),
			vr_audience_type,
			vr_audience_ref_owner_id,
			vr_audience_node_id,
			COALESCE(vr_audience_node_admin, FALSE)::BOOLEAN,
			vr_current_user_id,
			vr_now,
			FALSE
		);
	END IF;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

