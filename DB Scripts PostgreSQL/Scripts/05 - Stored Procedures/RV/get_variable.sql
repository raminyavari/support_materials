DROP FUNCTION IF EXISTS rv_get_variable;

CREATE OR REPLACE FUNCTION rv_get_variable
(
	vr_application_id	UUID,
	vr_name				VARCHAR(100)
)
RETURNS VARCHAR
AS
$$
BEGIN
	RETURN (
		SELECT v."value"
		FROM rv_variables AS v
		WHERE (vr_application_id IS NULL OR v.application_id = vr_application_id) AND 
			v.name = LOWER(vr_name)
		LIMIT 1
	);
END;
$$ LANGUAGE plpgsql;

