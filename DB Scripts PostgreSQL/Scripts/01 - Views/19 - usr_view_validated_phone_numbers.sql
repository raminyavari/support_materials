DROP VIEW IF EXISTS usr_view_validated_phone_numbers;

CREATE VIEW usr_view_validated_phone_numbers
AS
SELECT	e.number_id,
		e.user_id,
		LOWER(u.lowered_username) AS username,
		e.phone_number
FROM usr_phone_numbers AS e
	INNER JOIN rv_users AS u
	ON u.user_id = e.user_id
WHERE e.deleted = FALSE AND e.validated = TRUE;