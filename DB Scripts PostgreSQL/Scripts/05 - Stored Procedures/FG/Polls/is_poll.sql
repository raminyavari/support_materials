DROP FUNCTION IF EXISTS fg_is_poll;

CREATE OR REPLACE FUNCTION fg_is_poll
(
	vr_application_id	UUID,
	vr_ids				guid_table_type[]
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT "p".poll_id AS "id"
	FROM UNNEST(vr_ids) AS rf
		INNER JOIN fg_polls AS "p"
		ON "p".application_id = vr_application_id AND "p".poll_id = rf.value;
END;
$$ LANGUAGE plpgsql;

