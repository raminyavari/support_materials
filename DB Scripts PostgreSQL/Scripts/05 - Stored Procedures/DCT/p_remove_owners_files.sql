DROP FUNCTION IF EXISTS dct_p_remove_owners_files;

CREATE OR REPLACE FUNCTION dct_p_remove_owners_files
(
	vr_application_id	UUID,
    vr_owner_ids		UUID[]
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF EXISTS(
		SELECT * 
		FROM UNNEST(vr_owner_ids) AS x
			INNER JOIN dct_files AS d
			ON d.application_id = vr_application_id AND d.owner_id = x AND d.deleted = FALSE
		LIMIT 1
	) THEN
		UPDATE dct_files
		SET deleted = TRUE
		FROM UNNEST(vr_owner_ids) AS x
			INNER JOIN dct_files AS d
			ON d.application_id = vr_application_id AND d.owner_id = x AND d.deleted = FALSE;
		
		GET DIAGNOSTICS vr_result := ROW_COUNT;
		
		RETURN vr_result;
	ELSE
		RETURN 1::INTEGER;
	END IF;
END;
$$ LANGUAGE plpgsql;
