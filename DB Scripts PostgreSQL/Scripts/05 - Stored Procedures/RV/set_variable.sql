DROP FUNCTION IF EXISTS rv_set_variable;

CREATE OR REPLACE FUNCTION rv_set_variable
(
	vr_application_id	UUID,
	vr_name				VARCHAR(100),
	vr_value		 	VARCHAR,
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	vr_name := LOWER(vr_name);
	
	IF EXISTS (
		SELECT 1 
		FROM rv_variables  AS v
		WHERE (vr_application_id IS NULL OR v.application_id = vr_application_id) AND v.name = vr_name
		LIMIT 1
	) THEN
		UPDATE rv_variables AS v
		SET "value" = vr_value,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
		WHERE (vr_application_id IS NULL OR v.application_id = vr_application_id) AND v.name = vr_name;
	ELSE
		INSERT INTO rv_variables (
			application_id,
			"name",
			"value",
			last_modifier_user_id,
			last_modification_date
		)
		VALUES (
			vr_application_id,
			vr_name,
			vr_value,
			vr_current_user_id,
			vr_now
		);
	END IF;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

