DROP FUNCTION IF EXISTS cn_p_modify_node_name;

CREATE OR REPLACE FUNCTION cn_p_modify_node_name
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_name				VARCHAR(255),
    vr_current_user_id	UUID,
    vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER = 0;
BEGIN
	UPDATE cn_nodes AS x
	SET "name" = gfn_verify_string(vr_name),
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE x.application_id = vr_application_id AND x.node_id = vr_node_id;

	GET DIAGNOSTICS vr_result := ROW_COUNT;

	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

