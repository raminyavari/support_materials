DROP FUNCTION IF EXISTS cn_get_free_user_ids;

CREATE OR REPLACE FUNCTION cn_get_free_user_ids
(
	vr_application_id	UUID,
	vr_node_type_id		UUID
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT f.user_id AS "id"
	FROM cn_free_users AS f
	WHERE f.application_id = vr_application_id AND 
		f.node_type_id = vr_node_type_id AND f.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;
