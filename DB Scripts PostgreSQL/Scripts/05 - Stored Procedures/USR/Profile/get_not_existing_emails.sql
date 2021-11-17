DROP FUNCTION IF EXISTS usr_get_not_existing_emails;

CREATE OR REPLACE FUNCTION usr_get_not_existing_emails
(
	vr_application_id	UUID,
    vr_emails			string_table_type[]
)
RETURNS SETOF VARCHAR
AS
$$
BEGIN
	IF vr_application_id IS NULL THEN
		RETURN QUERY
		SELECT e.value
		FROM UNNEST(vr_emails) AS e
			LEFT JOIN usr_email_addresses AS "a"
			INNER JOIN usr_view_users AS un
			ON un.user_id = "a".user_id
			ON LOWER("a".email_address) = LOWER(e.value) AND "a".deleted = FALSE
		WHERE "a".email_id IS NULL;
	ELSE
		RETURN QUERY
		SELECT e.value
		FROM UNNEST(vr_emails) AS e
			LEFT JOIN usr_email_addresses AS "a"
			INNER JOIN users_normal AS un
			ON un.application_id = vr_application_id AND un.user_id = "a".user_id
			ON LOWER("a".email_address) = LOWER(e.value) AND "a".deleted = FALSE
		WHERE "a".email_id IS NULL;
	END IF;
END;
$$ LANGUAGE plpgsql;

