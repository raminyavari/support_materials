DROP FUNCTION IF EXISTS rv_is_system_admin;

CREATE OR REPLACE FUNCTION rv_is_system_admin
(
	vr_application_id	UUID,
	vr_user_id			UUID
)
RETURNS BOOLEAN
AS
$$
BEGIN
	RETURN gfn_is_system_admin(vr_application_id, vr_user_id);
END;
$$ LANGUAGE plpgsql;

