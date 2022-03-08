DROP FUNCTION IF EXISTS rv_get_file_extension;

CREATE OR REPLACE FUNCTION rv_get_file_extension
(
	vr_application_id	UUID,
	vr_file_id			UUID
)
RETURNS VARCHAR
AS
$$
BEGIN
	RETURN (
		SELECT f.extension AS "value"
		FROM dct_files AS f
		WHERE f.application_id = vr_application_id AND 
			(f.id = vr_file_id OR f.file_name_guid = vr_file_id)
		LIMIT 1
	);
END;
$$ LANGUAGE plpgsql;

