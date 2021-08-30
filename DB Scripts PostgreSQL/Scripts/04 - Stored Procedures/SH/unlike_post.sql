DROP FUNCTION IF EXISTS sh_unlike_post;

CREATE OR REPLACE FUNCTION sh_unlike_post
(
	vr_application_id	UUID,
    vr_share_id			UUID,
    vr_user_id			UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result 	INTEGER = 0;
BEGIN
	DELETE FROM sh_share_likes
	WHERE application_id = vr_application_id AND share_id = vr_share_id AND user_id = vr_user_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

