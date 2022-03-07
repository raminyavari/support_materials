DROP FUNCTION IF EXISTS rv_p_get_applications_by_ids;

CREATE OR REPLACE FUNCTION rv_p_get_applications_by_ids
(
	vr_application_ids	UUID[],
	vr_total_count		INTEGER DEFAULT 0
)
RETURNS SETOF rv_application_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT 	"a".application_id,
			"a".application_name,
			"a".title,
			"a".description,
			"a".creator_user_id,
			vr_total_count AS total_count
	FROM UNNEST(vr_application_ids) AS x
		INNER JOIN rv_applications AS "a"
		ON "a".application_id = x;
END;
$$ LANGUAGE plpgsql;

