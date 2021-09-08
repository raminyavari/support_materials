DROP FUNCTION IF EXISTS sh_get_user_posts_count;

CREATE OR REPLACE FUNCTION sh_get_user_posts_count
(
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_post_type_id	 	INTEGER
)
RETURNS INTEGER
AS
$$
BEGIN
	IF COALESCE(vr_post_type_id, 0)::INTEGER = 0 THEN
		RETURN (
			SELECT COUNT(*)
			FROM sh_post_shares AS x
			WHERE x.application_id = vr_application_id AND x.sender_user_id = vr_user_id AND x.deleted = FALSE
		);	
	ELSE
		RETURN (
			SELECT COUNT(*)
			FROM sh_post_shares AS ps
				INNER JOIN sh_posts  AS "p"
				ON "p".application_id = vr_application_id AND "p".post_id = ps.post_id
			WHERE ps.application_id = vr_application_id AND ps.sender_user_id = vr_user_id AND 
				ps.deleted = FALSE AND "p".post_type_id = vr_post_type_id
		);
	END IF;
END;
$$ LANGUAGE plpgsql;

