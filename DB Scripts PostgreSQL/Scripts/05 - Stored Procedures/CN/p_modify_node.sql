DROP FUNCTION IF EXISTS cn_p_modify_node;

CREATE OR REPLACE FUNCTION cn_p_modify_node
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_name				VARCHAR(255),
    vr_description		VARCHAR,
    vr_tags				VARCHAR(2000),
    vr_current_user_id	UUID,
    vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER = 0;
BEGIN
	vr_name := gfn_verify_string(vr_name);
	vr_description := gfn_verify_string(vr_description);
	vr_tags := gfn_verify_string(vr_tags);
	
	UPDATE cn_nodes
	SET Name = CASE WHEN COALESCE(vr_name, N'') = N'' THEN Name ELSE vr_name END,
		description = vr_description,
		tags = vr_tags,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE application_id = vr_application_id AND node_id = vr_node_id;

	GET DIAGNOSTICS vr_result := ROW_COUNT;

	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

