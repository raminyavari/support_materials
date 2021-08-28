
DROP FUNCTION IF EXISTS sh_get_post_likes_dislikes_count;

CREATE OR REPLACE FUNCTION sh_get_post_likes_dislikes_count
(
	vr_application_id	UUID,
    vr_share_id			UUID,
    vr_like			 	BOOLEAN
)
RETURNS INTEGER
AS
$$
BEGIN
	RETURN (
		SELECT COUNT(*)
		FROM sh_share_likes
		WHERE application_id = vr_application_id AND share_id = vr_share_id AND "like" = vr_like
	);	
END;
$$ LANGUAGE plpgsql;

