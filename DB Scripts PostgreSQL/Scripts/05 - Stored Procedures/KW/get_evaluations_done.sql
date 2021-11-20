DROP FUNCTION IF EXISTS kw_get_evaluations_done;

CREATE OR REPLACE FUNCTION kw_get_evaluations_done
(
	vr_application_id	UUID,
    vr_knowledge_id		UUID,
	vr_wf_version_id	INTEGER
)
RETURNS TABLE (
	user_id			UUID,
	username		VARCHAR,
	first_name		VARCHAR,
	last_name		VARCHAR,
	score			FLOAT,
	evaluation_date	TIMESTAMP,
	wf_version_id	INTEGER
)
AS
$$
DECLARE
	vr_date_from		TIMESTAMP;
	vr_last_version_id	INTEGER;
BEGIN
	vr_date_from := (
		SELECT MIN(h.action_date)
		FROM kw_history AS h
		WHERE h.application_id = vr_application_id AND
			h.knowledge_id = vr_knowledge_id AND h.action = 'SendToAdmin'
	);
	
	vr_last_version_id := kw_fn_get_wf_version_id(vr_application_id, vr_knowledge_id);
	
	SELECT *
	FROM (
			SELECT	rf.user_id,
					un.username,
					un.first_name,
					un.last_name,
					rf.score,
					rf.evaluation_date,
					vr_last_version_id AS wf_version_id
			FROM (
					SELECT 	"a".user_id, 
							SUM(COALESCE(COALESCE("a".admin_score, "a".score), 0))::FLOAT / 
								COALESCE(COUNT("a".user_id), 1)::FLOAT AS score,
						MAX("a".evaluation_date) AS evaluation_date
					FROM kw_question_answers AS "a"
					WHERE "a".application_id = vr_application_id AND 
						"a".knowledge_id = vr_knowledge_id AND "a".deleted = FALSE AND
						(vr_date_from IS NULL OR "a".evaluation_date > vr_date_from)
					GROUP BY "a".user_id
				) AS rf
				LEFT JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = rf.user_id
			WHERE vr_wf_version_id IS NULL OR vr_last_version_id = vr_wf_version_id
	
			UNION ALL
	
			SELECT	rf.user_id,
					un.username,
					un.first_name,
					un.last_name,
					rf.score,
					rf.evaluation_date,
					rf.wf_version_id
			FROM (
					SELECT 	"a".user_id, 
							SUM(COALESCE(COALESCE("a".admin_score, "a".score), 0))::FLOAT / 
								COALESCE(COUNT("a".user_id), 1)::FLOAT AS score,
							MAX("a".evaluation_date) AS evaluation_date, 
							"a".wf_version_id
					FROM kw_question_answers_history AS "a"
					WHERE "a".application_id = vr_application_id AND 
						"a".knowledge_id = vr_knowledge_id AND "a".deleted = FALSE AND
						(vr_date_from IS NULL OR "a".evaluation_date > vr_date_from) AND
						(vr_wf_version_id IS NULL OR "a".wf_version_id = vr_wf_version_id)
					GROUP BY "a".user_id, "a".wf_version_id
				) AS rf
				LEFT JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = rf.user_id
		) AS x
	ORDER BY x.wf_version_id DESC, x.evaluation_date DESC;
END;
$$ LANGUAGE plpgsql;

