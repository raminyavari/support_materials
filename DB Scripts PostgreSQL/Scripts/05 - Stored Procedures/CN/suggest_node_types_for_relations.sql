DROP FUNCTION IF EXISTS cn_suggest_node_types_for_relations;

CREATE OR REPLACE FUNCTION cn_suggest_node_types_for_relations
(
	vr_application_id	UUID,
	vr_user_id			UUID,
	vr_node_type_id		UUID,
	vr_count		 	INTEGER,
	vr_now		 		TIMESTAMP
)
RETURNS SETOF cn_node_type_ret_composite
AS
$$
DECLARE
	vr_node_type_ids	UUID[];
BEGIN
	vr_node_type_ids := ARRAY(
		SELECT rf.id
		FROM (
				SELECT nd.node_type_id AS "id", SUM("ref".rank) AS "rank"
				FROM (
						SELECT COALESCE(ex.node_id, r.node_id) AS node_id,
							((CASE
								WHEN ex.node_id IS NOT NULL AND r.node_id IS NOT NULL THEN 2
								ELSE 1
							END) * (
								(CASE 
									WHEN (ex.rank IS NULL OR ex.rank = 0) THEN 1 
									ELSE ex.rank 
								END) + 
								COALESCE(r.rank, 0))) AS "rank"
						FROM (
								SELECT ex.node_id,
									((COALESCE(ex.confirms_percentage, 0)::FLOAT / 100::FLOAT) * 
									 COALESCE(ex.referrals_count, 0)::FLOAT) AS "rank"
								FROM cn_experts AS ex
									LEFT JOIN cn_node_creators AS nc
									ON nc.application_id = vr_application_id AND nc.node_id = ex.node_id AND 
										nc.user_id = vr_user_id AND nc.deleted = FALSE
								WHERE ex.application_id = vr_application_id AND ex.user_id = vr_user_id AND 
									(ex.approved = TRUE OR ex.social_approved = TRUE) AND nc.node_id IS NULL
							) AS ex
							FULL OUTER JOIN (
								SELECT rn.node_id, 
									(AVG(
										CASE
											WHEN DATE_PART('DAY', vr_now - kw.creation_date) < 365
												THEN 365 - DATE_PART('DAY', vr_now - kw.creation_date)
											ELSE 0
										END
									)::FLOAT / 365::FLOAT) * COUNT(rn.node_id)::FLOAT AS "rank"
								FROM kw_view_knowledges AS kw
									INNER JOIN cn_view_out_related_nodes AS rn
									ON rn.application_id = vr_application_id AND rn.node_id = kw.knowledge_id
								WHERE kw.application_id = vr_application_id AND 
									kw.creator_user_id = vr_user_id AND kw.deleted = FALSE
								GROUP BY rn.node_id
							) AS r
							ON ex.node_id = r.node_id
					) AS "ref"
					INNER JOIN cn_view_nodes_normal AS nd
					ON nd.application_id = vr_application_id AND nd.node_id = "ref".node_id
				WHERE "ref".rank > 0 AND nd.deleted = FALSE AND nd.type_deleted = FALSE
				GROUP BY nd.node_type_id
			) AS rf
		ORDER BY rf.rank DESC
		LIMIT vr_count
	);
	
	IF COALESCE(ARRAY_LENGTH(vr_node_type_ids, 1), 0) = 0 THEN
		vr_node_type_ids := ARRAY(
			SELECT nt.node_type_id
			FROM cn_node_types AS nt
				LEFT JOIN cn_extensions AS x
				ON x.application_id = vr_application_id AND x.extension = 'Browser'
			WHERE nt.application_id = vr_application_id
			ORDER BY (CASE WHEN x.owner_id IS NULL THEN 0 ELSE 1 END) DESC
			LIMIT 10
		);
	END IF;
	
	RETURN QUERY
	SELECT *
	FROM cn_p_get_node_types_by_ids(vr_application_id, vr_node_type_ids);
END;
$$ LANGUAGE plpgsql;

