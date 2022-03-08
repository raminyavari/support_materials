DROP FUNCTION IF EXISTS rv_set_system_settings;

CREATE OR REPLACE FUNCTION rv_set_system_settings
(
	vr_application_id	UUID,
	vr_items			string_pair_table_type[],
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE rv_system_settings
	SET "value" = i.second_value,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM UNNEST(vr_items) AS i
		INNER JOIN rv_system_settings AS s
		ON s.application_id = vr_application_id AND s.name = i.first_value;
		
	INSERT INTO rv_system_settings (
		application_id, 
		"name", 
		"value", 
		last_modifier_user_id, 
		last_modification_date
	)
	SELECT 	vr_application_id, 
			i.first_value, 
			gfn_verify_string(i.second_value), 
			vr_current_user_id, 
			vr_now
	FROM UNNEST(vr_items) AS i
		LEFT JOIN rv_system_settings AS s
		ON s.application_id = vr_application_id AND s.name = i.first_value
	WHERE s.id IS NULL;
	
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

