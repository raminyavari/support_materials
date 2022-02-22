DROP FUNCTION IF EXISTS de_update_authors;

CREATE OR REPLACE FUNCTION de_update_authors
(
	vr_application_id	UUID,
	vr_current_user_id	UUID,
    vr_authors			exchange_author_table_type[],
    vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result_1			INTEGER;
	vr_result_2			INTEGER;
BEGIN
	DROP TABLE IF EXISTS vr_shares_34534;

	CREATE TEMP TABLE vr_shares_34534 (
		node_id 	UUID, 
		user_id 	UUID, 
		percentage 	INTEGER
	);
	
	INSERT INTO vr_shares_34534 (node_id, user_id, percentage)
	SELECT 	nd.node_id, 
			un.user_id, 
			MAX("a".percentage)::INTEGER
	FROM UNNEST(vr_authors) AS "a"
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.type_additional_id = "a".node_type_additional_id AND
			nd.node_additional_id = "a".node_additional_id
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND 
			un.username IS NOT NULL AND LOWER(un.username) = LOWER("a".username)
	WHERE COALESCE("a".node_type_additional_id, '') <> '' AND COALESCE("a".node_additional_id, '') <> '' AND 
		"a".percentage IS NOT NULL AND "a".percentage > 0 AND "a".percentage <= 100
	GROUP BY nd.node_id, un.user_id;
	
	DELETE FROM vr_shares_34534 AS x
	USING (
			SELECT s.node_id, SUM(s.percentage) AS summation
			FROM vr_shares_34534 AS s
			GROUP BY s.node_id
		) AS rf
	WHERE rf.node_id = x.node_id AND rf.summation <> 100;
	
	UPDATE cn_node_creators
	SET deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM (SELECT DISTINCT node_id FROM vr_shares_34534) AS s
		INNER JOIN cn_node_creators AS nc
		ON nc.application_id = vr_application_id AND nc.node_id = s.node_id;
		
	UPDATE cn_node_creators
	SET deleted = FALSE,
		collaborationShare = s.percentage::FLOAT,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM vr_shares_34534 AS s
		INNER JOIN cn_node_creators AS nc
		ON nc.application_id = vr_application_id AND 
			nc.node_id = s.node_id AND nc.user_id = s.user_id;
	
	GET DIAGNOSTICS vr_result_1 := ROW_COUNT;
	
	INSERT INTO cn_node_creators (
		application_id, 
		node_id, 
		user_id, 
		collaboration_share,
		creator_user_id, 
		creation_date, 
		deleted, 
		unique_id
	)
	SELECT	vr_application_id, 
			s.node_id, 
			s.user_id, 
			s.percentage::FLOAT, 
			vr_current_user_id, 
			vr_now, 
			FALSE, 
			gen_random_uuid()
	FROM vr_shares_34534 AS s
		LEFT JOIN cn_node_creators AS nc
		ON nc.application_id = vr_application_id AND 
			nc.node_id = s.node_id AND nc.user_id = s.user_id
	WHERE nc.node_id IS NULL;
	
	GET DIAGNOSTICS vr_result_2 := ROW_COUNT;

	RETURN COALESCE(vr_result_1, 0)::INTEGER + COALESCE(vr_result_2, 0)::INTEGER;
END;
$$ LANGUAGE plpgsql;

