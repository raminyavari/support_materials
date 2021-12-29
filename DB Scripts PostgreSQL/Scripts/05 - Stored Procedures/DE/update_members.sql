DROP FUNCTION IF EXISTS de_update_members;

CREATE OR REPLACE FUNCTION de_update_members
(
	vr_application_id	UUID,
	vr_members			exchange_member_table_type[],
    vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_m_ids 	guid_pair_table_type[];
	vr_result	INTEGER;
BEGIN
	DROP TABLE IF EXISTS vr_mbrs_07223;

	CREATE TEMP TABLE vr_mbrs_07223 (
		node_id 		UUID,
		user_id 		UUID,
		is_admin 		BOOLEAN,
		unique_admin 	BOOLEAN
	);
	
	INSERT INTO vr_mbrs_07223 (node_id, user_id, is_admin, unique_admin)
	SELECT	nd.node_id,
			un.user_id,
			MAX(COALESCE("m".is_admin, FALSE)::INTEGER)::BOOLEAN,
			MAX(COALESCE(s.unique_admin_member, FALSE)::INTEGER)::BOOLEAN
	FROM UNNEST(vr_members) AS "m"
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND 
			("m".node_id IS NULL AND nd.type_additional_id = "m".node_type_additional_id AND
			nd.node_additional_id = "m".node_additional_id) OR
			("m".node_id IS NOT NULL AND nd.node_id = "m".node_id)
		LEFT JOIN cn_services AS s
		ON s.application_id = vr_application_id AND s.node_type_id = nd.node_type_id
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND LOWER(un.username) = LOWER("m".username)
	GROUP BY nd.node_id, un.user_id;
	
	-- Add members
	vr_m_ids := ARRAY(
		SELECT ROW(x.node_id, x.user_id) 
		FROM vr_mbrs_07223 AS x
	);
	
	vr_result := cn_p_add_accepted_members(vr_application_id, vr_m_ids, vr_now);
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1);
		RETURN -1::INTEGER;
	END IF;
	--end of Add members
	
	--Update admins
	UPDATE cn_node_members
	SET is_admin = (
		CASE
			WHEN n_ids.unique_admin = FALSE THEN COALESCE(rf.is_admin, nm.is_admin)::BOOLEAN
			WHEN rf.node_id IS NULL
				THEN (CASE WHEN n_ids.admins_count = 0 THEN nm.is_admin ELSE FALSE END)
			ELSE (CASE WHEN n_ids.admins_count <= 1 THEN rf.is_admin ELSE FALSE END)
		END
	)
	FROM (
			SELECT	x.node_id, 
					MAX(x.unique_admin::INTEGER)::BOOLEAN AS unique_admin, 
					SUM(x.is_admin::INTEGER) AS admins_count
			FROM vr_mbrs_07223 AS x
			GROUP BY x.node_id
		) AS n_ids
		INNER JOIN cn_node_members AS nm
		ON nm.application_id = vr_application_id AND nm.node_id = n_ids.node_id AND nm.deleted = FALSE
		LEFT JOIN vr_mbrs_07223 AS rf
		ON rf.node_id = nm.node_id AND rf.user_id = nm.user_id;
	--end of Update admins
	
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

