DROP FUNCTION IF EXISTS cn_arithmetic_delete_relation_type;

CREATE OR REPLACE FUNCTION cn_arithmetic_delete_relation_type
(
	vr_application_id	UUID,
    vr_relation_type_id UUID,
    vr_current_user_id	UUID,
    vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER = 0;
BEGIN
	UPDATE cn_properties
	SET deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE application_id = vr_application_id AND property_id = vr_relation_type_id;

	GET DIAGNOSTICS vr_result := ROW_COUNT;

	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

