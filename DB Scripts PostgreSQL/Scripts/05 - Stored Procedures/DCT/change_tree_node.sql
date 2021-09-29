DROP FUNCTION IF EXISTS dct_change_tree_node;

CREATE OR REPLACE FUNCTION dct_change_tree_node
(
	vr_application_id	UUID,
    vr_tree_node_id 	UUID,
    vr_new_name		 	VARCHAR(256),
    vr_new_description	VARCHAR(1000),
    vr_current_user_id	UUID,
    vr_now	 			TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE dct_tree_nodes AS tn
	SET "name" = CASE WHEN COALESCE(vr_new_name, '') = '' THEN tn.name ELSE gfn_verify_string(vr_new_name) END,
		description = gfn_verify_string(vr_new_description),
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE tn.application_id = vr_application_id AND tn.tree_node_id = vr_tree_node_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
