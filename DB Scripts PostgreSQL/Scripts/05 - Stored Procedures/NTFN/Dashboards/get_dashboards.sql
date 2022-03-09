DROP FUNCTION IF EXISTS ntfn_get_dashboards;

CREATE OR REPLACE FUNCTION ntfn_get_dashboards
(
	vr_application_id		UUID,
	vr_user_id				UUID,
	vr_node_type_id			UUID,
	vr_node_id				UUID,
	vr_node_additional_id	VARCHAR(50),
	vr_type					VARCHAR(50),
	vr_subtype		 		VARCHAR(500),
	vr_done_state			BOOLEAN,
	vr_date_from		 	TIMESTAMP,
	vr_date_to			 	TIMESTAMP,
	vr_search_text		 	VARCHAR(500),
	vr_get_distinct_items 	BOOLEAN,
	vr_in_workflow_state 	BOOLEAN,
	vr_lower_boundary	 	INTEGER,
	vr_count			 	INTEGER
)
RETURNS REFCURSOR
AS
$$
DECLARE
	vr_cursor	REFCURSOR;
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
		"info" 						VARCHAR(1000),
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
		"info",
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
			d.info,
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


	IF COALESCE(vr_search_text, '') <> '' THEN
		IF vr_type = 'Wiki' OR vr_type = 'WorkFlow' OR vr_type = 'Knowledge' OR vr_type = 'MembershipRequest' THEN
			DELETE FROM results_73452 AS rs
			USING (
				SELECT r.id
				FROM results_73452 AS r
					LEFT JOIN cn_nodes AS nd
					ON nd.node_id = r.node_id AND nd.name &@~ vr_search_text
				WHERE nd.node_id IS NULL
			) AS x
			WHERE rs.id = x.id;
		ELSEIF vr_type = 'Question' THEN
			DELETE FROM results_73452 AS rs
			USING (
				SELECT r.id
				FROM results_73452 AS r
					LEFT JOIN qa_questions AS q
					ON q.question_id = r.node_id AND q.title &@~ vr_search_text
				WHERE q.node_id IS NULL
			) AS x
			WHERE rs.id = x.id;
		END IF;
	END IF;
	

	IF COALESCE(vr_get_distinct_items, FALSE) = TRUE THEN
		IF vr_in_workflow_state IS NOT NULL THEN
			UPDATE results_73452
			SET in_workflow = TRUE
			FROM results_73452 AS r
				INNER JOIN ntfn_dashboards AS d
				ON d.application_id = vr_application_id AND 
					d.node_id = r.node_id AND d.type = r.type AND 
					d.done = FALSE AND d.deleted = FALSE AND COALESCE(d.removable, FALSE) = FALSE
			WHERE r.node_id IS NOT NULL AND r.type IN ('WorkFlow', 'Knowledge');
		END IF;
		
		OPEN vr_cursor FOR
		WITH "data" AS
		(
			SELECT	ROW_NUMBER() OVER (ORDER BY rf.send_date DESC, rf.node_id DESC) AS "row_number",
					rf.node_id
			FROM (
					SELECT	r.node_id, 
							MAX(r.send_date) AS send_date, 
							MAX(r.in_workflow::INTEGER) AS in_workflow
					FROM results_73452 AS r
					WHERE r.node_id IS NOT NULL AND r.done = TRUE
					GROUP BY r.node_id
				) AS rf
			WHERE vr_in_workflow_state IS NULL OR
				(vr_in_workflow_state = FALSE AND COALESCE(rf.in_workflow, FALSE) = FALSE) OR
				(vr_in_workflow_state = TRUE AND COALESCE(rf.in_workflow, FALSE) = TRUE)
		),
		total AS
		(
			SELECT COUNT(d.node_id)::INTEGER AS total_count
			FROM "data" AS d
		)
		SELECT 	x.node_id AS "id",
				"t".total_count
		FROM "data" AS x
			CROSS JOIN total AS "t"
		WHERE x.row_number >= COALESCE(vr_lower_boundary, 0)
		ORDER BY x.row_number ASC
		LIMIT COALESCE(vr_count, 50);
		RETURN vr_cursor;
	ELSE
		OPEN vr_cursor FOR
		WITH "data" AS
		(
			SELECT	ROW_NUMBER() OVER (ORDER BY 
									   r.seen_order ASC, 
									   r.send_date DESC, 
									   r.id DESC) AS "row_number",
					r.*
			FROM results_73452 AS r
			WHERE (vr_done_state IS NULL OR COALESCE(r.done, FALSE) = vr_done_state) AND
				(vr_date_from IS NULL OR r.send_date >= vr_date_from) AND
				(vr_date_to IS NULL OR r.send_date < vr_date_to) AND
				(vr_subtype IS NULL OR r.subtype = vr_subtype OR r.wf_state = vr_subtype)
		),
		total AS
		(
			SELECT COUNT(d.id)::INTEGER AS total_count
			FROM "data" AS d
		)
		SELECT 	x.*,
				"t".total_count
		FROM "data" AS x
			CROSS JOIN total AS "t"
		WHERE x.row_number >= COALESCE(vr_lower_boundary, 0)
		ORDER BY x.row_number ASC
		LIMIT COALESCE(vr_count, 50);
		RETURN vr_cursor;
	END IF;
END;
$$ LANGUAGE plpgsql;

