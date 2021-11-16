DROP FUNCTION IF EXISTS usr_set_first_and_last_name;

CREATE OR REPLACE FUNCTION usr_set_first_and_last_name
(
	vr_user_id 		UUID,
    vr_first_name	VARCHAR(255),
    vr_last_name	VARCHAR(255)
)
RETURNS INTEGER
AS
$$
BEGIN
	RETURN usr_p_set_first_and_last_name(vr_user_id, vr_first_name, vr_last_name);
END;
$$ LANGUAGE plpgsql;

