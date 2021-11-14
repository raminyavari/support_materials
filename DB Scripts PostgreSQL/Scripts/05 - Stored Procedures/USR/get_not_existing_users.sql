DROP FUNCTION IF EXISTS usr_get_not_existing_users;

CREATE OR REPLACE FUNCTION usr_get_not_existing_users
(
	vr_application_id	UUID,
	vr_usernames		string_table_type[]
)
RETURNS SETOF VARCHAR
AS
$$
BEGIN
	RETURN QUERY
	SELECT DISTINCT rf.value AS "value"
	FROM UNNEST(vr_usernames) AS rf
		LEFT JOIN users_normal AS un
		ON un.application_id = vr_application_id AND 
			(un.username = rf.value OR un.lowered_username = LOWER(rf.value))
	WHERE un.user_id IS NULL;
END;
$$ LANGUAGE plpgsql;

