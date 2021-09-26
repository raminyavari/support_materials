DROP FUNCTION IF EXISTS cn_get_expertise_suggestions;

CREATE OR REPLACE FUNCTION cn_get_expertise_suggestions
(
	vr_application_id	UUID,
	vr_user_id			UUID,
	vr_count		 	INTEGER,
	vr_lower_boundary	INTEGER
)
RETURNS TABLE (
	node_id				UUID,
	node_name			VARCHAR,
	node_type			VARCHAR,
	expert_user_id		UUID,
	expert_username		VARCHAR,
	expert_first_name	VARCHAR,
	expert_last_name	VARCHAR
)
AS
$$
BEGIN
	IF vr_count IS NULL THEN
		vr_count := 10;
	END IF;
	
	RETURN QUERY
	SELECT	nd.node_id,
			nd.node_name,
			nd.type_name AS node_type,
			rf.user_id AS expert_user_id,
			un.username AS expert_username,
			un.first_name AS expert_first_name,
			un.last_name AS expert_last_name
	FROM
		(
			SELECT 	ROW_NUMBER() OVER(ORDER BY er.referrals_count) AS "id",
				   	er.referrer_user_id, 
					er.user_id, 
					er.node_id
			FROM cn_view_expertise_referrals AS er
			WHERE er.application_id = vr_application_id AND er.referrer_user_id = vr_user_id
		) AS rf
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = rf.node_id
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = rf.user_id
	WHERE vr_lower_boundary IS NULL OR rf.id > vr_lower_boundary
	LIMIT vr_count;
END;
$$ LANGUAGE plpgsql;
