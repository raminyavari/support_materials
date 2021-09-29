DROP FUNCTION IF EXISTS dct_get_owner_trees;

CREATE OR REPLACE FUNCTION dct_get_owner_trees
(
	vr_application_id	UUID,
	vr_owner_id			UUID
)
RETURNS SETOF dct_tree_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT tr.tree_id
		FROM dct_tree_owners AS tr
		WHERE tr.application_id = vr_application_id AND 
			tr.owner_id = vr_owner_id AND tr.deleted = FALSE
	);
	
	RETURN QUERY
	SELECT *
	FROM dct_p_get_trees_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;
