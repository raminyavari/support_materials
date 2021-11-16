DROP FUNCTION IF EXISTS usr_p_set_first_and_last_name;

CREATE OR REPLACE FUNCTION usr_p_set_first_and_last_name
(
	vr_user_id 		UUID,
    vr_first_name	VARCHAR(255),
    vr_last_name	VARCHAR(255)
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	vr_first_name := gfn_verify_string(vr_first_name);
	vr_last_name := gfn_verify_string(vr_last_name);

	IF EXISTS (
		SELECT 1 
		FROM usr_profile AS "p"
		WHERE "p".user_id = vr_user_id
		LIMIT 1
	) THEN
		UPDATE usr_profile AS pr
		SET first_name = vr_first_name,
			last_name = vr_last_name
		WHERE pr.user_id = vr_user_id;
	ELSE
		INSERT INTO usr_profile (
			user_id,
			first_name,
			last_name
		)
		VALUES (
			vr_user_id,
			vr_first_name,
			vr_last_name
		);
	END IF;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

