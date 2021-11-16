DROP FUNCTION IF EXISTS usr_set_phone_number;

CREATE OR REPLACE FUNCTION usr_set_phone_number
(
	vr_number_id			UUID,
    vr_user_id 				UUID,
    vr_phone_number			VARCHAR(50),
    vr_phone_number_type	VARCHAR(20),
    vr_creator_user_id		UUID,
    vr_creation_date	 	TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	INSERT INTO usr_phone_numbers (
		number_id,
		phone_number,
		user_id,
		creator_user_id,
		creation_date,
		phone_type, 
		deleted
	)
	VALUES (
		vr_number_id,
		vr_phone_number,
		vr_user_id,
		vr_creator_user_id,
		vr_creation_date,
		vr_phone_number_type,
		FALSE
	);
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

