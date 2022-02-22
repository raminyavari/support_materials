DROP FUNCTION IF EXISTS de_update_user_confidentialities;

CREATE OR REPLACE FUNCTION de_update_user_confidentialities
(
	vr_application_id	UUID,
	vr_current_user_id	UUID,
    vr_input			int_string_table_type[],
    vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_values	guid_pair_table_type[]; /* first_value: user_id, second_value: confidentiality_id */
	vr_result_1	INTEGER;
	vr_result_2	INTEGER;
BEGIN
	vr_values := ARRAY(
		SELECT DISTINCT ROW(un.user_id, l.id)
		FROM UNNEST(vr_input) AS rf
			INNER JOIN users_normal AS un
			ON un.application_id = vr_application_id AND LOWER(un.username) = LOWER(rf.second_value)
			INNER JOIN prvc_confidentiality_levels AS l
			ON l.application_id = vr_application_id AND l.level_id = rf.first_value::INTEGER
	);
		
	UPDATE prvc_settings
	SET confidentiality_id = v.second_value,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM UNNEST(vr_values) AS v
		INNER JOIN prvc_settings AS s
		ON s.application_id = vr_application_id AND s.object_id = v.first_value;
	
	GET DIAGNOSTICS vr_result_1 := ROW_COUNT;
	
	INSERT INTO prvc_settings (
		application_id,
		object_id,
		confidentiality_id,
		creator_user_id,
		creation_date
	)
	SELECT 	vr_application_id, 
			v.user_id, 
			v.second_value, 
			vr_current_user_id, 
			vr_now
	FROM UNNEST(vr_values) AS v
		LEFT JOIN prvc_settings AS s
		ON s.application_id = vr_application_id AND s.object_id = v.first_value
	WHERE s.object_id IS NULL;
	
	GET DIAGNOSTICS vr_result_2 := ROW_COUNT;

	RETURN COALESCE(vr_result_1, 0)::INTEGER + COALESCE(vr_result_2, 0)::INTEGER;
END;
$$ LANGUAGE plpgsql;

