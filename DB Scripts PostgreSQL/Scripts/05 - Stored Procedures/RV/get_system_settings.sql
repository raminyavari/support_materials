DROP FUNCTION IF EXISTS rv_get_system_settings;

CREATE OR REPLACE FUNCTION rv_get_system_settings
(
	vr_application_id	UUID,
	vr_item_names		string_table_type[]
)
RETURNS TABLE (
	"name"	VARCHAR,
	"value"	VARCHAR
)
AS
$$
DECLARE
	vr_names	VARCHAR[];
	vr_count	INTEGER;
BEGIN
	vr_names := ARRAY(
		SELECT DISTINCT rf.value
		FROM UNNEST(vr_item_names) AS rf
	);
	
	vr_count := COALESCE(ARRAY_LENGTH(vr_names, 1), 0)::INTEGER;
	
	RETURN QUERY
	SELECT 	s.name, 
			s.value
	FROM rv_system_settings AS s
	WHERE s.application_id = vr_application_id AND 
		(vr_count = 0 OR s.name IN (SELECT n FROM UNNEST(vr_names) AS n));
END;
$$ LANGUAGE plpgsql;

