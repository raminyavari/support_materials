DROP FUNCTION IF EXISTS dct_fn_files_count;

CREATE OR REPLACE FUNCTION dct_fn_files_count
(
	vr_application_id	UUID,
	vr_owner_id			UUID
)
RETURNS INTEGER
AS
$$
BEGIN
	RETURN COALESCE((
		SELECT COUNT(f.id)
		FROM dct_files AS f
		WHERE f.application_id = vr_application_id AND f.owner_id = vr_owner_id AND f.deleted = FALSE
	), 0)::INTEGER;
END;
$$ LANGUAGE PLPGSQL;