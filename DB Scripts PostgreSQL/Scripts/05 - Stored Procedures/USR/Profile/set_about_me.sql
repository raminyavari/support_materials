DROP FUNCTION IF EXISTS usr_set_about_me;

CREATE OR REPLACE FUNCTION usr_set_about_me
(
	vr_user_id 	UUID,
    vr_text 	VARCHAR(2000)
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE usr_profile AS pr
	SET about_me = gfn_verify_string(vr_text)
	WHERE pr.user_id = vr_user_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

