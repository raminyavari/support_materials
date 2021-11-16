DROP FUNCTION IF EXISTS usr_invite_user;

CREATE OR REPLACE FUNCTION usr_invite_user
(
    vr_application_id	UUID,
	vr_invitation_id	UUID,
	vr_email		 	VARCHAR(255),
    vr_current_user_id	UUID,
    vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	INSERT INTO usr_invitations (
		application_id,
		"id", 
		email, 
		sender_user_id, 
		send_date
	)
	VALUES (
		vr_application_id, 
		vr_invitation_id, 
		LOWER(vr_email), 
		vr_current_user_id, 
		vr_now
	);
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

