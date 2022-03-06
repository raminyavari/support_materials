DROP FUNCTION IF EXISTS fg_set_poll_description;

CREATE OR REPLACE FUNCTION fg_set_poll_description
(
	vr_application_id	UUID,
	vr_poll_id			UUID,
	vr_description 		VARCHAR(2000),
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE fg_polls AS "p"
	SET description = gfn_verify_string(vr_description),
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE "p".application_id = vr_application_id AND "p".poll_id = vr_poll_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

