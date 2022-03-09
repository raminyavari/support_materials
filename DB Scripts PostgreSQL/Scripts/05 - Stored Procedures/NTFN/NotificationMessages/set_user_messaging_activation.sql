DROP FUNCTION IF EXISTS ntfn_set_user_messaging_activation;

CREATE OR REPLACE FUNCTION ntfn_set_user_messaging_activation
(
	vr_application_id	UUID,
	vr_option_id		UUID,
	vr_user_id			UUID,
	vr_current_user_id	UUID,
	vr_now_date 		TIMESTAMP,
	vr_subject_type		VARCHAR(50),
	vr_user_status		VARCHAR(50),
	vr_action			VARCHAR(50),
	vr_media			VARCHAR(50),
	vr_lang				VARCHAR(50),
	vr_enable			BOOLEAN
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF EXISTS (
		SELECT 1 
		FROM ntfn_user_messaging_activation AS n
		WHERE n.application_id = vr_application_id AND n.option_id = vr_option_id
		LIMIT 1
	) THEN
		UPDATE ntfn_user_messaging_activation AS n
		SET "enable" = vr_enable,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
		WHERE n.application_id = vr_application_id AND n.option_id = vr_option_id;
	ELSE
		INSERT INTO ntfn_user_messaging_activation (
			application_id,
			option_id,
			user_id,
			subject_type,
			user_status,
			"action",
			media,
			lang,
			"enable"
		)
		VALUES (
			vr_application_id,
			vr_option_id,
			vr_user_id,
			vr_subject_type,
			vr_user_status,
			vr_action,
			vr_media,
			vr_lang,
			vr_enable
		);
	END IF;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

