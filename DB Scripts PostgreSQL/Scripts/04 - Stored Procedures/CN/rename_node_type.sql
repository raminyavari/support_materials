DROP FUNCTION IF EXISTS cn_rename_node_type;

CREATE OR REPLACE FUNCTION cn_rename_node_type
(
	vr_application_id	UUID,
    vr_node_type_id 	UUID,
    vr_name				VARCHAR(255),
    vr_current_user_id	UUID,
    vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result INTEGER = 0;
BEGIN
	UPDATE cn_node_types
	SET "name" = gfn_verify_string(vr_name),
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE application_id = vr_application_id AND node_type_id = vr_node_type_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

