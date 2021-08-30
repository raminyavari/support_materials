DROP FUNCTION IF EXISTS cn_set_additional_id;

CREATE OR REPLACE FUNCTION cn_set_additional_id
(
	vr_application_id		UUID,
    vr_id					UUID,
    vr_additional_id_main	VARCHAR(300),
    vr_additional_id		VARCHAR(50),
    vr_current_user_id		UUID,
    vr_now			 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER = 0;
BEGIN
	IF EXISTS(
		SELECT node_id
		FROM cn_nodes 
		WHERE application_id = vr_application_id AND node_id = vr_id
		LIMIT 1
	) THEN
		UPDATE cn_nodes
		SET additional_id_main = vr_additional_id_main,
			additional_id = vr_additional_id,
			lastModifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
		WHERE application_id = vr_application_id AND node_id = vr_id;
	ELSE
		UPDATE cn_node_types
		SET additional_id = vr_additional_id,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
		WHERE application_id = vr_application_id AND node_type_id = vr_id;
	END IF;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;

	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

