DROP FUNCTION IF EXISTS usr_get_invited_users_count;

CREATE OR REPLACE FUNCTION usr_get_invited_users_count
(
    vr_application_id	UUID,
	vr_user_id			UUID
)
RETURNS INTEGER
AS
$$
BEGIN
	RETURN COALESCE((
		SELECT COUNT(i.email)
		FROM usr_invitations AS i
		WHERE i.application_id = vr_application_id AND 
			(vr_user_id IS NULL OR i.sender_user_id = vr_user_id)
	), 0)::INTEGER;
END;
$$ LANGUAGE plpgsql;

