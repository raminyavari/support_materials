DROP FUNCTION IF EXISTS dct_recycle_tree;

CREATE OR REPLACE FUNCTION dct_recycle_tree
(
	vr_application_id	UUID,
    vr_tree_id			UUID,
    vr_current_user_id	UUID,
    vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE dct_trees AS tr
	SET deleted = FALSE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE tr.application_id = vr_application_id AND tr.tree_id = vr_tree_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
