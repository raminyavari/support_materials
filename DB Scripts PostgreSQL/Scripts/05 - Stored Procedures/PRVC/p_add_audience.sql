DROP FUNCTION IF EXISTS prvc_p_add_audience;

CREATE OR REPLACE FUNCTION prvc_p_add_audience
(
	vr_application_id	UUID,
	vr_object_id		UUID,
	vr_role_id			UUID,
	vr_permission_type	varchar(50),
	vr_allow			BOOLEAN,
	vr_expiration_date	TIMESTAMP,
	vr_current_user_id	UUID,
	vr_now	 			TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF EXISTS (
		SELECT 1
		FROM prvc_audience AS au
		WHERE au.application_id = vr_application_id AND 
			au.role_id = vr_role_id AND au.object_id = vr_object_id
		LIMIT 1
	) THEN
		UPDATE prvc_audience AS au
		SET allow = vr_allow,
			expiration_date = vr_expiration_date,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now,
			deleted = FALSE
		WHERE au.application_id = vr_application_id AND au.object_id = vr_object_id AND 
			au.role_id = vr_role_id AND au.permission_type = vr_permission_type;
	ELSE
		INSERT INTO prvc_audience (
			application_id,
			object_id,
			role_id,
			permission_type,
			allow,
			expiration_date,
			creator_user_id,
			creation_date,
			deleted
		)
		VALUES (
			vr_application_id,
			vr_object_id, 
			vr_role_id, 
			vr_permission_type,
			vr_allow, 
			vr_expiration_date, 
			vr_current_user_id, 
			vr_now, 
			FALSE
		);
	END IF;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

