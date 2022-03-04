DROP FUNCTION IF EXISTS fg_set_element_limit_necessity;

CREATE OR REPLACE FUNCTION fg_set_element_limit_necessity
(
	vr_application_id	UUID,
	vr_owner_id			UUID,
	vr_element_id		UUID,
	vr_necessary		BOOLEAN,
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE fg_element_limits AS l
	SET necessary = COALESCE(vr_necessary, FALSE)::BOOLEAN,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE l.application_id = vr_application_id AND 
		l.owner_id = vr_owner_id AND l.element_id = vr_element_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

