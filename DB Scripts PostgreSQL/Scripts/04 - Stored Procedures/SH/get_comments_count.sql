DROP FUNCTION IF EXISTS sh_get_comments_count;

CREATE OR REPLACE FUNCTION sh_get_comments_count
(
	vr_application_id	UUID,
    vr_post_id			UUID,
    vr_sender_user_id	UUID
)
RETURNS INTEGER
AS
$$
BEGIN
	RETURN (
		SELECT COUNT(*)
		FROM sh_comments
		WHERE application_id = vr_application_id AND (vr_post_id IS NULL OR post_id = vr_post_id) AND 
			(vr_sender_user_id IS NULL OR sender_user_id = vr_sender_user_id) AND deleted = FALSE
	);	
END;
$$ LANGUAGE plpgsql;

