DROP FUNCTION IF EXISTS cn_suggest_node_relations;

CREATE OR REPLACE FUNCTION cn_suggest_node_relations
(
	vr_application_id		UUID,
	vr_user_id				UUID,
	vr_node_type_id			UUID,
	vr_related_node_type_id	UUID,
	vr_count			 	INTEGER,
	vr_now			 		TIMESTAMP
)
RETURNS SETOF cn_node_ret_composite
AS
$$
DECLARE
	vr_node_ids	UUID[];
BEGIN
	vr_node_ids := ARRAY(
		SELECT rf.node_id
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
							INNER JOIN cn_view_nodes_normal AS nd
							ON nd.application_id = vr_application_id AND nd.node_id = ex.node_id
							LEFT JOIN cn_node_creators AS nc
							ON nc.application_id = vr_application_id AND 
								nc.node_id = ex.node_id AND nc.user_id = vr_user_id AND nc.deleted = FALSE
						WHERE ex.application_id = vr_application_id AND ex.user_id = vr_user_id AND 
							(ex.approved = TRUE OR ex.social_approved = TRUE) AND
							(vr_related_node_type_id IS NULL OR nd.node_type_id = vr_related_node_type_id) AND
							nc.node_id IS NULL AND nd.deleted = FALSE AND nd.type_deleted = FALSE
					) AS ex
					FULL OUTER JOIN (
						SELECT rn.node_id, 
							(AVG(
								CASE
									WHEN DATE_PART('DAY', vr_now - kw.creation_date) < 365
										THEN 365 - DATE_PART('DAY', vr_now - kw.creation_date)
									ELSE 0
								END
							) / 365::FLOAT) * COUNT(rn.node_id) AS "rank"
						FROM kw_view_knowledges AS kw
							INNER JOIN cn_view_out_related_nodes AS rn
							ON rn.application_id = vr_application_id AND rn.node_id = kw.knowledge_id
							INNER JOIN cn_view_nodes_normal AS nd
							ON nd.application_id = vr_application_id AND nd.node_id = rn.node_id
						WHERE kw.application_id = vr_application_id AND 
							kw.creator_user_id = vr_user_id AND kw.deleted = FALSE AND 
							(vr_related_node_type_id IS NULL OR nd.node_type_id = vr_related_node_type_id) AND
							nd.deleted = FALSE AND nd.type_deleted = FALSE
						GROUP BY rn.node_id
					) AS r
					ON ex.node_id = r.node_id
			) AS rf
		WHERE rf.rank > 0
		ORDER BY rf.rank DESC
		LIMIT vr_count
	);
	
	IF COALESCE(ARRAY_LENGTH(vr_node_ids, 1), 0) = 0 THEN
		vr_node_ids := ARRAY(
			SELECT nd.node_id
			FROM cn_nodes AS nd
			WHERE nd.application_id = vr_application_id AND deleted = FALSE AND 
				(vr_related_node_type_id IS NULL OR nd.node_type_id = vr_related_node_type_id)
			LIMIT vr_count
		);
	END IF;
	
	RETURN QUERY
	SELECT *
	FROM cn_p_get_nodes_by_ids(vr_application_id, vr_node_ids, NULL, NULL);
END;
$$ LANGUAGE plpgsql;

