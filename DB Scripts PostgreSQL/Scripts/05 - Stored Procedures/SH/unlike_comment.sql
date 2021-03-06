DROP FUNCTION IF EXISTS sh_unlike_comment;

CREATE OR REPLACE FUNCTION sh_unlike_comment
(
	vr_application_id	UUID,
    vr_comment_id		UUID,
    vr_user_id			UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result 	INTEGER = 0;
BEGIN
	DELETE FROM sh_comment_likes
	WHERE application_id = vr_application_id AND comment_id = vr_comment_id AND user_id = vr_user_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

