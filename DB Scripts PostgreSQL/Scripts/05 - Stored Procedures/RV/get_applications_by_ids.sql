DROP FUNCTION IF EXISTS rv_get_applications_by_ids;

CREATE OR REPLACE FUNCTION rv_get_applications_by_ids
(
	vr_application_ids	guid_table_type[]
)
RETURNS SETOF rv_application_ret_composite
AS
$$
DECLARE
	vr_ids			UUID[];
	vr_total_count 	INTEGER;
BEGIN
	vr_ids := ARRAY(
		SELECT DISTINCT x.value 
		FROM UNNEST(vr_application_ids) AS x
	);
	
	vr_total_count := COALESCE(ARRAY_LENGTH(vr_ids, 1), 0)::INTEGER;
	
	RETURN QUERY
	SELECT *
	FROM rv_p_get_applications_by_ids(vr_ids, vr_total_count);
END;
$$ LANGUAGE plpgsql;

