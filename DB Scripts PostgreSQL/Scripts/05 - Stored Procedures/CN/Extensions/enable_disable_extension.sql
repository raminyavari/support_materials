DROP FUNCTION IF EXISTS cn_enable_disable_extension;

CREATE OR REPLACE FUNCTION cn_enable_disable_extension
(
	vr_application_id	UUID,
	vr_owner_id			UUID,
	vr_extension		VARCHAR(50),
	vr_disable	 		BOOLEAN,
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE cn_extensions AS ex
	SET deleted = COALESCE(vr_disable, FALSE),
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE ex.application_id = vr_application_id AND 
		ex.owner_id = vr_owner_id AND ex.extension = vr_extension;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
