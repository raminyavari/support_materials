DROP FUNCTION IF EXISTS fg_arithmetic_delete_form_owner;

CREATE OR REPLACE FUNCTION fg_arithmetic_delete_form_owner
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
	UPDATE fg_form_owners AS o
	SET deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE o.application_id = vr_application_id AND o.owner_id = vr_owner_id AND o.form_id = vr_form_id;

	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

