DROP FUNCTION IF EXISTS cn_fn_get_wf_version_id;

CREATE OR REPLACE FUNCTION cn_fn_get_wf_version_id
(
	vr_application_id	UUID,
	vr_knowledge_id		UUID
)
RETURNS INTEGER
AS
$$
BEGIN
	RETURN COALESCE((
		SELECT MAX(h.wf_version_id)
		FROM kw_history AS h
		WHERE h.application_id = vr_application_id AND h.knowledge_id = vr_knowledge_id
		LIMIT 1
	), 1)::INTEGER;
END;
$$ LANGUAGE PLPGSQL;