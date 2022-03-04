DROP FUNCTION IF EXISTS fg_p_copy_form_instances;

CREATE OR REPLACE FUNCTION fg_p_copy_form_instances
(
	vr_application_id	UUID,
	vr_old_owner_id		UUID,
	vr_new_owner_id		UUID,
	vr_new_form_id		UUID,
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF EXISTS (
		SELECT 1
		FROM fg_form_instances AS i
		WHERE i.application_id = vr_application_id AND 
			i.owner_id = vr_old_owner_id AND i.deleted = FALSE
		LIMIT 1
	) THEN
		INSERT INTO fg_form_instances (
			application_id,
			instance_id,
			form_id,
			owner_id,
			director_id,
			filled,
			creator_user_id,
			creation_date,
			deleted
		)
		SELECT	vr_application_id,
				gen_random_uuid(),
				COALESCE(vr_new_form_id, i.form_id),
				vr_new_owner_id,
				i.director_id,
				FALSE,
				vr_current_user_id,
				vr_now,
				FALSE
		FROM fg_form_instances AS i
		WHERE i.application_id = vr_application_id AND 
			i.owner_id = vr_old_owner_id AND i.deleted = FALSE;
		
		GET DIAGNOSTICS vr_result := ROW_COUNT;
		
		RETURN vr_result;
	ELSE
		RETURN 1::INTEGER;
	END IF;
END;
$$ LANGUAGE plpgsql;

