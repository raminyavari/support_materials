DROP FUNCTION IF EXISTS cn_set_additional_id_pattern;

CREATE OR REPLACE FUNCTION cn_set_additional_id_pattern
(
	vr_application_id			UUID,
    vr_node_type_id 			UUID,
    vr_additional_id_Pattern	VARCHAR(255),
    vr_current_user_id			UUID,
    vr_now 						TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER = 0;
BEGIN
	UPDATE cn_node_types AS x
	SET additional_id_pattern = vr_additional_id_pattern,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE x.application_id = vr_application_id AND x.node_type_id = vr_node_type_id;

	GET DIAGNOSTICS vr_result := ROW_COUNT;

	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

