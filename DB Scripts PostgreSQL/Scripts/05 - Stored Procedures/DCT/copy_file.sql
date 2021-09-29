DROP FUNCTION IF EXISTS dct_copy_file;

CREATE OR REPLACE FUNCTION dct_copy_file
(
	vr_application_id	UUID,
	vr_owner_id			UUID,
    vr_file_id			UUID,
    vr_owner_type		VARCHAR(50),
    vr_current_user_id	UUID,
    vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF EXISTS(
		SELECT * 
		FROM dct_files AS af
		WHERE af.application_id = vr_application_id AND 
			af.owner_id = vr_owner_id AND (af.id = vr_file_id OR af.file_name_guid = vr_file_id)
		LIMIT 1
	) THEN
		UPDATE dct_files AS af
		SET deleted = FALSE
		WHERE af.application_id = vr_application_id AND 
			af.owner_id = vr_owner_id AND (af.id = vr_file_id OR af.file_name_guid = vr_file_id);
	ELSE
		INSERT INTO dct_files (
			application_id,
			"id",
			owner_id,
			owner_type,
			file_name_guid,
			"extension",
			file_name,
			mime,
			"size",
			creator_user_id,
			creation_date,
			deleted
		)
		SELECT	vr_application_id, 
				gen_random_uuid(), 
				vr_owner_id,
				vr_owner_type,
				af.file_name_guid, 
				af.extension, 
				af.file_name, 
				af.mime, 
				af.size, 
				vr_current_user_id,
				vr_now,
				FALSE
		FROM dct_files AS af
		WHERE af.application_id = vr_application_id AND 
			(af.id = vr_file_id OR af.file_name_guid = vr_file_id)
		LIMIT 1;
	END IF;
		
	GET DIAGNOSTICS vr_result := ROW_COUNT;
		
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
