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
		FROM sh_comments AS x
		WHERE x.application_id = vr_application_id AND (vr_post_id IS NULL OR x.post_id = vr_post_id) AND 
			(vr_sender_user_id IS NULL OR x.sender_user_id = vr_sender_user_id) AND x.deleted = FALSE
	);	
END;
$$ LANGUAGE plpgsql;

