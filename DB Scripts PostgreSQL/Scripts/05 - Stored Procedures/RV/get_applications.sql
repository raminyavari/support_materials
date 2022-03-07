DROP FUNCTION IF EXISTS rv_get_applications;

CREATE OR REPLACE FUNCTION rv_get_applications
(
	vr_count		 	INTEGER,
	vr_lower_boundary 	INTEGER
)
RETURNS SETOF rv_application_ret_composite
AS
$$
DECLARE
	vr_ids			UUID[];
	vr_total_count 	INTEGER;
BEGIN
	WITH "data" AS
	(
		SELECT	ROW_NUMBER() OVER (ORDER BY "a".application_id DESC) AS "row_number",
				"a".application_id
		FROM rv_applications AS "a"
	),
	total AS
	(
		SELECT COUNT(d.application_id)::INTEGER AS total_count
		FROM "data" AS d
	)
	SELECT INTO vr_total_count, vr_ids
				(
					SELECT "t".total_count
					FROM total AS "t"
					LIMIT 1
				),
				ARRAY(
					SELECT d.application_id
					FROM "data" AS d
					WHERE d.row_number >= COALESCE(vr_lower_boundary, 0)
					LIMIT COALESCE(vr_count, 100)
				);
	
	RETURN QUERY
	SELECT *
	FROM rv_p_get_applications_by_ids(vr_ids, vr_total_count);
END;
$$ LANGUAGE plpgsql;

