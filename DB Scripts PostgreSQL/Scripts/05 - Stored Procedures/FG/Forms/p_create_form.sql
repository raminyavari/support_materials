DROP FUNCTION IF EXISTS fg_p_create_form;

CREATE OR REPLACE FUNCTION fg_p_create_form
(
	vr_application_id	UUID,
    vr_form_id			UUID,
    vr_template_form_id	UUID,
	vr_title			VARCHAR(255),
	vr_current_user_id	UUID,
	vr_now	 			TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER DEFAULT 0;
BEGIN
	vr_title := gfn_verify_string(vr_title);
	
	IF EXISTS (
		SELECT 1
		FROM fg_extended_forms AS f
		WHERE f.application_id = vr_application_id AND 
			f.title = vr_title AND f.deleted = TRUE
		LIMIT 1
	) THEN
		UPDATE fg_extended_forms AS f
		SET template_form_id = vr_template_form_id,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now,
			deleted = FALSE
		WHERE f.application_id = vr_application_id AND 
			f.title = vr_title AND f.deleted = TRUE;
				
		GET DIAGNOSTICS vr_result := ROW_COUNT;
	ELSEIF EXISTS (
		SELECT 1
		FROM fg_extended_forms AS f
		WHERE f.application_id = vr_application_id AND 
			f.title = vr_title AND f.deleted = FALSE
		LIMIT 1
	) THEN
		vr_result := -1;
	ELSE
		INSERT INTO fg_extended_forms (
			application_id,
			form_id,
			template_form_id,
			title,
			creator_user_id,
			creation_date,
			deleted
		)
		VALUES (
			vr_application_id,
			vr_form_id,
			vr_template_form_id,
			vr_title,
			vr_current_user_id,
			vr_now,
			FALSE
		);
		
		GET DIAGNOSTICS vr_result := ROW_COUNT;
	END IF;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

