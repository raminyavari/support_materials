DROP FUNCTION IF EXISTS dct_get_files_by_ids;

CREATE OR REPLACE FUNCTION dct_get_files_by_ids
(
	vr_application_id	UUID,
    vr_file_ids			guid_table_type[]
)
RETURNS SETOF dct_file_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT x.value
		FROM UNNEST(vr_file_ids) AS x
	);
	
	RETURN QUERY
	SELECT *
	FROM dct_p_get_files_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;
