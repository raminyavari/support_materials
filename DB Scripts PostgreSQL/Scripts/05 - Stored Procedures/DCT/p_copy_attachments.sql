DROP FUNCTION IF EXISTS dct_p_copy_attachments;

CREATE OR REPLACE FUNCTION dct_p_copy_attachments
(
	vr_application_id	UUID,
	vr_from_owner_id	UUID,
    vr_to_owner_id		UUID,
    vr_to_owner_type	VARCHAR(50),
    vr_current_user_id	UUID,
    vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
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
			vr_to_owner_id,
			vr_to_owner_type,
			af.file_name_guid,
			af.extension,
			af.file_name,
			af.mime,
			af.size,
			vr_current_user_id,
			vr_now,
			af.deleted
	FROM dct_files AS af
	WHERE af.application_id = vr_application_id AND 
		af.owner_id = vr_from_owner_id AND af.deleted = FALSE;
		
	GET DIAGNOSTICS vr_result := ROW_COUNT;
		
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
