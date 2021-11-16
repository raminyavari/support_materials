DROP FUNCTION IF EXISTS usr_get_approved_user_ids;

CREATE OR REPLACE FUNCTION usr_get_approved_user_ids
(
	vr_application_id	UUID,
    vr_user_ids			guid_table_type[]
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT un.user_id AS "id"
	FROM UNNEST(vr_user_ids) AS u
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = u.value
	WHERE un.is_approved = TRUE;
END;
$$ LANGUAGE plpgsql;

