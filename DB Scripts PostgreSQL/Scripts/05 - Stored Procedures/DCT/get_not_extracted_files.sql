DROP FUNCTION IF EXISTS dct_get_not_extracted_files;

CREATE OR REPLACE FUNCTION dct_get_not_extracted_files
(
	vr_application_id		UUID,
	vr_allowed_extensions	string_table_type[],
	vr_count			 	INTEGER
)
RETURNS SETOF dct_file_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT af.id
		FROM UNNEST(vr_allowed_extensions) AS ex
			INNER JOIN dct_files AS af
			ON ex.value = LOWER(af.extension)
			LEFT JOIN dct_file_contents AS fc
			ON fc.application_id = vr_application_id AND fc.file_id = af.file_name_guid
		WHERE af.application_id = vr_application_id AND af.deleted = FALSE AND fc.file_id IS NULL AND 
			af.owner_type IN ('Node', 'WikiContent', 'FormElement')
		LIMIT COALESCE(vr_count, 20)
	);
	
	RETURN QUERY
	SELECT *
	FROM dct_p_get_files_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;
