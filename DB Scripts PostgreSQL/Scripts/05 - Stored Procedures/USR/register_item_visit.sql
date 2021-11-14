DROP FUNCTION IF EXISTS usr_register_item_visit;

CREATE OR REPLACE FUNCTION usr_register_item_visit
(
	vr_application_id	UUID,
	vr_item_id			UUID,
    vr_user_id			UUID,
    vr_visit_date	 	TIMESTAMP,
    vr_item_type		VARCHAR(20)
)
RETURNS INTEGER
AS
$$
BEGIN
	INSERT INTO usr_item_visits (
		application_id,
		item_id,
		visit_date,
		user_id,
		item_type,
		unique_id
	)
	VALUES(
		vr_application_id,
		vr_item_id,
		vr_visit_date,
		vr_user_id,
		vr_item_type,
		gen_random_uuid()
	);
	
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

