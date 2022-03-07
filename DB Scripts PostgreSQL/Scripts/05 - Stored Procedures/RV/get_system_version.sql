DROP FUNCTION IF EXISTS rv_get_system_version;

CREATE OR REPLACE FUNCTION rv_get_system_version()
RETURNS VARCHAR
AS
$$
BEGIN
	RETURN (
		SELECT s.version
		FROM app_setting AS s
		LIMIT 1
	);
END;
$$ LANGUAGE plpgsql;

