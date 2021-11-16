DROP FUNCTION IF EXISTS usr_set_theme;

CREATE OR REPLACE FUNCTION usr_set_theme
(
	vr_user_id	UUID,
    vr_theme	VARCHAR(50)
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE usr_profile AS pr
	SET theme = vr_theme
	WHERE pr.user_id = vr_user_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

