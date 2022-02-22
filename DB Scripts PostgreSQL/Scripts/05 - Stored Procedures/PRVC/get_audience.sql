DROP FUNCTION IF EXISTS prvc_get_audience;

CREATE OR REPLACE FUNCTION prvc_get_audience
(
	vr_application_id	UUID,
	vr_object_ids		guid_table_type[]
)
RETURNS TABLE (
	object_id		UUID, 
	role_id			UUID, 
	permission_type	VARCHAR, 
	allow			BOOLEAN, 
	expiration_date	TIMESTAMP,
	"name"			VARCHAR,
	"type"			VARCHAR,
	node_type		VARCHAR,
	additional_id	VARCHAR
)
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT DISTINCT x.value
		FROM UNNEST(vr_object_ids) AS x
	);
	
	RETURN QUERY
	WITH audience AS 
	(
		SELECT 	rf.object_id, 
				rf.role_id, 
				rf.permission_type, 
				rf.allow, 
				rf.expiration_date
		FROM UNNEST(vr_ids) AS ids
			INNER JOIN prvc_audience AS rf
			ON rf.application_id = vr_application_id AND 
				rf.object_id = ids.value AND rf.deleted = FALSE
	)
	SELECT	external_ids.*,
			RTRIM(LTRIM((COALESCE(un.first_name, '') + ' ' + COALESCE(un.last_name, '')))) AS "name",
			'User' AS "type",
			NULL::VARCHAR AS node_type,
			un.username AS additional_id
	FROM audience AS external_ids
		INNER JOIN users_normal AS un
		ON un.user_id = external_ids.role_id
	WHERE un.application_id = vr_application_id AND un.is_approved = TRUE
	
	UNION ALL
	
	SELECT	external_ids.*,
			nd.node_name AS "name",
			'Node' AS "type",
			nd.type_name AS node_type,
			nd.node_additional_id AS additional_id
	FROM audience AS external_ids
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.node_id = external_ids.role_id
	WHERE nd.application_id = vr_application_id AND nd.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

