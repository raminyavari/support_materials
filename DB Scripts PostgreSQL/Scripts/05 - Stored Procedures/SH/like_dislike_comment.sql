DROP FUNCTION IF EXISTS sh_like_dislike_comment;

CREATE OR REPLACE FUNCTION sh_like_dislike_comment
(
	vr_application_id	UUID,
    vr_comment_id		UUID,
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
		FROM sh_comment_likes 
		WHERE application_id = vr_application_id AND comment_id = vr_comment_id AND user_id = vr_user_id
		LIMIT 1
	) THEN
		UPDATE sh_comment_likes
		SET "like" = vr_like,
			score = vr_score,
			date = vr_date
		WHERE application_id = vr_application_id AND comment_id = vr_comment_id AND user_id = vr_user_id;
	ELSE
		INSERT INTO sh_comment_likes (
			application_id,
			comment_id,
			user_id,
			"like",
			score,
			date
		)
		VALUES (
			vr_application_id,
			vr_comment_id,
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

