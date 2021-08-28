
DROP FUNCTION IF EXISTS sh_get_post_fan_ids;

CREATE OR REPLACE FUNCTION sh_get_post_fan_ids
(
	vr_application_id	UUID,
    vr_share_id			UUID,
    vr_like_status	 	BOOLEAN,
    vr_count		 	INTEGER,
    vr_lower_boundary	BIGINT
)
RETURNS TABLE (
	"order"		INTEGER,
	total_count	INTEGER,
	user_id		UUID
)
AS
$$
BEGIN
	IF COALESCE(vr_count, 0) <= 0 THEN 
		vr_count := 1000000;
	END IF;

	RETURN QUERY
	SELECT	"ref".row_number AS "order",
			("ref".row_number + "ref".rev_row_number - 1) AS total_count,
			"ref".user_id AS user_id
	FROM (
			SELECT	ROW_NUMBER() OVER (ORDER BY sl.date DESC) AS "row_number",
					ROW_NUMBER() OVER (ORDER BY sl.date ASC) AS rev_row_number,
					sl.user_id
			FROM sh_share_likes AS sl
			WHERE sl.application_id = vr_application_id AND sl.share_id = vr_share_id AND 
				COALESCE(sl.like, FALSE)::BOOLEAN = COALESCE(vr_like_status, FALSE)::BOOLEAN
		) AS "ref"
	WHERE "ref".row_number >= COALESCE(vr_lower_boundary, 0)::INTEGER
	LIMIT vr_count;
END;
$$ LANGUAGE plpgsql;

