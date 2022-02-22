DROP FUNCTION IF EXISTS prvc_initialize_confidentiality_levels;

CREATE OR REPLACE FUNCTION prvc_initialize_confidentiality_levels
(
	vr_application_id	UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_user_id	UUID;
	vr_now 		TIMESTAMP;
BEGIN
	vr_user_id := (
		SELECT un.user_id
		FROM users_normal AS un
		WHERE un.application_id = vr_application_id AND un.lowered_username = 'admin'
		LIMIT 1
	);
	
	IF vr_user_id IS NULL THEN
		SELECT vr_user_id = "a".creator_user_id
		FROM rv_applications AS "a"
		WHERE "a".application_id = vr_application_id
		LIMIT 1;
	END IF;
	
	IF vr_user_id IS NULL OR EXISTS (
		SELECT 1
		FROM prvc_confidentiality_levels AS l
		WHERE l.application_id = vr_application_id
		LIMIT 1
	) THEN 
		RETURN 1::INTEGER;
	END IF;
	
	vr_now := NOW();
	
	WITH "data" AS
	(
		SELECT 1::INTEGER AS level_id, 'فاقد طبقه بندی'::VARCHAR AS title
		
		UNION ALL
		
		SELECT 2::INTEGER AS level_id, 'محرمانه'::VARCHAR AS title
		
		UNION ALL
		
		SELECT 3::INTEGER AS level_id, 'خیلی محرمانه'::VARCHAR AS title
		
		UNION ALL
		
		SELECT 4::INTEGER AS level_id, 'سری'::VARCHAR AS title
		
		UNION ALL
		
		SELECT 5::INTEGER AS level_id, 'به کلی سری'::VARCHAR AS title
	)
	INSERT INTO prvc_confidentiality_levels (
		application_id, 
		"id", 
		level_id, 
		title, 
		creator_user_id, 
		creation_date, 
		deleted
	)
	SELECT 	vr_application_id, 
			gen_random_uuid(), 
			d.level_id, 
			d.title, 
			vr_user_id, 
			vr_now,
			FALSE
	FROM "data" AS d;
    
    RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

