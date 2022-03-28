DROP FUNCTION IF EXISTS wf_add_owner_workflow;

CREATE OR REPLACE FUNCTION wf_add_owner_workflow
(
	vr_application_id	UUID,
	vr_node_type_id		UUID,
	vr_workflow_id		UUID,
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF EXISTS (
		SELECT 1
		FROM wf_workflow_owners AS o
		WHERE o.application_id = vr_application_id AND
			o.node_type_id = vr_node_type_id AND o.workflow_id = vr_workflow_id
		LIMIT 1
	) THEN
		UPDATE wf_workflow_owners AS o
		SET deleted = FALSE,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
		WHERE o.application_id = vr_application_id AND
			o.node_type_id = vr_node_type_id AND o.workflow_id = vr_workflow_id;
	ELSE
		INSERT INTO wf_workflow_owners (
			application_id,
			"id",
			node_type_id,
			workflow_id,
			creator_user_id,
			creation_date,
			deleted
		)
		VALUES (
			vr_application_id,
			gen_random_uuid(),
			vr_node_type_id,
			vr_workflow_id,
			vr_current_user_id,
			vr_now,
			FALSE
		);
	END IF;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

