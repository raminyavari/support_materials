DROP FUNCTION IF EXISTS cn_is_service_admin;

CREATE OR REPLACE FUNCTION cn_is_service_admin
(
	vr_application_id	UUID,
	vr_ids				guid_table_type[],
	vr_user_id			UUID
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT i.value AS "id"
	FROM UNNEST(vr_ids) AS i
		LEFT JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = i.value
		INNER JOIN cn_service_admins AS sa
		ON sa.application_id = vr_application_id AND 
			sa.node_type_id = COALESCE(nd.node_type_id, i.value) AND 
			sa.user_id = vr_user_id AND sa.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;
