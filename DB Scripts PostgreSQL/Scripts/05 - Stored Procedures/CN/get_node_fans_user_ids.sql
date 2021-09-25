DROP FUNCTION IF EXISTS cn_get_node_fans_user_ids;

CREATE OR REPLACE FUNCTION cn_get_node_fans_user_ids
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_count		 	INTEGER,
    vr_lower_boundary	BIGINT
)
RETURNS SETOF UUID
AS
$$
BEGIN
	IF COALESCE(vr_count, 0) <= 0 THEN 
		vr_count = 1000000;
	END IF;
	
	RETURN QUERY
	WITH "data" AS (
		SELECT	ROW_NUMBER() OVER (ORDER BY nl.like_date DESC, nl.user_id DESC) AS "row_number",
				nl.user_id
		FROM cn_node_likes AS nl
		WHERE nl.application_id = vr_application_id AND nl.node_id = vr_node_id AND nl.deleted = FALSE
	),
	total AS (
		SELECT COUNT(d.user_id) AS total_count
		FROM "data" AS d
	)
	SELECT	d.row_number AS "order",
			"t".total_count,
			d.user_id
	FROM "data" AS d
		CROSS JOIN total AS "t"
	WHERE d.row_number >= COALESCE(vr_lower_boundary, 0)
	ORDER BY d.row_number ASC
	LIMIT vr_count;
END;
$$ LANGUAGE plpgsql;
