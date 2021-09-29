DROP FUNCTION IF EXISTS dct_p_add_files;

CREATE OR REPLACE FUNCTION dct_p_add_files
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
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE dct_files
	SET deleted = FALSE
	FROM UNNEST(vr_doc_files) AS f
		INNER JOIN dct_files AS d
		ON d.application_id = vr_application_id AND (d.id = f.file_id OR d.file_name_guid = f.file_id) AND
			((f.owner_id IS NULL AND d.owner_id IS NULL) OR (d.owner_id = COALESCE(vr_owner_id, f.owner_id)));
	
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
			COALESCE(vr_owner_id, f.owner_id),
			COALESCE(vr_owner_type, f.owner_type),
			f.file_id,
			f.extension,
			f.file_name,
			f.mime,
			f.size,
			vr_current_user_id,
			vr_now,
			FALSE
	FROM UNNEST(vr_doc_files) AS f
		LEFT JOIN dct_files AS d
		ON d.application_id = vr_application_id AND (d.id = f.file_id OR d.file_name_guid = f.file_id) AND
			((f.owner_id IS NULL AND d.owner_id IS NULL) OR (d.owner_id = COALESCE(vr_owner_id, f.owner_id)))
	WHERE d.id IS NULL;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
