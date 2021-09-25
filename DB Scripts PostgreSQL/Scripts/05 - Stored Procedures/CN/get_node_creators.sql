DROP FUNCTION IF EXISTS cn_get_node_creators;

CREATE OR REPLACE FUNCTION cn_get_node_creators
(
	vr_application_id	UUID,
	vr_node_id			UUID,
	vr_full		 		BOOLEAN
)
RETURNS TABLE (
	node_id				UUID,
	user_id				UUID,
	username			VARCHAR,
	first_name			VARCHAR,
	last_name			VARCHAR,
	collaboration_share	FLOAT,
	status				VARCHAR
)
AS
$$
BEGIN
	IF COALESCE(vr_full, FALSE) = FALSE THEN
		SELECT nc.node_id,
			   nc.user_id,
			   NULL::VARCHAR AS username,
			   NULL::VARCHAR AS first_name,
			   NULL::VARCHAR AS last_name,
			   nc.collaboration_share,
			   nc.status::VARCHAR
		FROM cn_node_creators AS nc
		WHERE nc.application_id = vr_application_id AND nc.node_id = vr_node_id AND nc.deleted = FALSE;
	ELSE
		SELECT nc.node_id,
			   nc.user_id,
			   un.username::VARCHAR,
			   un.first_name::VARCHAR,
			   un.last_name::VARCHAR,
			   nc.collaboration_share,
			   nc.status::VARCHAR
		FROM cn_node_creators AS nc
			LEFT JOIN users_normal AS un
			ON un.application_id = vr_application_id AND un.user_id = nc.user_id
		WHERE nc.application_id = vr_application_id AND nc.node_id = vr_node_id AND nc.deleted = FALSE;
	END IF;
END;
$$ LANGUAGE plpgsql;
