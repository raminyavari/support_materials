DROP FUNCTION IF EXISTS qa_remove_workflow_admin;

CREATE OR REPLACE FUNCTION qa_remove_workflow_admin
(
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_workflow_id 		UUID,
    vr_current_user_id	UUID,
    vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE qa_admins AS ad
	SET deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE ad.application_id = vr_application_id AND ad.user_id = vr_user_id AND
		((ad.workflow_id IS NULL AND vr_workflow_id IS NULL) OR (ad.workflow_id = vr_workflow_id));

	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

