DROP FUNCTION IF EXISTS dct_arithmetic_delete_files;

CREATE OR REPLACE FUNCTION dct_arithmetic_delete_files
(
	vr_application_id	UUID,
	vr_owner_id			UUID,
    vr_file_ids			guid_table_type[]
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE dct_files
	SET deleted = TRUE
	FROM UNNEST(vr_file_ids) AS ex
		INNER JOIN dct_files AS af
		ON af.application_id = vr_application_id AND af.deleted = FALSE AND
			(vr_owner_id IS NULL OR af.owner_id = vr_owner_id) AND
			(af.id = ex.value OR af.file_name_guid = ex.value);
		
	GET DIAGNOSTICS vr_result := ROW_COUNT;
		
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
