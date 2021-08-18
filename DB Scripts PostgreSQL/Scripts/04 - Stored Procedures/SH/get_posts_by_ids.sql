
DROP FUNCTION IF EXISTS sh_get_posts_by_ids;

CREATE OR REPLACE FUNCTION sh_get_posts_by_ids 
(
	vr_application_id	UUID,
    vr_share_ids		guid_table_type[],
    vr_user_id			UUID
)
RETURNS SETOF sh_post_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT (UNNEST(vr_share_ids)).value
	);

	RETURN QUERY
	SELECT *
	FROM sh_p_get_posts_by_ids(vr_application_id, vr_ids, vr_user_id);
END;
$$ LANGUAGE plpgsql;

