DROP FUNCTION IF EXISTS prvc_set_audience;

CREATE OR REPLACE FUNCTION prvc_set_audience
(
	vr_application_id		UUID,
	vr_object_ids			guid_table_type[],
	vr_default_permissions	guid_string_pair_table_type[],
	vr_audience				privacy_audience_table_type[],
	vr_settings				guid_pair_bit_table_type[],
	vr_current_user_id		UUID,
	vr_now			 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
BEGIN
	-- Update Settings
	DELETE FROM prvc_settings AS x
	USING (
			SELECT s.object_id
			FROM UNNEST(vr_object_ids) AS ids
				INNER JOIN prvc_settings AS s
				ON s.object_id = ids.value
				LEFT JOIN UNNEST(vr_settings) AS "t"
				ON "t".first_value = ids.value
			WHERE "t".first_value IS NULL
		) AS y
	WHERE y.object_id = x.object_id;
	
	UPDATE prvc_settings
	SET calculate_hierarchy = COALESCE("t".bit_value, FALSE),
		confidentiality_id = "t".second_value,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM prvc_settings AS s
		INNER JOIN UNNEST(vr_settings) AS "t"
		ON "t".first_value = s.object_id;
	
	INSERT INTO prvc_settings (
		application_id, 
		object_id, 
		calculate_hierarchy, 
		confidentiality_id, 
		creator_user_id, 
		creation_date
	)
	SELECT 	vr_application_id, 
			"t".first_value, 
			COALESCE("t".bit_value, FALSE), 
			"t".second_value, 
			vr_current_user_id, 
			vr_now
	FROM UNNEST(vr_settings) AS "t"
		LEFT JOIN prvc_settings AS s
		ON s.object_id = "t".first_value
	WHERE s.object_id IS NULL;
	-- end of Update Settings
	
	
	-- Update Default Permissions
	DELETE FROM prvc_default_permissions AS x
	USING (
			SELECT "p".object_id
			FROM UNNEST(vr_object_ids) AS ids
				INNER JOIN prvc_default_permissions AS "p"
				ON "p".object_id = ids.value
				LEFT JOIN UNNEST(vr_default_permissions) AS d
				ON d.guid_value = ids.value AND d.first_value = "p".permission_type
			WHERE d.guid_value IS NULL
		) AS y
	WHERE y.object_id = x.object_id;
	
	UPDATE prvc_default_permissions
	SET defaultValue = d.second_value,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM prvc_default_permissions AS "p"
		INNER JOIN UNNEST(vr_default_permissions) AS d
		ON d.guid_value = "p".object_id AND d.first_value = "p".permission_type;
	
	INSERT INTO prvc_default_permissions (
		application_id, 
		object_id, 
		permission_type, 
		default_value, 
		creator_user_id, 
		creation_date
	)
	SELECT 	vr_application_id, 
			d.guid_value, 
			d.first_value, 
			d.second_value, 
			vr_current_user_id, 
			vr_now
	FROM UNNEST(vr_default_permissions) AS d
		LEFT JOIN prvc_default_permissions AS "p"
		ON "p".object_id = d.guid_value AND "p".permission_type = d.first_value
	WHERE "p".object_id IS NULL;
	-- end of Update Default Permissions
	
	
	-- Update Audience
	UPDATE prvc_audience
	SET deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM UNNEST(vr_object_ids) AS ids
		INNER JOIN prvc_audience AS "a"
		ON "a".object_id = ids.value
		LEFT JOIN UNNEST(vr_audience) AS d
		ON d.object_id = "a".object_id AND 
			d.role_id = "a".role_id AND d.permission_type = "a".permission_type
	WHERE d.object_id IS NULL;
	
	UPDATE prvc_audience
	SET allow = COALESCE(d.allow, FALSE),
		permission_type = d.permission_type,
		expiration_date = d.expiration_date,
		deleted = FALSE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM prvc_audience AS "a"
		INNER JOIN UNNEST(vr_audience) AS d
		ON d.object_id = "a".object_id AND 
			d.role_id = "a".role_id AND d.permission_type = "a".permission_type;
	
	INSERT INTO prvc_audience (
		application_id, 
		object_id, 
		role_id, 
		allow, 
		permission_type, 
		expiration_date, 
		creator_user_id, 
		creation_date, 
		deleted
	)
	SELECT 	vr_application_id, 
			d.object_id, 
			d.role_id, 
			COALESCE(d.allow, FALSE), 
			d.permission_type, 
			d.expiration_date, 
			vr_current_user_id, 
			vr_now, 
			FALSE
	FROM UNNEST(vr_audience) AS d
		LEFT JOIN prvc_audience AS "a"
		ON "a".object_id = d.object_id AND 
			"a".role_id = d.role_id AND d.permission_type = "a".permission_type
	WHERE "a".object_id IS NULL;
	-- end of Update Audience
	
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

