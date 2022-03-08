DROP FUNCTION IF EXISTS rv_get_fan_ids;

CREATE OR REPLACE FUNCTION rv_get_fan_ids
(
	vr_application_id	UUID,
	vr_liked_id			UUID
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT l.user_id AS "id"
	FROM rv_likes AS l
	WHERE l.application_id =  vr_application_id AND l.liked_id = vr_liked_id;
END;
$$ LANGUAGE plpgsql;

