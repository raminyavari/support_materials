DROP FUNCTION IF EXISTS dct_p_remove_trees;

CREATE OR REPLACE FUNCTION dct_p_remove_trees
(
	vr_application_id	UUID,
    vr_tree_ids			UUID[],
    vr_owner_id			UUID,
    vr_current_user_id	UUID,
    vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE dct_trees
	SET deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM UNNEST(vr_tree_ids) AS x
		INNER JOIN dct_trees AS "t"
		ON "t".application_id = vr_application_id AND "t".tree_id = x AND
			((vr_owner_id IS NULL AND "t".owner_id IS NULL) OR "t".owner_id = vr_owner_id);
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
