DROP FUNCTION IF EXISTS usr_get_invitation_id;

CREATE OR REPLACE FUNCTION usr_get_invitation_id
(
    vr_application_id		UUID,
	vr_email		 		VARCHAR(255),
	vr_check_if_not_used	BOOLEAN
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT i.id
	FROM usr_invitations AS i
	WHERE i.application_id = vr_application_id AND i.email = LOWER(vr_email) AND
		(COALESCE(vr_check_if_not_used, FALSE) = FALSE OR i.created_user_id IS NULL);
END;
$$ LANGUAGE plpgsql;

