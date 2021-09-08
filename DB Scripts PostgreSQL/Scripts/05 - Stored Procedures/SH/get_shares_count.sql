DROP FUNCTION IF EXISTS sh_get_shares_count;

CREATE OR REPLACE FUNCTION sh_get_shares_count
(
	vr_application_id	UUID,
    vr_share_id			UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_post_id	UUID;
BEGIN
	vr_post_id := (
		SELECT x.post_id
		FROM sh_post_shares AS x
		WHERE x.application_id = vr_application_id AND x.share_id = vr_share_id
		LIMIT 1
	);

	RETURN (
		SELECT COUNT(*)
		FROM sh_post_shares AS x
		WHERE x.application_id = vr_application_id AND x.post_id = vr_post_id AND x.deleted = FALSE
	);	
END;
$$ LANGUAGE plpgsql;

