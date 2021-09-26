DROP FUNCTION IF EXISTS cn_p_get_users_expertise_domains;

CREATE OR REPLACE FUNCTION cn_p_get_users_expertise_domains
(
	vr_application_id	UUID,
    vr_user_ids			UUID[],
    vr_node_type_id		UUID,
    vr_approved	 		BOOLEAN,
    vr_social_approved 	BOOLEAN,
    vr_all		 		BOOLEAN
)
RETURNS TABLE (
	node_id				UUID,
	node_additional_id	VARCHAR,
	node_name			VARCHAR,
	node_type_id		UUID,
	node_type			VARCHAR,
	expert_user_id		UUID,
	expert_username		VARCHAR,
	expert_first_name	VARCHAR,
	expert_last_name	VARCHAR,
	approved			BOOLEAN,
	social_approved		BOOLEAN,
	referrals_count		INTEGER,
	confirms_percentage	FLOAT
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT ex.node_id,
		   vn.node_additional_id,
		   vn.node_name,
		   vn.node_type_id,
		   vn.type_name AS node_type,
		   ex.user_id AS expert_user_id,
		   un.username AS expert_username,
		   un.first_name AS expert_first_name,
		   un.last_name AS expert_last_name,
		   ex.approved,
		   ex.social_approved,
		   ex.referrals_count::INTEGER,
		   ex.confirms_percentage::FLOAT
	FROM UNNEST(vr_user_ids) AS x
		INNER JOIN cn_experts AS ex
		ON ex.application_id = vr_application_id AND ex.user_id = x
		INNER JOIN cn_view_nodes_normal AS vn
		ON vn.application_id = vr_application_id AND vn.node_id = ex.node_id
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = ex.user_id
	WHERE (vr_node_type_id IS NULL OR vn.node_type_id = vr_node_type_id) AND 
		(
			(vr_all = TRUE AND ex.social_approved IS NOT NULL) OR 
			(vr_approved = TRUE AND ex.approved = TRUE) OR
			(vr_social_approved = TRUE AND ex.social_approved = TRUE)
		) AND
		vn.deleted = FALSE AND un.is_approved = TRUE;
END;
$$ LANGUAGE plpgsql;
