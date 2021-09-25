DROP FUNCTION IF EXISTS cn_get_lists;

CREATE OR REPLACE FUNCTION cn_get_lists
(
	vr_application_id			UUID,
	vr_node_type_id				UUID,
	vr_node_type_additional_id	VARCHAR(50),
    vr_search_text			 	VARCHAR(1000),
    vr_count				 	INTEGER,
    vr_min_id					UUID
)
RETURNS SETOF cn_list_ret_composite
AS
$$
DECLARE
	vr_ret_ids		UUID[];
	vr_total_count	INTEGER;
BEGIN
	vr_search_text := gfn_verify_string(vr_search_text);
	
	IF vr_node_type_id IS NULL AND vr_node_type_additional_id IS NOT NULL THEN
		vr_node_type_id := (
			SELECT nt.node_type_id 
			FROM cn_node_types AS nt
			WHERE nt.application_id = vr_application_id AND nt.additional_id = vr_node_type_additional_id
			LIMIT 1
		);
	END IF;

	IF vr_count IS NULL OR vr_count <= 0 THEN
		vr_count := 1000;
	END IF;
	
	WITH "data" AS (
		SELECT 	ROW_NUMBER() OVER (ORDER BY ls.list_id ASC) AS "row_number",
				ls.list_id 
		FROM cn_lists AS ls
		WHERE ls.application_id = vr_application_id AND 
			(vr_node_type_id IS NULL OR ls.node_type_id = vr_node_type_id) AND 
			(COALESCE(vr_search_text, '') = '' OR ls.name &@~ vr_search_text) AND
			ls.deleted = FALSE
	),
	total AS (
		SELECT COUNT(d.list_id) AS total_count
		FROM "data" AS d
	),
	last_item AS (
		SELECT d.row_number AS pos
		FROM "data" AS d
		WHERE d.list_id = vr_min_id
		LIMIT 1
	)
	SELECT 	vr_ret_ids = ARRAY(
				SELECT d.list_id 
				FROM "data" AS d
				WHERE d.row_number > COALESCE((SELECT MAX(x.pos) FROM last_item AS x), 0)
				ORDER BY d.row_number ASC
				LIMIT vr_count
			),
			vr_total_count = COALESCE((
				SELECT MAX("t".total_count)
				FROM total AS "t"
			), 0)::INTEGER;
	
	RETURN QUERY
	SELECT *
	FROM cn_p_get_lists_by_ids(vr_application_id, vr_list_ids, vr_total_count);
END;
$$ LANGUAGE plpgsql;
