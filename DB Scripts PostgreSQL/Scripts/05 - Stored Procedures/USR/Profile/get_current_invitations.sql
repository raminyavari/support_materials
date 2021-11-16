DROP FUNCTION IF EXISTS usr_get_current_invitations;

CREATE OR REPLACE FUNCTION usr_get_current_invitations
(
    vr_user_id	UUID,
	vr_email	VARCHAR(255)
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT app_ids.application_id AS "id"
	FROM (
			SELECT DISTINCT i.application_id
			FROM usr_invitations AS i
			WHERE LOWER(i.email) = LOWER(vr_email)
		) AS app_ids
		LEFT JOIN usr_user_applications AS "a"
		ON "a".application_id = app_ids.application_id AND "a".user_id = vr_user_id
	WHERE "a".user_id IS NULL;
END;
$$ LANGUAGE plpgsql;

