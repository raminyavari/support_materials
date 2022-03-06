DROP FUNCTION IF EXISTS fg_get_owner_poll_ids;

CREATE OR REPLACE FUNCTION fg_get_owner_poll_ids
(
	vr_application_id		UUID,
	vr_is_copy_of_poll_id	UUID,
	vr_owner_id				UUID
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT "p".poll_id AS "id"
	FROM fg_polls AS "p"
	WHERE "p".application_id = vr_application_id AND 
		"p".is_copy_of_poll_id = vr_is_copy_of_poll_id AND 
		"p".owner_id = vr_owner_id AND "p".deleted = FALSE
	ORDER BY "p".creation_date DESC;
END;
$$ LANGUAGE plpgsql;

