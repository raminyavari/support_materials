DROP FUNCTION IF EXISTS rv_follow_unfollow;

CREATE OR REPLACE FUNCTION rv_follow_unfollow
(
	vr_application_id	UUID,
	vr_user_id			UUID,
	vr_followed_id		UUID,
	vr_follow			BOOLEAN,
	vr_now			 	TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF COALESCE(vr_follow, FALSE)::BOOLEAN = FALSE THEN
		DELETE FROM rv_followers AS f
		WHERE f.application_id = vr_application_id AND 
			f.followed_id = vr_followed_id AND f.user_id = vr_user_id;
	ELSE
		UPDATE rv_followers AS f
		SET action_date = COALESCE(f.action_date, vr_now)
		WHERE f.application_id = vr_application_id AND 
			f.followed_id = vr_followed_id AND f.user_id = vr_user_id;
			
		GET DIAGNOSTICS vr_result := ROW_COUNT;
			
		IF COALESCE(vr_result, 0) = 0 THEN
			INSERT INTO rv_followers (
				application_id,
				user_id,
				followed_id,
				action_date
			)
			VALUES (
				vr_application_id,
				vr_user_id,
				vr_followed_id,
				vr_now
			);
		END IF;
	END IF;
	
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

