DROP VIEW IF EXISTS usr_view_users;

CREATE VIEW usr_view_users
AS
SELECT  u.user_id, 
		u.username, 
		u.lowered_username,
		p.first_name, 
		p.last_name, 
		p.birthdate,
		p.main_phone_id,
		p.main_email_id,
		m.is_approved,
		m.is_locked_out,
		m.create_date AS creation_date
FROM    rv_users AS u
		INNER JOIN usr_profile AS p
		ON p.user_id = u.user_id
		INNER JOIN rv_membership AS m
		ON m.user_id = u.user_id;