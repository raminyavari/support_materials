DROP FUNCTION IF EXISTS dct_get_owner_files;

CREATE OR REPLACE FUNCTION dct_get_owner_files
(
	vr_application_id	UUID,
    vr_owner_ids		guid_table_type[],
    vr_type				VARCHAR(50)
)
RETURNS SETOF dct_file_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT af.id
		FROM UNNEST(vr_owner_ids) AS ex
			INNER JOIN dct_files AS af
			ON af.application_id = vr_application_id AND 
				af.owner_id = ex.value AND af.deleted = FALSE AND
				(vr_type IS NULL OR af.owner_type = vr_type)
	);
	
	RETURN QUERY
	SELECT *
	FROM dct_p_get_files_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;
