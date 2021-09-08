DROP FUNCTION IF EXISTS sh_get_comment_sender_id;

CREATE OR REPLACE FUNCTION sh_get_comment_sender_id
(
	vr_application_id	UUID,
    vr_comment_id		UUID
)
RETURNS UUID
AS
$$
BEGIN
	RETURN (
		SELECT "c".sender_user_id
		FROM sh_comments AS "c"
		WHERE "c".application_id = vr_application_id AND "c".comment_id = vr_comment_id
		LIMIT 1
	);
END;
$$ LANGUAGE plpgsql;

