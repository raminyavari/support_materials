DROP FUNCTION IF EXISTS qa_is_comment_owner;

CREATE OR REPLACE FUNCTION qa_is_comment_owner
(
	vr_application_id	UUID,
    vr_comment_id		UUID,
	vr_user_id			UUID
)
RETURNS BOOLEAN
AS
$$
BEGIN
	RETURN COALESCE((
		SELECT TRUE
		FROM qa_comments AS "c"
		WHERE "c".application_id = vr_application_id AND 
			"c".comment_id = vr_comment_id AND "c".sender_user_id = vr_user_id
		LIMIT 1
	), FALSE)::BOOLEAN;
END;
$$ LANGUAGE plpgsql;

