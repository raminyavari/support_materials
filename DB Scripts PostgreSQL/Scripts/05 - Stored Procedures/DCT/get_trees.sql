DROP FUNCTION IF EXISTS dct_get_trees;

CREATE OR REPLACE FUNCTION dct_get_trees
(
	vr_application_id	UUID,
    vr_owner_id			UUID,
    vr_archive	 		BOOLEAN
)
RETURNS SETOF dct_tree_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT DISTINCT rf.tree_id
		FROM dct_trees AS rf
		WHERE rf.application_id = vr_application_id AND 
			((vr_owner_id IS NULL AND rf.is_private = FALSE) OR rf.owner_id = vr_owner_id) AND
			rf.deleted = COALESCE(vr_archive, FALSE)
	);

	RETURN QUERY
	SELECT *
	FROM dct_p_get_trees_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;
