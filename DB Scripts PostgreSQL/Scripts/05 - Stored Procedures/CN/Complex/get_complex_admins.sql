DROP FUNCTION IF EXISTS cn_get_complex_admins;

CREATE OR REPLACE FUNCTION cn_get_complex_admins
(
	vr_application_id		UUID,
	vr_list_id_or_node_id	UUID
)
RETURNS SETOF UUID
AS
$$
DECLARE
	vr_is_list	BOOLEAN;
BEGIN
	vr_is_list := COALESCE((
		SELECT TRUE
		FROM cn_lists AS l
		WHERE l.application_id = vr_application_id AND l.list_id = vr_list_id_or_node_id
		LIMIT 1
	), FALSE);
	
	IF vr_is_list = TRUE THEN
		RETURN QUERY
		SELECT DISTINCT l.user_id AS "id"
		FROM cn_view_list_admins AS l
		WHERE l.application_id = vr_application_id AND l.list_id = vr_list_id_or_node_id;
	ELSE
		RETURN QUERY
		SELECT DISTINCT l.user_id AS "id"
		FROM cn_view_list_admins AS l
		WHERE l.application_id = vr_application_id AND l.node_id = vr_list_id_or_node_id;
	END IF;
END;
$$ LANGUAGE plpgsql;

