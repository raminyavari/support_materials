DROP FUNCTION IF EXISTS sh_get_post_owner_id;

CREATE OR REPLACE FUNCTION sh_get_post_owner_id
(
	vr_application_id			UUID,
    vr_post_id_or_comment_id	UUID
)
RETURNS UUID
AS
$$
BEGIN
	IF NOT EXISTS(
		SELECT share_id
		FROM sh_post_shares
		WHERE application_id = vr_application_id AND share_id = vr_post_id_or_comment_id
		LIMIT 1
	) THEN
		SELECT vr_post_id_or_comment_id = share_id
		FROM sh_comments
		WHERE application_id = vr_application_id AND comment_id = vr_post_id_or_comment_id
		LIMIT 1;
	END IF;
	
	RETURN (
		SELECT owner_id
		FROM sh_post_shares
		WHERE application_id = vr_application_id AND share_id = vr_post_id_or_comment_id
		LIMIT 1
	);
END;
$$ LANGUAGE plpgsql;

