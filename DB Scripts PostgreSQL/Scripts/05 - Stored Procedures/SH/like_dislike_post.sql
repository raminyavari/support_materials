DROP FUNCTION IF EXISTS sh_like_dislike_post;

CREATE OR REPLACE FUNCTION sh_like_dislike_post
(
	vr_application_id	UUID,
    vr_share_id			UUID,
    vr_user_id			UUID,
    vr_like		 		BOOLEAN,
    vr_score			FLOAT,
    vr_date		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result 	INTEGER = 0;
BEGIN
	IF EXISTS (
		SELECT * 
		FROM sh_share_likes AS x
		WHERE x.application_id = vr_application_id AND x.share_id = vr_share_id AND x.user_id = vr_user_id
		LIMIT 1
	) THEN
		UPDATE sh_share_likes AS x
		SET "like" = vr_like,
			score = vr_score,
			date = vr_date
		WHERE x.application_id = vr_application_id AND x.share_id = vr_share_id AND x.user_id = vr_user_id;
	ELSE
		INSERT INTO sh_share_likes (
			application_id,
			share_id,
			user_id,
			"like",
			score,
			date
		)
		VALUES (
			vr_application_id,
			vr_share_id,
			vr_user_id,
			vr_like,
			vr_score,
			vr_date
		);
	END IF;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

