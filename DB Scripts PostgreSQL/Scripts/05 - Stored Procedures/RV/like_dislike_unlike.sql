DROP FUNCTION IF EXISTS rv_like_dislike_unlike;

CREATE OR REPLACE FUNCTION rv_like_dislike_unlike
(
	vr_application_id	UUID,
	vr_user_id			UUID,
	vr_liked_id			UUID,
	vr_like			 	BOOLEAN,
	vr_now			 	TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF vr_like IS NULL THEN
		DELETE FROM rv_likes AS l
		WHERE l.application_id = vr_application_id AND 
			l.user_id = vr_user_id AND l.liked_id = vr_liked_id;
	ELSE
		UPDATE rv_likes AS l
		SET "like" = vr_like,
			action_date = COALESCE(l.action_date, vr_now)
		WHERE l.application_id = vr_application_id AND 
			l.user_id = vr_user_id AND l.liked_id = vr_liked_id;
			
		GET DIAGNOSTICS vr_result := ROW_COUNT;
			
		IF COALESCE(vr_result, 0) = 0 THEN
			INSERT INTO rv_likes (
				application_id,
				user_id,
				liked_id,
				"like",
				action_date
			)
			VALUES (
				vr_application_id,
				vr_user_id,
				vr_liked_id,
				vr_like,
				vr_now
			);
		END IF;
	END IF;
	
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

