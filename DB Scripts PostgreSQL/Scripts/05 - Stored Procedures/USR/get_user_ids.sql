DROP FUNCTION IF EXISTS usr_get_user_ids;

CREATE OR REPLACE FUNCTION usr_get_user_ids
(
	vr_application_id	UUID,
	vr_usernames		string_table_type[]
)
RETURNS SETOF UUID
AS
$$
BEGIN
	IF vr_application_id IS NULL THEN
		RETURN QUERY
		SELECT un.user_id AS "id"
		FROM UNNEST(vr_usernames) AS rf
			INNER JOIN usr_view_users AS un
			ON un.lowered_username = LOWER(rf.value);
	ELSE
		RETURN QUERY
		SELECT un.user_id AS "id"
		FROM UNNEST(vr_usernames) AS rf
			INNER JOIN users_normal AS un
			ON un.application_id = vr_application_id AND un.lowered_username = LOWER(rf.value);
	END IF;
END;
$$ LANGUAGE plpgsql;

