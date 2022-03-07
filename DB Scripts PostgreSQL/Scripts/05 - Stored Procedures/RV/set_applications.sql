DROP FUNCTION IF EXISTS rv_set_applications;

CREATE OR REPLACE FUNCTION rv_set_applications
(
	vr_applications		guid_string_table_type[]
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result_1	INTEGER;
	vr_result_2	INTEGER;
BEGIN
	UPDATE rv_applications
	SET application_name = "a".second_value,
		lowered_application_name = LOWER("a".second_value)
	FROM UNNEST(vr_applications) AS "a"
		INNER JOIN rv_applications AS app
		ON app.application_id = "a".first_value;
		
	GET DIAGNOSTICS vr_result_1 := ROW_COUNT;
		
	INSERT INTO rv_applications (
		application_id,
		application_name,
		lowered_application_name
	)
	SELECT 	"a".first_value, 
			"a".second_value, 
			LOWER("a".second_value)
	FROM UNNEST(vr_applications) AS "a"
		LEFT JOIN rv_applications AS app
		ON app.application_id = "a".first_value
	WHERE app.application_id IS NULL;
	
	GET DIAGNOSTICS vr_result_2 := ROW_COUNT;
	
	RETURN vr_result_1 + vr_result_2;
END;
$$ LANGUAGE plpgsql;

