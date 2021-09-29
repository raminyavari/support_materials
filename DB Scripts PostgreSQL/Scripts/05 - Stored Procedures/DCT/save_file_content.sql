DROP FUNCTION IF EXISTS dct_save_file_content;

CREATE OR REPLACE FUNCTION dct_save_file_content
(
	vr_application_id	UUID,
	vr_file_id			UUID,
	vr_content	 		VARCHAR,
	vr_not_extractable 	BOOLEAN,
	vr_file_not_fount 	BOOLEAN,
	vr_duration			BIGINT,
	vr_extraction_date 	TIMESTAMP,
	vr_error		 	VARCHAR
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
    INSERT INTO dct_file_contents (
		application_id,
		file_id, 
		"content", 
		not_extractable,
		file_not_found, 
		duration, 
		extraction_date, 
		"error"
	)
    VALUES (
		vr_application_id, 
		vr_file_id, 
		gfn_verify_string(COALESCE(vr_content, '')), 
		vr_not_extractable, 
		vr_file_not_fount, 
		vr_duration, 
		vr_extraction_date, 
		vr_error
	);
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
    
    RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
