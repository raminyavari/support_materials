DROP FUNCTION IF EXISTS dct_fn_has_file;

CREATE OR REPLACE FUNCTION dct_fn_has_file
(
	vr_application_id	UUID,
	vr_owner_id			UUID
)
RETURNS BOOLEAN
AS
$$
BEGIN
	RETURN COALESCE((
		SELECT 1
		FROM dct_files AS f
		WHERE f.application_id = vr_application_id AND f.owner_id = vr_owner_id AND f.deleted = FALSE
		LIMIT 1
	), 0)::BOOLEAN;
END;
$$ LANGUAGE PLPGSQL;