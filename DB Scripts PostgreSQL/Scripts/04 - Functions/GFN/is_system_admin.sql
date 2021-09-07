DROP FUNCTION IF EXISTS gfn_is_system_admin;

CREATE OR REPLACE FUNCTION gfn_is_system_admin
(
	vr_application_id	UUID,
	vr_user_id			UUID
)
RETURNS UUID
AS
$$
BEGIN
	RETURN COALESCE((
		SELECT TRUE
		FROM rv_users_in_roles AS u
			INNER JOIN rv_roles AS r
			ON r.role_id = u.role_id
		WHERE (vr_application_id IS NULL OR r.application_id = vr_application_id) AND 
			u.user_id = vr_user_id AND r.lowered_role_name = N'admins'
		LIMIT 1
	), FALSE)::BOOLEAN;
END;
$$ LANGUAGE PLPGSQL;