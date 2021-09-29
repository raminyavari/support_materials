DROP FUNCTION IF EXISTS dct_arithmetic_delete_owner_tree;

CREATE OR REPLACE FUNCTION dct_arithmetic_delete_owner_tree
(
	vr_application_id	UUID,
	vr_owner_id			UUID,
	vr_tree_id			UUID,
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS BOOLEAN
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE dct_tree_owners AS tr
	SET deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE tr.application_id = vr_application_id AND 
		tr.owner_id = vr_owner_id AND tr.tree_id = vr_tree_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
