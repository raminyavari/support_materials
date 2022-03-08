DROP FUNCTION IF EXISTS rv_set_owner_variable;

CREATE OR REPLACE FUNCTION rv_set_owner_variable
(
	vr_application_id	UUID,
	vr_id				BIGINT,
	vr_owner_id			UUID,
	vr_name				VARCHAR(100),
	vr_value		 	VARCHAR,
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS BIGINT
AS
$$
DECLARE
	vr_result	INTEGER;
	vr_new_id	BIGINT;
BEGIN
	IF vr_name IS NOT NULL THEN 
		vr_name := LOWER(vr_name);
	END IF;
	
	IF vr_id IS NOT NULL THEN
		UPDATE rv_variables_with_owner AS v
		SET "name" = LOWER(CASE WHEN COALESCE(vr_name, '') = '' THEN v."name" ELSE vr_name END),
			"value" = vr_value,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
		WHERE v.application_id = vr_application_id AND v.id = vr_id;
		
		GET DIAGNOSTICS vr_result := ROW_COUNT;
		
		RETURN CASE WHEN vr_result > 0 THEN vr_id ELSE NULL::BIGINT END;
	ELSE
		INSERT INTO rv_variables_with_owner (
			application_id,
			owner_id,
			"name",
			"value",
			creator_user_id,
			creation_date,
			deleted
		)
		VALUES (
			vr_application_id,
			vr_owner_id,
			LOWER(vr_name),
			vr_value,
			vr_current_user_id,
			vr_now,
			FALSE
		)
		RETURNING "id" INTO vr_new_id;
		
		RETURN vr_new_id;
	END IF;
END;
$$ LANGUAGE plpgsql;

