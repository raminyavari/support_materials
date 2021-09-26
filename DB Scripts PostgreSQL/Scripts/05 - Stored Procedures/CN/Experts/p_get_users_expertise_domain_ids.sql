DROP FUNCTION IF EXISTS cn_p_get_users_expertise_domain_ids;

CREATE OR REPLACE FUNCTION cn_p_get_users_expertise_domain_ids
(
	vr_application_id	UUID,
    vr_user_ids			UUID[],
    vr_node_type_id		UUID,
    vr_approved	 		BOOLEAN,
    vr_social_approved 	BOOLEAN
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT ex.node_id AS "id"
	FROM UNNEST(vr_user_ids) AS x
		INNER JOIN cn_experts AS ex
		ON ex.application_id = vr_application_id AND ex.user_id = x
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND 
			nd.node_id = ex.node_id AND nd.deleted = FALSE
	WHERE (vr_approved = TRUE AND ex.approved = TRUE) OR 
		(vr_social_approved = TRUE AND ex.social_approved = TRUE);
END;
$$ LANGUAGE plpgsql;
