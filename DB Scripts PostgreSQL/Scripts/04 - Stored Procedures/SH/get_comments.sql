
DROP FUNCTION IF EXISTS sh_get_comments;

CREATE OR REPLACE FUNCTION sh_get_comments
(
	vr_application_id	UUID,
    vr_share_ids		guid_table_type[],
    vr_user_id	 		UUID
)
RETURNS SETOF sh_comment_ret_composite
AS
$$
DECLARE
	vr_comment_ids 	UUID[];
BEGIN
	vr_comment_ids := ARRAY(
		SELECT "c".comment_id
		FROM UNNEST(vr_share_ids) AS ex
			INNER JOIN sh_comments AS "c"
			ON "c".share_id = ex.value
		WHERE "c".application_id = vr_application_id AND "c".deleted = FALSE
	);

	RETURN QUERY
	SELECT *
	FROM sh_p_get_comments_by_ids(vr_application_id, vr_comment_ids, vr_user_id);
END;
$$ LANGUAGE plpgsql;

