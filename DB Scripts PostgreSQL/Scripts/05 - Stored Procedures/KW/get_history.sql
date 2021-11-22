DROP FUNCTION IF EXISTS kw_get_history;

CREATE OR REPLACE FUNCTION kw_get_history
(
	vr_application_id	UUID,
    vr_knowledge_id		UUID,
    vr_user_id			UUID,
    vr_action			VARCHAR(50),
    vr_wf_version_id 	INTEGER
)
RETURNS SETOF kw_history_ret_composite
AS
$$
DECLARE
	vr_ids	BIGINT[];
BEGIN
	vr_ids := ARRAY(
		SELECT h.id
		FROM kw_history AS h
		WHERE h.application_id = vr_application_id AND h.knowledge_id = vr_knowledge_id AND
			(vr_user_id IS NULL OR h.actor_user_id = vr_user_id) AND
			(vr_action IS NULL OR h.action = vr_action) AND
			(vr_wf_version_id IS NULL OR h.wf_version_id = vr_wf_version_id)
		ORDER BY h.id DESC
	);
	
	RETURN QUERY
	SELECT *
	FROM kw_p_get_history_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;

