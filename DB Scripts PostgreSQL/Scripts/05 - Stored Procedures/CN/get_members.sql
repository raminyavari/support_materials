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
	
	DROP TABLE IF EXISTS mm_24968;
	
	CREATE TEMP TABLE mm_24968 (
		node_id		UUID,
		user_id		UUID,
		total_count	INTEGER
	);
	
	IF COALESCE(vr_search_text, N'') = N'' THEN
		INSERT INTO mm_24968 (node_id, user_id, total_count)
		SELECT 	"ref".node_id, 
				"ref".user_id, 
				"ref".row_number + "ref".rev_row_number - 1 AS total_count
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY nm.is_admin DESC, nm.node_id DESC, nm.user_id DESC) AS "row_number",
						ROW_NUMBER() OVER (ORDER BY nm.is_admin ASC, nm.node_id ASC, nm.user_id ASC) AS rev_row_number,
						nm.node_id,
						nm.user_id
				FROM UNNEST(vr_node_ids) AS rf
					INNER JOIN cn_view_node_members AS nm 
					ON nm.node_id = rf.value
				WHERE nm.application_id = vr_application_id AND 
					(vr_is_pending IS NULL OR nm.is_pending = vr_is_pending) AND
					(vr_is_admin IS NULL OR nm.is_admin = vr_is_admin)
			) AS "ref"
		WHERE "ref".row_number >= COALESCE(vr_lower_boundary, 0)
		ORDER BY "ref".row_number ASC
		LIMIT vr_count;
	ELSE
		INSERT INTO mm_24968 (node_id, user_id, total_count)
		SELECT 	"ref".node_id, 
				"ref".user_id, 
				"ref".row_number + "ref".rev_row_number - 1 AS total_count
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY x.rank DESC, nm.node_id DESC, nm.user_id DESC) AS "row_number",
						ROW_NUMBER() OVER (ORDER BY x.rank ASC, nm.node_id ASC, nm.user_id ASC) AS rev_row_number,
						nm.node_id,
						nm.user_id
				FROM UNNEST(vr_node_ids) AS rf
					INNER JOIN cn_view_node_members AS nm 
					ON nm.application_id = vr_application_id AND nm.node_id = rf.value
					INNER JOIN (
						SELECT 	u.user_id,
								(pgroonga_score(u.tableoid, u.ctid)::FLOAT + 
								 	pgroonga_score("p".tableoid, "p".ctid)::FLOAT) AS "rank"
						FROM rv_users AS u
							INNER JOIN usr_profile AS "p"
							ON "p".user_id = u.user_id
						WHERE u.username &@~ vr_search_text OR u.first_name &@~ vr_search_text OR
							u.last_name &@~ vr_search_text
					) AS x
					ON nm.user_id = x.user_id
				WHERE (vr_is_pending IS NULL OR nm.is_pending = vr_is_pending) AND
					(vr_is_admin IS NULL OR nm.is_admin = vr_is_admin)
			) AS "ref"
		WHERE "ref".row_number >= COALESCE(vr_lower_boundary, 0)
		ORDER BY "ref".row_number ASC
		LIMIT vr_count;
	END IF;
	
	SELECT vr_total_count = "m".total_count
	FROM mm_24968 AS "m"
	LIMIT 1;
	
	vr_members := ARRAY(
		SELECT ROW("m".node_id, "m".user_id)
		FROM mm_24968 AS "m"
	);
	
	RETURN QUERY
	SELECT *
	FROM cn_p_get_members(vr_application_id, vr_members, vr_total_count);
END;
$$ LANGUAGE plpgsql;
