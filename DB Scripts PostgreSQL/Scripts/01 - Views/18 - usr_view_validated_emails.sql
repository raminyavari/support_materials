DROP VIEW IF EXISTS usr_view_validated_emails;

CREATE VIEW usr_view_validated_emails
AS
SELECT	e.email_id,
		e.user_id,
		LOWER(u.lowered_username) AS username,
		LOWER(e.email_address) AS email
FROM usr_email_addresses AS e
	INNER JOIN rv_users AS u
	ON u.user_id = e.user_id
WHERE e.deleted = FALSE AND e.validated = TRUE;