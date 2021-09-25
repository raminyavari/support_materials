DROP FUNCTION IF EXISTS cn_modify_complex;

CREATE OR REPLACE FUNCTION cn_modify_complex
(
	vr_application_id	UUID,
    vr_list_id			UUID,
    vr_name				VARCHAR(255),
    vr_description		VARCHAR(2000),
    vr_current_user_id	UUID,
    vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE cn_lists AS l
	SET "name" = gfn_verify_string(vr_name),
		description = gfn_verify_string(vr_description),
		last_modifier_user_id = vr_current_id,
		last_modification_date = vr_now
	WHERE l.application_id = vr_application_id AND l.list_id = vr_list_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;

	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
