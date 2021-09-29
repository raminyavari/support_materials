DROP FUNCTION IF EXISTS dct_p_get_files_by_ids;

CREATE OR REPLACE FUNCTION dct_p_get_files_by_ids
(
	vr_application_id	UUID,
    vr_file_ids			UUID[],
	vr_total_count		INTEGER DEFAULT 0
)
RETURNS SETOF dct_file_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT af.owner_id,
		   af.owner_type,
		   af.file_name_guid AS file_id,
		   af.file_name,
		   af.extension,
		   af.mime,
		   af.size,
		   vr_total_count
	FROM UNNEST(vr_file_ids) AS x
		INNER JOIN dct_files AS af
		ON af.application_id = vr_application_id AND 
			 (af.id = x OR af.file_name_guid = x)
	ORDER BY af.creation_date ASC, af.file_name ASC;
END;
$$ LANGUAGE plpgsql;
