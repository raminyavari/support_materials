DROP FUNCTION IF EXISTS usr_get_users_by_username;

CREATE OR REPLACE FUNCTION usr_get_users_by_username
(
	vr_application_id	UUID,
    vr_usernames		string_table_type[]
)
RETURNS SETOF usr_user_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT DISTINCT un.user_id
		FROM UNNEST(vr_usernames) AS rf
			INNER JOIN users_normal AS un
			ON un.application_id = vr_application_id AND LOWER(un.username) = LOWER(rf.value)
	);
	
	RETURN QUERY
	SELECT *
	FROM usr_p_get_users_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;

