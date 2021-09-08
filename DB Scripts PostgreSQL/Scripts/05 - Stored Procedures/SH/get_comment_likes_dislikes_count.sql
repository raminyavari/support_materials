DROP FUNCTION IF EXISTS sh_get_comment_likes_dislikes_count;

CREATE OR REPLACE FUNCTION sh_get_comment_likes_dislikes_count
(
	vr_application_id	UUID,
    vr_comment_id		UUID,
    vr_like			 	BOOLEAN
)
RETURNS INTEGER
AS
$$
BEGIN
	RETURN (
		SELECT COUNT(*)
		FROM sh_comment_likes AS x
		WHERE x.application_id = vr_application_id AND x.comment_id = vr_comment_id AND x.like = vr_like
	);	
END;
$$ LANGUAGE plpgsql;

