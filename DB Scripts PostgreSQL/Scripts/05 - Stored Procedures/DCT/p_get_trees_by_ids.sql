DROP FUNCTION IF EXISTS dct_p_get_trees_by_ids;

CREATE OR REPLACE FUNCTION dct_p_get_trees_by_ids
(
	vr_application_id	UUID,
    vr_tree_ids			UUID[],
	vr_total_count		INTEGER DEFAULT 0
)
RETURNS SETOF dct_tree_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT tr.tree_id,
		   tr.name,
		   tr.description,
		   tr.is_template,
		   vr_total_count
	FROM UNNEST(vr_tree_ids) AS x
		INNER JOIN dct_trees AS tr
		ON tr.application_id = vr_application_id AND tr.tree_id = x
	ORDER BY (CASE 
			  	WHEN tr.deleted = TRUE THEN (tr.sequence_number + 1000000)::VARCHAR(100)
			  	ELSE tr.creation_date::VARCHAR(100) 
			  END) ASC;
END;
$$ LANGUAGE plpgsql;
