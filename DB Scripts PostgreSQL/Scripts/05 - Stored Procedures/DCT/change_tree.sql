DROP FUNCTION IF EXISTS dct_change_tree;

CREATE OR REPLACE FUNCTION dct_change_tree
(
	vr_application_id	UUID,
    vr_tree_id 			UUID,
    vr_new_name		 	VARCHAR(256),
    vr_new_description	VARCHAR(1000),
    vr_current_user_id	UUID,
    vr_now	 			TIMESTAMP,
    vr_is_template		BOOLEAN
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE dct_trees AS tr
	SET "name" = gfn_verify_string(vr_new_name),
		description = gfn_verify_string(vr_new_description),
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now,
		is_template = vr_is_template
	WHERE tr.application_id = vr_application_id AND tr.tree_id = vr_tree_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
