DROP FUNCTION IF EXISTS cn_get_members;

CREATE OR REPLACE FUNCTION cn_get_members
(
	vr_application_id	UUID,
    vr_node_ids			guid_table_type[],
    vr_is_pending	 	BOOLEAN,
    vr_is_admin	 		BOOLEAN,
    vr_search_text	 	VARCHAR(255),
    vr_count		 	INTEGER,
    vr_lower_boundary	BIGINT
)
RETURNS SETOF cn_member_ret_composite
AS
$$
DECLARE
	vr_members		guid_pair_table_type[];
	vr_total_count	INTEGER;
BEGIN
	IF COALESCE(vr_count, 0) <= 0 THEN 
		vr_count := 1000000;
	END IF;
	
	IF vr_is_pending = TRUE THEN
		vr_is_admin := NULL;
	END IF;
	
	WITH "data" AS (
		SELECT	ROW_NUMBER() OVER (
					ORDER BY	pgroonga_score("p".tableoid, "p".ctid) DESC, 
								nm.is_admin DESC, 
								nm.node_id DESC, 
								nm.user_id DESC
				) AS "row_number",
				nm.node_id,
				nm.user_id
		FROM UNNEST(vr_node_ids) AS rf
			INNER JOIN cn_view_node_members AS nm 
			ON nm.application_id = vr_application_id AND nm.node_id = rf.value AND
				(vr_is_pending IS NULL OR nm.is_pending = vr_is_pending) AND
				(vr_is_admin IS NULL OR nm.is_admin = vr_is_admin)
			INNER JOIN usr_profile AS "p"
			ON "p".user_id = nm.user_id AND (
					COALESCE(vr_search_text, '') = '' OR "p".username &@~ vr_search_text OR 
					"p".first_name &@~ vr_search_text OR "p".last_name &@~ vr_search_text
				)
	)
	SELECT 	vr_members = ARRAY(
				SELECT ROW(d.node_id, d.user_id)
				FROM "data" AS d
				WHERE d.row_number >= COALESCE(vr_lower_boundary, 0)
				ORDER BY d.row_number ASC
				LIMIT vr_count
			),
			vr_total_count = COALESCE((
				SELECT COUNT(d.node_id)
				FROM "data" AS d
			), 0)::INTEGER;
	
	RETURN QUERY
	SELECT *
	FROM cn_p_get_members(vr_application_id, vr_members, vr_total_count);
END;
$$ LANGUAGE plpgsql;
