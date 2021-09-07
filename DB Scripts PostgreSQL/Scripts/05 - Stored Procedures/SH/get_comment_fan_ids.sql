DROP FUNCTION IF EXISTS sh_get_comment_fan_ids;

CREATE OR REPLACE FUNCTION sh_get_comment_fan_ids
(
	vr_application_id	UUID,
    vr_comment_id		UUID,
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
			SELECT	ROW_NUMBER() OVER (ORDER BY cl.date DESC) AS "row_number",
					ROW_NUMBER() OVER (ORDER BY cl.date ASC) AS rev_row_number,
					cl.user_id
			FROM sh_comment_likes AS cl
			WHERE cl.application_id = vr_application_id AND cl.comment_id = vr_comment_id AND 
				COALESCE(cl.like, FALSE)::BOOLEAN = COALESCE(vr_like_status, FALSE)::BOOLEAN
		) AS "ref"
	WHERE "ref".row_number >= COALESCE(vr_lower_boundary, 0)::INTEGER
	LIMIT vr_count;
END;
$$ LANGUAGE plpgsql;

