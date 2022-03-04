DROP FUNCTION IF EXISTS fg_p_set_form_owner;

CREATE OR REPLACE FUNCTION fg_p_set_form_owner
(
	vr_application_id	UUID,
	vr_owner_id			UUID,
	vr_form_id			UUID,
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
		FROM fg_form_owners AS o
		WHERE o.application_id = vr_application_id AND o.owner_id = vr_owner_id
		LIMIT 1
	) THEN
		UPDATE fg_form_owners AS o
		SET form_id = vr_form_id,
		 	deleted = FALSE,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
		WHERE o.application_id = vr_application_id AND o.owner_id = vr_owner_id;
	ELSE
		INSERT INTO fg_form_owners (
			application_id,
			owner_id,
			form_id,
			creator_user_id,
			creation_date,
			deleted
		)
		VALUES (
			vr_application_id,
			vr_owner_id,
			vr_form_id,
			vr_current_user_id,
			vr_now,
			FALSE
		);
	END IF;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

