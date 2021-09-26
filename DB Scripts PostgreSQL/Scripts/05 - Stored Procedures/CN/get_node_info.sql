DROP FUNCTION IF EXISTS cn_get_node_info;

CREATE OR REPLACE FUNCTION cn_get_node_info
(
	vr_application_id		UUID,
	vr_node_ids				guid_table_type[],
    vr_current_user_id		UUID,
    vr_tags			 		BOOLEAN,
    vr_description	 		BOOLEAN,
    vr_creator		 		BOOLEAN,
    vr_contributors_count 	BOOLEAN,
    vr_likes_count		 	BOOLEAN,
    vr_visits_count	 		BOOLEAN,
    vr_experts_count		BOOLEAN,
    vr_members_count 		BOOLEAN,
    vr_childs_count	 		BOOLEAN,
    vr_related_nodes_count 	BOOLEAN,
    vr_like_status		 	BOOLEAN
)
RETURNS TABLE (
	node_id				UUID,
	node_type_id		UUID,
	tags				VARCHAR,
	description			VARCHAR,
	creator_user_id		UUID,
	creator_username	VARCHAR,
	creator_first_name	VARCHAR,
	creator_last_name	VARCHAR,
	contributors_count	INTEGER,
	likes_count			INTEGER,
	visits_count		INTEGER,
	experts_count		INTEGER,
	members_count		INTEGER,
	childs_count		INTEGER,
	related_nodes_count	INTEGER,
	like_status			BOOLEAN
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT	n.value AS node_id,
			nd.node_type_id,
			CASE WHEN vr_tags = TRUE THEN nd.tags ELSE NULL END AS tags,
			CASE WHEN vr_description = TRUE THEN nd.description ELSE NULL END AS description,
			un.user_id AS creator_user_id,
			un.username AS creator_username,
			un.first_name AS creator_first_name,
			un.last_name AS creator_last_name,
			nc.contributors_count,
			nl.likes_count,
			iv.visits_count,
			ex.experts_count,
			nm.members_count,
			ch.childs_count,
			rl.related_nodes_count,
			CASE WHEN n_likes.node_id IS NULL THEN FALSE ELSE TRUE END::BOOLEAN AS like_status
	FROM UNNEST(vr_node_ids) AS n
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = n.value
		LEFT JOIN users_normal AS un
		ON un.application_id = vr_application_id AND vr_creator = TRUE AND un.user_id = nd.creator_user_id
		LEFT JOIN (
			SELECT nc.node_id, COUNT(nc.user_id) AS contributors_count
			FROM UNNEST(vr_node_ids) AS rf
				INNER JOIN cn_node_creators AS nc
				ON nc.node_id = rf.value
			WHERE nc.application_id = vr_application_id AND nc.deleted = FALSE
			GROUP BY nc.node_id
		) AS nc
		ON vr_contributors_count = TRUE AND nc.node_id = n.value
		LEFT JOIN (
			SELECT nl.node_id, COUNT(nl.user_id) AS likes_count
			FROM UNNEST(vr_node_ids) AS rf
				INNER JOIN cn_node_likes AS nl
				ON nl.node_id = rf.value
			WHERE nl.application_id = vr_application_id AND nl.deleted = FALSE
			GROUP BY nl.node_id
		) AS nl
		ON vr_likes_count = TRUE AND nl.node_id = n.value
		LEFT JOIN (
			SELECT iv.item_id, COUNT(iv.user_id) AS visits_count
			FROM UNNEST(vr_node_ids) AS rf
				INNER JOIN usr_item_visits AS iv
				ON iv.application_id = vr_application_id AND iv.item_id = rf.value
			GROUP BY iv.item_id
		) AS iv
		ON vr_visits_count = TRUE AND iv.item_id = n.value
		LEFT JOIN (
			SELECT ex.node_id, COUNT(ex.user_id) AS experts_count
			FROM UNNEST(vr_node_ids) AS rf
				INNER JOIN cn_view_experts AS ex
				ON ex.application_id = vr_application_id AND ex.node_id = rf.value
			GROUP BY ex.node_id
		) AS ex
		ON vr_experts_count = TRUE AND ex.node_id = n.value
		LEFT JOIN (
			SELECT nm.node_id, COUNT(nm.user_id) AS members_count
			FROM UNNEST(vr_node_ids) AS rf
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id AND nm.node_id = rf.value AND
					nm.is_pending = FALSE
			GROUP BY nm.node_id
		) AS nm
		ON vr_members_count = TRUE AND nm.node_id = n.value
		LEFT JOIN (
			SELECT ch.parent_node_id AS node_id, COUNT(ch.node_id) AS childs_count
			FROM UNNEST(vr_node_ids) AS rf
				INNER JOIN cn_nodes AS ch
				ON ch.parent_node_id = rf.value
			WHERE ch.application_id = vr_application_id AND ch.deleted = FALSE
			GROUP BY ch.parent_node_id
		) AS ch
		ON vr_childs_count = TRUE AND ch.node_id = n.value
		LEFT JOIN (
			SELECT rl.node_id, COUNT(DISTINCT rl.related_node_id) AS related_nodes_count
			FROM (
					SELECT in_r.node_id, in_r.related_node_id, in_r.property_id
					FROM UNNEST(vr_node_ids) AS rf
						INNER JOIN cn_view_in_related_nodes AS in_r
						ON in_r.application_id = vr_application_id AND in_r.node_id = rf.value
					
					UNION
					
					SELECT ou_r.node_id, our.related_node_id, ou_r.property_id
					FROM UNNEST(vr_node_ids) AS rf
						INNER JOIN cn_view_out_related_nodes AS ou_r
						ON ou_r.application_id = vr_application_id AND ou_r.node_id = rf.value
				) AS rl
			GROUP BY rl.node_id
		) AS rl
		ON vr_related_nodes_count = TRUE AND rl.node_id = n.value
		LEFT JOIN cn_node_likes AS n_likes
		ON n_likes.application_id = vr_application_id AND 
			vr_current_user_id IS NOT NULL AND vr_like_status = TRUE AND 
			n_likes.node_id = n.value AND n_likes.user_id = vr_current_user_id AND n_likes.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

