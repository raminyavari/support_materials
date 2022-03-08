DROP FUNCTION IF EXISTS rv_get_email_queue_items;

CREATE OR REPLACE FUNCTION rv_get_email_queue_items
(
	vr_application_id	UUID,
	vr_count		 	INTEGER
)
RETURNS TABLE (
	"id"			BIGINT,
	sender_user_id	UUID,
	"action"		VARCHAR,
	email			VARCHAR,
	title			VARCHAR,
	email_body		VARCHAR
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT 	e.id,
			e.sender_user_id,
			e.action,
			e.email,
			e.title,
			e.email_body
	FROM rv_email_queue AS e
	WHERE e.application_id = vr_application_id
	ORDER BY e.id ASC
	LIMIT COALESCE(vr_count, 100);
END;
$$ LANGUAGE plpgsql;

