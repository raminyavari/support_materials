DROP FUNCTION IF EXISTS qa_get_comment_owner_id;

CREATE OR REPLACE FUNCTION qa_get_comment_owner_id
(
	vr_application_id	UUID,
	vr_comment_id	 	UUID
)
RETURNS UUID
AS
$$
BEGIN
	RETURN (
		SELECT cm.owner_id AS "id"
		FROM qa_comments AS cm
		WHERE cm.application_id = vr_application_id AND cm.comment_id = vr_comment_id
		LIMIT 1
	);
END;
$$ LANGUAGE plpgsql;

