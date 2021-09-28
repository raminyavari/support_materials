DROP FUNCTION IF EXISTS cn_add_complex_admin;

CREATE OR REPLACE FUNCTION cn_add_complex_admin
(
	vr_application_id	UUID,
	vr_list_id			UUID,
	vr_user_id			UUID,
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER = 0;
BEGIN
	IF EXISTS(
		SELECT * 
		FROM cn_list_admins AS "a"
		WHERE "a".application_id = vr_application_id AND "a".list_id = vr_list_id AND "a".user_id = vr_user_id
		LIMIT 1
	) THEN
		UPDATE cn_list_admins AS x
		SET last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now,
		 	deleted = FALSE
		WHERE x.application_id = vr_application_id AND x.list_id = vr_list_id AND x.user_id = vr_user_id;
	ELSE
		INSERT INTO cn_list_admins(
			application_id,
			list_id,
			user_id,
			creator_user_id,
			creation_date,
			deleted
		)
		VALUES(
			vr_application_id,
			vr_list_id,
			vr_user_id,
			vr_current_user_id,
			vr_now,
			FALSE
		);
	END IF;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

