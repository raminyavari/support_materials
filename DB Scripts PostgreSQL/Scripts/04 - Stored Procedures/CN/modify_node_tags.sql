DROP FUNCTION IF EXISTS cn_modify_node_tags;

CREATE OR REPLACE FUNCTION cn_modify_node_tags
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_tags				VARCHAR,
    vr_current_user_id	UUID,
    vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER = 0;
BEGIN
	UPDATE cn_nodes
	SET tags = gfn_verify_string(vr_tags),
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE application_id = vr_application_id AND node_id = vr_node_id;

	GET DIAGNOSTICS vr_result := ROW_COUNT;

	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

