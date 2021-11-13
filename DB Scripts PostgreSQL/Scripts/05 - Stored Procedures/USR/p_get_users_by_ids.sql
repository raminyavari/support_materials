DROP FUNCTION IF EXISTS usr_p_get_users_by_ids;

CREATE OR REPLACE FUNCTION usr_p_get_users_by_ids
(
	vr_application_id	UUID,
    vr_user_ids			UUID[],
	vr_total_count		BIGINT DEFAULT 0
)
RETURNS SETOF usr_user_ret_composite
AS
$$
BEGIN
	IF vr_application_id IS NULL THEN
		RETURN QUERY
		SELECT	un.user_id, 
				un.username,
				un.first_name, 
				un.last_name, 
				un.birthdate,
				'' AS about_me,
				'' AS city,
				'' AS organization,
				'' AS department,
				'' AS job_title,
				un.main_phone_id,
				un.main_email_id,
				un.is_approved, 
				un.is_locked_out,
				vr_total_count
		FROM	UNNEST(vr_user_ids) AS rf
				INNER JOIN usr_view_users AS un
				ON un.user_id = rf;
	ELSE
		RETURN QUERY
		SELECT	un.user_id, 
				un.username,
				un.first_name, 
				un.last_name, 
				un.birthdate,
				un.about_me,
				un.city,
				un.organization,
				un.department,
				un.job_title,
				un.main_phone_id,
				un.main_email_id,
				un.is_approved, 
				un.is_locked_out,
				vr_total_count
		FROM	UNNEST(vr_user_ids) AS rf
				INNER JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = rf;
	END IF;
END;
$$ LANGUAGE plpgsql;

