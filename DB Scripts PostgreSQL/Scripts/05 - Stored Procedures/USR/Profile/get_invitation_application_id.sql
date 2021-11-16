DROP FUNCTION IF EXISTS usr_get_invitation_application_id;

CREATE OR REPLACE FUNCTION usr_get_invitation_application_id
(
	vr_invitation_id		UUID,
	vr_check_if_not_used	BOOLEAN
)
RETURNS UUID
AS
$$
BEGIN
	RETURN (
		SELECT i.application_id AS "id"
		FROM usr_invitations AS i
		WHERE i.id = vr_invitation_id AND 
			(COALESCE(vr_check_if_not_used, FALSE) = FALSE OR i.created_user_id IS NULL)
		LIMIT 1
	);
END;
$$ LANGUAGE plpgsql;

