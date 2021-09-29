DROP FUNCTION IF EXISTS dct_p_remove_owner_files;

CREATE OR REPLACE FUNCTION dct_p_remove_owner_files
(
	vr_application_id	UUID,
    vr_owner_id			UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF EXISTS(
		SELECT * 
		FROM dct_files AS d
		WHERE d.application_id = vr_application_id AND d.owner_id = vr_owner_id AND d.deleted = FALSE
		LIMIT 1
	) THEN
		UPDATE dct_files AS d
		SET deleted = TRUE
		WHERE d.application_id = vr_application_id AND d.owner_id = vr_owner_id AND d.deleted = FALSE;
		
		GET DIAGNOSTICS vr_result := ROW_COUNT;
		
		RETURN vr_result;
	ELSE
		RETURN 1::INTEGER;
	END IF;
END;
$$ LANGUAGE plpgsql;
