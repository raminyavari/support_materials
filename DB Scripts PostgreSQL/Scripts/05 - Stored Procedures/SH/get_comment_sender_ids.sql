DROP FUNCTION IF EXISTS sh_get_comment_sender_ids;

CREATE OR REPLACE FUNCTION sh_get_comment_sender_ids
(
	vr_application_id	UUID,
    vr_post_id			UUID
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT x.sender_user_id AS "id"
	FROM sh_comments AS x
	WHERE x.application_id = vr_application_id AND x.share_id = vr_post_id AND x.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

