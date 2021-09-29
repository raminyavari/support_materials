DROP FUNCTION IF EXISTS dct_add_files;

CREATE OR REPLACE FUNCTION dct_add_files
(
	vr_application_id	UUID,
    vr_owner_id			UUID,
    vr_owner_type		VARCHAR(20),
    vr_doc_files		doc_file_info_table_type[],
    vr_current_user_id	UUID,
    vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
BEGIN
	RETURN dct_p_add_files(vr_application_id, vr_owner_id, vr_owner_type, 
						   vr_doc_files, vr_current_user_id, vr_now);
END;
$$ LANGUAGE plpgsql;
