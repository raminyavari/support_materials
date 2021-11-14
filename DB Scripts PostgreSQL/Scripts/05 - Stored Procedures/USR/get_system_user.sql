DROP FUNCTION IF EXISTS usr_get_system_user;

CREATE OR REPLACE FUNCTION usr_get_system_user
(
	vr_application_id	UUID
)
RETURNS SETOF usr_user_ret_composite
AS
$$
DECLARE
	vr_user_id	UUID;
	vr_ids		UUID[];
	vr_result	INTEGER;
BEGIN
	IF NOT EXISTS(
		SELECT * 
		FROM users_normal AS un
		WHERE (vr_application_id IS NULL OR un.application_id = vr_application_id) AND 
			un.lowered_username = 'system'
		LIMIT 1
	) THEN
		vr_user_id := gen_random_uuid();
		
		vr_ids := ARRAY(
			SELECT vr_user_id
		);
		
		vr_result := usr_p_create_system_user(vr_application_id, vr_user_id);
	ELSE
		IF vr_application_id IS NULL THEN
			vr_ids := ARRAY(
				SELECT un.user_id
				FROM usr_view_users AS un
				WHERE un.lowered_username = 'system'
			);
		ELSE
			vr_ids := ARRAY(
				SELECT un.user_id
				FROM users_normal AS un
				WHERE un.application_id = vr_application_id AND un.lowered_username = 'system'
			);
		END IF;
	END IF;
	
	RETURN QUERY
	SELECT *
	FROM usr_p_get_users_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;

