DROP FUNCTION IF EXISTS sh_get_posts_count;

CREATE OR REPLACE FUNCTION sh_get_posts_count
(
	vr_application_id	UUID,
    vr_owner_id			UUID,
    vr_sender_user_id	UUID
)
RETURNS INTEGER
AS
$$
BEGIN
	RETURN (
		SELECT COUNT(*)
		FROM sh_post_shares AS x
		WHERE x.application_id = vr_application_id AND (vr_owner_id IS NULL OR x.owner_id = vr_owner_id) AND 
			(vr_sender_user_id IS NULL OR x.sender_user_id = vr_sender_user_id) AND x.deleted = FALSE
	);	
END;
$$ LANGUAGE plpgsql;

