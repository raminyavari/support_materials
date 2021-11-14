DROP FUNCTION IF EXISTS usr_advanced_user_search;

CREATE OR REPLACE FUNCTION usr_advanced_user_search
(
	vr_application_id	UUID,
	vr_raw_search_text 	VARCHAR(1000),
	vr_search_text  	VARCHAR(1000),
	vr_node_type_ids 	guid_table_type[],
	vr_node_ids			guid_table_type[],
	vr_members	 		BOOLEAN,
	vr_experts	 		BOOLEAN,
	vr_contributors 	BOOLEAN,
	vr_property_owners 	BOOLEAN,
	vr_resume		 	BOOLEAN,
    vr_lower_boundary	BIGINT,
    vr_count		 	INTEGER
)
RETURNS TABLE (
	user_id					UUID, 
	total_count				INTEGER,
	"rank"					FLOAT,
	is_member_count			INTEGER,
	is_expert_count			INTEGER,
	is_contributor_count	INTEGER,
	has_property_count		INTEGER,
	resume					INTEGER
)
AS
$$
DECLARE
	vr_node_count		INTEGER;
	vr_node_type_count	INTEGER;
BEGIN
	vr_search_text := gfn_verify_string(COALESCE(vr_search_text, ''));
	vr_raw_search_text := gfn_verify_string(COALESCE(vr_raw_search_text, ''));
	vr_node_count := COALESCE(ARRAY_LENGTH(vr_node_ids, 1), 0)::INTEGER;
	
	IF vr_node_count > 0 THEN
		vr_search_text = '';
		vr_node_type_ids := ARRAY[];
	END IF;
	
	vr_node_type_count := COALESCE(ARRAY_LENGTH(vr_node_type_ids, 1), 0)::INTEGER;
	
	RETURN QUERY
	WITH dt_nodes (node_id, "rank") AS 
	(
		SELECT rf.value AS node_id, 1::FLOAT AS "rank"
		FROM UNNEST(vr_node_ids) AS rf
		WHERE vr_node_count > 0
		
		UNION ALL
		
		SELECT	nd.node_id,
				(ROW_NUMBER() OVER (ORDER BY pgroonga_score(nd.tableoid, nd.ctid)::FLOAT DESC, nd.node_id ASC))::FLOAT AS "rank"
		FROM cn_nodes AS nd
		WHERE vr_node_count = 0 AND nd.application_id = vr_application_id AND
			nd.deleted = FALSE AND COALESCE(nd.searchable, TRUE) = TRUE AND 
			(vr_search_text = '' OR nd.name &@~ vr_search_text) AND
			(vr_node_type_count = 0 OR nd.node_type_id IN (SELECT x.value FROM UNNEST(vr_node_type_ids) AS x))
	),
	srch_users (user_id, "rank") AS 
	(
		SELECT	un.user_id,
				(ROW_NUMBER() OVER (ORDER BY srch.rank ASC, un.user_id ASC))::FLOAT AS "rank"
		FROM usr_user_applications AS app
			INNER JOIN usr_profile AS un
			ON un.user_id = app.user_id AND
				(un.username &@~ vr_search_text OR un.first_name &@~ vr_search_text OR
					un.last_name &@~ vr_search_text)
		WHERE vr_node_count = 0 AND vr_search_text <> '' AND app.application_id = @application_id
	), 
	srch_resume (user_id, "rank") AS 
	(
		SELECT x.user_id, SUM(x.rank)::FLOAT
		FROM (
				SELECT	ea.user_id,
						1::FLOAT AS "rank"
				FROM usr_email_addresses AS ea
					INNER JOIN users_normal AS un
					ON un.application_id = vr_application_id AND un.user_id = ea.user_id
				WHERE vr_raw_search_text <> '' AND ea.deleted = FALSE AND 
					LOWER(ea.email_address) ILIKE ('%' + LOWER(vr_raw_search_text) + '%')

				UNION ALL

				SELECT	pn.user_id,
						1::FLOAT AS "rank"
				FROM usr_phone_numbers AS pn
					INNER JOIN users_normal AS un
					ON un.application_id = vr_application_id AND un.user_id = pn.user_id
				WHERE vr_raw_search_text <> '' AND pn.deleted = FALSE AND 
					pn.phone_number ILIKE ('%' + LOWER(vr_raw_search_text) + '%')

				UNION ALL

				SELECT	e.user_id,
						1::FLOAT AS "rank"
				FROM usr_educational_experiences AS e
				WHERE e.application_id = vr_application_id AND
					(e.school &@~ vr_search_text OR e.study_field &@~ vr_search_text)

				UNION ALL

				SELECT	h.user_id,
						1::FLOAT AS "rank"
				FROM usr_honors_and_awards AS h
				WHERE h.application_id = vr_application_id AND
					(h.title &@~ vr_search_text OR h.issuer &@~ vr_search_text OR
						h.occupation &@~ vr_search_text OR h.description &@~ vr_search_text)

				UNION ALL

				SELECT	j.user_id,
						1::FLOAT AS "rank"
				FROM usr_job_experiences AS j
				WHERE j.application_id = vr_application_id AND
					(j.title &@~ vr_search_text OR j.employer &@~ vr_search_text)

				UNION ALL

				SELECT	u.user_id,
						1::FLOAT AS "rank"
				FROM usr_language_names AS l
					INNER JOIN usr_user_languages AS u
					ON u.application_id = vr_application_id AND u.language_id = l.language_id
				WHERE l.application_id = vr_application_id AND l.language_name &@~ vr_search_text
			) AS x
		WHERE vr_node_count = 0 AND vr_search_text <> ''
		GROUP BY x.user_id
	),
	"data" (
		user_id, 
		"rank", 
		is_member_count, 
		is_expert_count, 
		is_contributor_count,
		has_property_count,
		resume
	) AS 
	(
		SELECT	users.user_id,
				(
					SUM(users.rank) + 
					SUM(users.is_member) + 
					SUM(users.is_expert) + 
					SUM(users.is_contributor) + 
					SUM(users.has_property) + 
					SUM(users.resume)
				) AS "rank",
				SUM(users.is_member) AS is_member_count,
				SUM(users.is_expert) AS is_expert_count,
				SUM(users.is_contributor) AS is_contributos_count,
				SUM(users.has_property) AS has_property_count,
				SUM(users.resume) AS resume
		FROM (
				SELECT	u.user_id,
						(2 * u.rank)::FLOAT AS "rank",
						0::INTEGER AS is_member,
						0::INTEGER AS is_expert,
						0::INTEGER AS is_contributor,
						0::INTEGER AS has_property,
						0::INTEGER AS resume
				FROM srch_users AS u

				UNION ALL

				SELECT	"m".user_id,
						nodes.rank,
						1::INTEGER AS is_member,
						0::INTEGER AS is_expert,
						0::INTEGER AS is_contributor,
						0::INTEGER AS has_property,
						0::INTEGER AS resume
				FROM dt_nodes AS nodes 
					INNER JOIN cn_view_node_members AS "m"
					ON "m".application_id = vr_application_id AND 
						"m".node_id = nodes.node_id AND "m".is_pending = FALSE
				WHERE vr_members = TRUE

				UNION ALL

				SELECT	e.user_id,
						nodes.rank,
						0::INTEGER AS is_member,
						1::INTEGER AS is_expert,
						0::INTEGER AS is_contributor,
						0::INTEGER AS has_property,
						0::INTEGER AS resume
				FROM dt_nodes AS nodes 
					INNER JOIN cn_view_experts AS e
					ON e.application_id = vr_application_id AND e.node_id = nodes.node_id
				WHERE vr_experts = TRUE

				UNION ALL

				SELECT	"c".user_id,
						nodes.rank,
						0::INTEGER AS is_member,
						0::INTEGER AS is_expert,
						1::INTEGER AS is_contributor,
						0::INTEGER AS has_property,
						0::INTEGER AS resume
				FROM dt_nodes AS nodes 
					INNER JOIN cn_node_creators AS "c"
					ON "c".application_id = vr_application_id AND 
						"c".node_id = nodes.node_id AND "c".deleted = FALSE
				WHERE vr_contributors = TRUE

				UNION ALL

				SELECT	"c".user_id,
						nodes.seq_no AS "rank",
						0::INTEGER AS is_member,
						0::INTEGER AS is_expert,
						0::INTEGER AS is_contributor,
						1::INTEGER AS has_property,
						0::INTEGER AS resume
				FROM (
						SELECT n.node_id, MAX(n.rank) AS seq_no
						FROM (
								SELECT i.related_node_id AS node_id, nodes.rank
								FROM dt_nodes AS nodes 
									INNER JOIN cn_view_in_related_nodes AS i
									ON i.application_id = vr_application_id AND i.node_id = nodes.node_id

								UNION ALL

								SELECT o.related_node_id AS node_id, nodes.rank
								FROM dt_nodes AS nodes 
									INNER JOIN cn_view_out_related_nodes AS o
									ON o.application_id = vr_application_id AND o.node_id = nodes.node_id
							) AS n
						GROUP BY n.node_id
					) AS nodes
					INNER JOIN cn_node_creators AS "c"
					ON "c".application_id = vr_application_id AND 
						"c".node_id = nodes.node_id AND "c".deleted = FALSE
				WHERE vr_property_owners = TRUE

				UNION ALL

				SELECT	r.user_id,
						1::FLOAT AS "rank",
						0::INTEGER AS is_member,
						0::INTEGER AS is_expert,
						0::INTEGER AS is_contributor,
						0::INTEGER AS has_property,
						r.rank AS resume
				FROM srch_resume AS r
				WHERE vr_resume = TRUE
			) AS users
		GROUP BY users.user_id
	),
	total AS (
		SELECT COUNT(d.user_id) AS total_count
		FROM "data" AS d
	)
	SELECT	x.user_id, 
			"t".total_count::INTEGER,
			x.rank::FLOAT,
			x.is_member_count::INTEGER,
			x.is_expert_count::INTEGER,
			x.is_contributor_count::INTEGER,
			x.has_property_count::INTEGER,
			x.resume::INTEGER
	FROM (
			SELECT	ROW_NUMBER() OVER (ORDER BY u.rank DESC, u.user_id ASC) AS seq,
					u.*
			FROM "data" AS u
				INNER JOIN users_normal AS un
				ON un.application_id = vr_application_id AND 
					un.user_id = u.user_id AND un.is_approved = TRUE
		) AS x
		CROSS JOIN total AS "t"
	WHERE x.seq >= COALESCE(vr_lower_boundary, 0)
	ORDER BY x.seq ASC
	LIMIT COALESCE(vr_count, 20);
END;
$$ LANGUAGE plpgsql;


