DROP FUNCTION IF EXISTS ntfn_get_dashboards_count;

CREATE OR REPLACE FUNCTION ntfn_get_dashboards_count
(
	vr_application_id		UUID,
	vr_user_id				UUID,
	vr_node_type_id			UUID,
	vr_node_id				UUID,
	vr_node_additional_id	VARCHAR(50),
	vr_type					VARCHAR(50)
)
RETURNS TABLE (
	"type"						VARCHAR, 
	subtype						VARCHAR, 
	node_type_id				UUID, 
	node_type					VARCHAR,
	date_of_effect				TIMESTAMP,
	not_seen					INTEGER,
	to_be_done					INTEGER,
	done						INTEGER,
	done_and_in_workflow		INTEGER,
	done_and_not_in_workflow	INTEGER
)
AS
$$
BEGIN
	IF vr_node_id IS NOT NULL THEN 
		vr_node_type_id := NULL;
	END IF;
	
	IF vr_node_id IS NOT NULL OR vr_node_additional_id = '' THEN
		vr_node_additional_id = NULL;
	END IF;

	DROP TABLE IF EXISTS results_73452;
	
	CREATE TEMP TABLE results_73452 (
		seen_order 					INTEGER, 
		"id" 						BIGINT, 
		user_id 					UUID, 
		node_id 					UUID, 
		node_additional_id 			VARCHAR(50), 
		node_name 					VARCHAR(255), 
		node_type_id 				UUID, 
		node_type 					VARCHAR(255), 
		"type" 						VARCHAR(50), 
		subtype 					VARCHAR(500), 
		wf_state 					VARCHAR(1000), 
		removable 					BOOLEAN, 
		sender_user_id 				UUID, 
		send_date 					TIMESTAMP, 
		expiration_date 			TIMESTAMP, 
		seen 						BOOLEAN, 
		view_date 					TIMESTAMP, 
		done 						BOOLEAN, 
		action_date 				TIMESTAMP, 
		in_workflow 				BOOLEAN, 
		done_and_in_workflow 		INTEGER, 
		done_and_not_in_workflow	INTEGER,
		PRIMARY KEY (nodeid, "type", "id")
	);

	INSERT INTO results_73452 (
		seen_order, 
		"id", 
		user_id, 
		node_id, 
		node_additional_id, 
		node_name, 
		node_type_id, 
		node_type, 
		"type", 
		subtype, 
		wf_state, 
		removable, 
		sender_user_id, 
		send_date, 
		expiration_date, 
		seen, 
		view_date, 
		done, 
		action_date
	)
	SELECT 	CASE WHEN d.seen = FALSE THEN 0 ELSE 1 END::INTEGER AS seen_order,
			d.id, 
			d.user_id, 
			d.node_id, 
			nd.node_additional_id, 
			COALESCE(nd.node_name, q.title) AS node_name,
			nd.node_type_id,
			nd.type_name AS node_type, 
			d.type, 
			d.subtype, 
			nd.wf_state, 
			d.removable,
			d.sender_user_id, 
			d.send_date, 
			d.expiration_date,
			d.seen, 
			d.view_date, 
			d.done, 
			d.action_date
	FROM ntfn_dashboards AS d
		LEFT JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND 
			nd.node_id = d.node_id AND nd.deleted = FALSE
		LEFT JOIN qa_questions AS q
		ON q.application_id = vr_application_id AND 
			q.question_id = d.node_id AND q.deleted = FALSE
	WHERE d.application_id = vr_application_id AND d.deleted = FALSE AND
		(nd.node_id IS NOT NULL OR q.question_id IS NOT NULL) AND
		(vr_user_id IS NULL OR d.user_id = vr_user_id) AND 
		(vr_node_id IS NULL OR d.node_id = vr_node_id) AND
		(vr_node_type_id IS NULL OR nd.node_type_id = vr_node_type_id) AND
		(vr_node_additional_id IS NULL OR nd.node_additional_id = vr_node_additional_id) AND
		(vr_type IS NULL OR d.type = vr_type);
			
			
	-- Remove Invalid WorkFlow Items
	IF COALESCE(vr_type, '') = '' OR vr_type = 'WorkFlow' THEN
		DELETE FROM results_73452 AS rs
		USING (
			SELECT r.id
			FROM results_73452 AS r
				LEFT JOIN wf_workflow_owners AS wo
				ON wo.application_id = vr_application_id AND wo.node_type_id = r.node_type_id AND wo.deleted = FALSE
				LEFT JOIN cn_services AS s
				ON s.application_id = vr_application_id AND s.node_type_id = r.node_type_id
			WHERE r.node_type_id IS NOT NULL AND r.type = 'WorkFlow' AND 
				(wo.workflow_id IS NULL OR s.is_knowledge = TRUE)
		) AS x
		WHERE rs.id = x.id;
	END IF;
	-- end of Remove Invalid WorkFlow Items


	-- Remove Invalid Knowledge Items
	IF COALESCE(vr_type, '') = '' OR vr_type = 'Knowledge' THEN
		DELETE FROM results_73452 AS rs
		USING (
			SELECT r.id
			FROM results_73452 AS r
				LEFT JOIN cn_services AS s
				ON s.application_id = vr_application_id AND s.node_type_id = r.node_type_id
			WHERE r.node_type_id IS NOT NULL AND 
				r.type = 'Knowledge' AND COALESCE(s.is_knowledge, FALSE) = FALSE
		) AS x
		WHERE rs.id = x.id;
	END IF;
	-- end of Remove Invalid Knowledge Items


	-- Remove Invalid Wiki Items
	IF COALESCE(vr_type, '') = '' OR vr_type = 'Wiki' THEN
		DELETE FROM results_73452 AS rs
		USING (
			SELECT r.id
			FROM results_73452 AS r
				LEFT JOIN cn_extensions AS s
				ON s.application_id = vr_application_id AND s.owner_id = r.node_type_id AND 
					s.extension = 'Wiki' AND s.deleted = FALSE
			WHERE r.node_type_id IS NOT NULL AND r.type = 'Wiki' AND s.owner_id IS NULL
		) AS x
		WHERE rs.id = x.id;
	END IF;
	-- end of Remove Invalid Wiki Items


	UPDATE results_73452
	SET in_workflow = TRUE
	FROM results_73452 AS r
		INNER JOIN (
			SELECT r.node_id, r.type
			FROM results_73452 AS r
				INNER JOIN ntfn_dashboards AS d
				ON d.application_id = vr_application_id AND r.node_id IS NOT NULL AND 
					r.type IN ('WorkFlow', 'Knowledge') AND d.node_id = r.node_id AND 
					d.type = r.type AND d.done = FALSE AND d.deleted = FALSE AND COALESCE(d.removable, FALSE) = FALSE
			GROUP BY r.node_id, r.type
		) AS x
		ON x.node_id = r.node_id AND x.type = r.type;


	UPDATE results_73452
	SET done_and_in_workflow = "a".done_and_in_workflow,
		done_and_not_in_workflow = "a".done_and_not_in_workflow
	FROM results_73452 AS x
		INNER JOIN (
			SELECT u.user_id, u.type, u.node_type_id,
				COUNT(DISTINCT (CASE WHEN u.done_and_in_workflow = TRUE THEN u.node_id ELSE NULL END)) AS done_and_in_workflow,
				COUNT(DISTINCT (CASE WHEN u.done_and_not_in_workflow = TRUE THEN u.node_id ELSE NULL END)) AS done_and_not_in_workflow
			FROM (
					SELECT r.user_id, r.type, r.node_id, r.node_type_id, 
						CASE 
							WHEN MAX(COALESCE(r.done, FALSE)::INTEGER) = 1 AND
								COALESCE(MAX(r.in_workflow::INTEGER), 0) > 0 THEN 1
							ELSE 0
						END::INTEGER AS done_and_in_workflow,
						CASE 
							WHEN MAX(COALESCE(r.done, FALSE)::INTEGER) = 1 AND
								COALESCE(MAX(r.in_workflow::INTEGER), 0) = 0 THEN 1
							ELSE 0
						END::INTEGER AS done_and_not_in_workflow
					FROM results_73452 AS r
					GROUP BY r.user_id, r.type, r.node_id, r.node_type_id
				) AS u
			GROUP BY u.user_id, u.type, u.node_type_id
		) AS "a"
		ON "a".user_id = x.user_id AND "a".type = x.type AND 
			(("a".node_type_id IS NULL AND x.node_type_id IS NULL) OR ("a".node_type_id = x.node_type_id));

	UPDATE results_73452 AS r
	SET subtype = wf_state
	WHERE r.type = 'WorkFlow';

	RETURN QUERY
	SELECT	r.type, 
			r.subtype, 
			r.node_type_id, 
			MAX(r.node_type) AS node_type,
			COALESCE(MAX(CASE WHEN COALESCE(r.done, FALSE) = FALSE THEN r.send_date ELSE NULL END),
				MAX(CASE WHEN r.done = TRUE THEN r.send_date ELSE NULL END)) AS date_of_effect, -- تاریخ موثر
			COUNT(CASE WHEN COALESCE(r.done, FALSE) = FALSE AND COALESCE(r.seen, FALSE) = FALSE THEN r.node_id ELSE NULL END) AS not_seen, -- منتظر اقدام و دیده نشده
			COUNT(CASE WHEN COALESCE(r.done, FALSE) = FALSE THEN r.node_id ELSE NULL END) AS to_be_done, -- منتظر اقدام
			COUNT(CASE WHEN r.done = TRUE THEN r.node_id ELSE NULL END) AS done, -- تعداد کل اقدامات انجام شده
			MAX(r.done_and_in_workflow) AS done_and_in_workflow, -- اقدام شده و از جریان خارج شده
			MAX(r.done_and_not_in_workflow) AS done_and_not_in_workflow -- اقدام شده و همچنان در جریان
	FROM results_73452 AS r
	GROUP BY r.user_id, r.type, r.subtype, r.node_type_id
	ORDER BY r.date_of_effect DESC;
END;
$$ LANGUAGE plpgsql;

