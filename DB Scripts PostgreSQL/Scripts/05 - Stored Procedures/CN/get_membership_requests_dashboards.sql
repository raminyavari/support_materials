DROP FUNCTION IF EXISTS cn_get_membership_requests_dashboards;

CREATE OR REPLACE FUNCTION cn_get_membership_requests_dashboards
(
	vr_application_id	UUID,
    vr_user_id			UUID
)
RETURNS TABLE (
	node_id				UUID,
	user_id				UUID,
	membership_date		TIMESTAMP,
	is_admin			BOOLEAN,
	status				VARCHAR,
	acception_date		TIMESTAMP,
	"position"			VARCHAR,
	username			VARCHAR,
	first_name			VARCHAR,
	last_name			VARCHAR,
	node_additional_id	VARCHAR,
	node_name			VARCHAR,
	node_type_id		UUID,
	node_type			VARCHAR
)
AS
$$
DECLARE
	vr_node_ids	UUID[];
BEGIN
	vr_node_ids := ARRAY(
		SELECT *
		FROM cn_get_user_managed_node_ids(vr_application_id, vr_user_id)
	);

	RETURN QUERY
    SELECT nm.node_id,
		   nm.user_id,
		   nm.membership_date,
		   nm.is_admin,
		   nm.status,
		   nm.acception_date,
		   nm.position,
		   usr.username,
		   usr.first_name,
		   usr.last_name,
		   vn.node_additional_id,
		   vn.node_name,
		   vn.node_type_id,
		   vn.type_name AS node_type
    FROM UNNEST(vr_node_ids) AS x 
		INNER JOIN cn_node_members AS nm 
		ON nm.application_id = vr_application_id AND nm.node_id = x
		INNER JOIN users_normal AS usr 
		ON usr.application_id = vr_application_id AND usr.user_id = nm.user_id
		INNER JOIN cn_view_nodes_normal AS vn 
		ON vn.application_id = vr_application_id AND vn.node_id = nm.node_id
	WHERE nm.status = 'Pending' AND nm.deleted = FALSE AND 
		usr.is_approved = TRUE AND vn.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;
