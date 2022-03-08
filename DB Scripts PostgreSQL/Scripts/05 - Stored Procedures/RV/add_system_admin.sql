DROP FUNCTION IF EXISTS rv_add_system_admin;

CREATE OR REPLACE FUNCTION rv_add_system_admin
(
	vr_application_id	UUID,
	vr_user_id			UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_admin_role_id	UUID;
	vr_result			INTEGER;
BEGIN
	vr_admin_role_id := (
		SELECT r.role_id
		FROM rv_roles AS r
		WHERE r.application_id = vr_application_id AND r.lowered_role_name = 'admins'
		LIMIT 1
	);

	IF vr_admin_role_id IS NULL THEN
		vr_admin_role_id := gen_random_uuid();
	
		INSERT INTO rv_roles (
			application_id,
			role_id,
			role_name,
			lowered_role_name
		)
		VALUES (
			vr_application_id,
			vr_admin_role_id,
			'Admins',
			'admins'
		);
	END IF;
	
	IF EXISTS (
		SELECT 1
		FROM rv_users_in_roles AS ur
		WHERE ur.user_id = vr_user_id AND ur.role_id = vr_admin_role_id
		LIMIT 1
	) THEN
		RETURN 1::INTEGER;
	ELSE
		INSERT INTO rv_users_in_roles (
			user_id, 
			role_id
		)
		VALUES (
			vr_user_id, 
			vr_admin_role_id
		);
		
		GET DIAGNOSTICS vr_result := ROW_COUNT;

		RETURN vr_result;
	END IF;
END;
$$ LANGUAGE plpgsql;

