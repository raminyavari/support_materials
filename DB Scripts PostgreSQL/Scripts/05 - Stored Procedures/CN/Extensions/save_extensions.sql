DROP FUNCTION IF EXISTS cn_save_extensions;

CREATE OR REPLACE FUNCTION cn_save_extensions
(
	vr_application_id	UUID,
	vr_owner_id			UUID,
	vr_extensions		cn_extension_table_type[],
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result					INTEGER;
BEGIN
	WITH tbl AS (
		SELECT x.extension, x.title, COALESCE(x.disabled, FALSE)::INTEGER
		FROM UNNEST(vr_extensions) AS x
	)
	UPDATE cn_extensions
	SET title = "t".title,
		deleted = CASE WHEN "t".extension IS NULL THEN TRUE ELSE "t".deleted END,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM cn_extensions AS x
		LEFT JOIN tbl AS "t"
		ON "t".extension = x.extension
	WHERE x.application_id = vr_application_id AND x.owner_id = vr_owner_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
