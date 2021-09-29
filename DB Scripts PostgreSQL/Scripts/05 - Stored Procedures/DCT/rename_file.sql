DROP FUNCTION IF EXISTS dct_rename_file;

CREATE OR REPLACE FUNCTION dct_rename_file
(
	vr_application_id	UUID,
    vr_file_id			UUID,
    vr_name		 		VARCHAR(255)
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE dct_files AS af
	SET file_name = gfn_verify_string(COALESCE(vr_name, 'file'))
	WHERE af.application_id = vr_application_id AND (af.id = vr_file_id OR af.file_name_guid = vr_file_id);
		
	GET DIAGNOSTICS vr_result := ROW_COUNT;
		
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
