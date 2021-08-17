DROP VIEW IF EXISTS users_normal;

CREATE VIEW users_normal
AS
SELECT  app.application_id,
		u.user_id, 
		u.username, 
		u.lowered_username,
		p.first_name, 
		p.last_name, 
		p.birthdate,
		p.about_me,
		p.city,
		app.organization,
		app.department,
		app.job_title,
		app.employment_type,
		p.main_phone_id,
		p.main_email_id,
		m.is_approved,
		m.is_locked_out,
		m.create_date AS creation_date,
		p.index_last_update_date,
		u.last_activity_date
FROM    rv_users AS u
		INNER JOIN usr_profile AS p
		ON p.user_id = u.user_id
		INNER JOIN rv_membership AS m
		ON m.user_id = u.user_id
		INNER JOIN usr_user_applications AS app
		ON app.user_id = u.user_id;