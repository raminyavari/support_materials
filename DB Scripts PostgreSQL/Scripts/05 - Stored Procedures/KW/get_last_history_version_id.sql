DROP FUNCTION IF EXISTS kw_get_last_history_version_id;

CREATE OR REPLACE FUNCTION kw_get_last_history_version_id
(
	vr_application_id	UUID,
    vr_knowledge_id		UUID
)
RETURNS INTEGER
AS
$$
BEGIN
	RETURN kw_fn_get_wf_version_id(vr_application_id, vr_knowledge_id)::INTEGER;
END;
$$ LANGUAGE plpgsql;

