DROP FUNCTION IF EXISTS usr_send_friendship_request;

CREATE OR REPLACE FUNCTION usr_send_friendship_request
(
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_receiver_user_id	UUID,
    vr_request_date 	TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF NOT EXISTS (
		SELECT * 
		FROM usr_friends AS f
		WHERE f.application_id = vr_application_id AND (
				(f.sender_user_id = vr_user_id AND f.receiver_user_id = vr_receiver_user_id) OR
				(f.sender_user_id = vr_receiver_user_id AND f.receiver_user_id = vr_user_id)
			)
		LIMIT 1
	) THEN
		INSERT INTO usr_friends (
			application_id,
			sender_user_id,
			receiver_user_id,
			request_date,
			are_friends,
			deleted,
			unique_id
		)
		VALUES (
			vr_application_id,
			vr_user_id,
			vr_receiver_user_id,
			vr_request_date,
			FALSE,
			FALSE,
			gen_random_uuid()
		);
	ELSE
		UPDATE usr_friends AS f
		SET sender_user_id = vr_user_id,
			receiver_user_id = vr_receiver_user_id,
			request_date = vr_request_date,
			acception_date = NULL,
			are_friends = FALSE,
			deleted = FALSE
		WHERE f.application_id = vr_application_id AND (
				(f.sender_user_id = vr_user_id AND f.receiver_user_id = vr_receiver_user_id) OR
				(f.sender_user_id = vr_receiver_user_id AND f.receiver_user_id = vr_user_id)
			);
	END IF;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

