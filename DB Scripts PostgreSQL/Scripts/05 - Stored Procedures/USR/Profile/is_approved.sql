DROP FUNCTION IF EXISTS usr_is_approved;

CREATE OR REPLACE FUNCTION usr_is_approved
(
	vr_application_id	UUID,
    vr_user_id 			UUID,
    vr_is_approved	 	BOOLEAN
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF vr_is_approved IS NULL THEN
		RETURN COALESCE((
			SELECT mm.is_approved
			FROM rv_membership AS mm
			WHERE mm.user_id = vr_user_id
			LIMIT 1
		), FALSE)::INTEGER;
	ELSE
		UPDATE rv_membership AS mm
		SET is_approved = vr_is_approved
		WHERE mm.user_id = vr_user_id;
		
		GET DIAGNOSTICS vr_result := ROW_COUNT;
		
		RETURN vr_result;
	END IF;
END;
$$ LANGUAGE plpgsql;

