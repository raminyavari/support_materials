DROP FUNCTION IF EXISTS wf_get_workflow_tags;

CREATE OR REPLACE FUNCTION wf_get_workflow_tags
(
	vr_application_id	UUID,
    vr_workflow_id		UUID
)
RETURNS TABLE (
	tag_id	UUID,
	tag		VARCHAR
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT 	wfs.tag_id, 
			tg.tag
	FROM wf_workflow_states AS wfs
		INNER JOIN cn_tags AS tg
		ON tg.application_id = vr_application_id AND tg.tag_id = wfs.tag_id
	WHERE wfs.application_id = vr_application_id AND 
		wfs.workflow_id = vr_workflow_id AND wfs.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

