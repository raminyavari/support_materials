DROP FUNCTION IF EXISTS sh_update_post;

CREATE OR REPLACE FUNCTION sh_update_post 
(
	vr_application_id	UUID,
    vr_share_id			UUID,
	vr_description		VARCHAR(4000),
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_parent_share_id	UUID;
    vr_post_id 			UUID;
	vr_result 			INTEGER = 0;
BEGIN
	vr_description := gfn_verify_string(vr_description);
	
	DROP TABLE IF EXISTS tmp_45298;
	
	-- Create a temp table TO store the select results
    CREATE TEMP TABLE tmp_45298
    (
        share_id 		UUID NOT NULL,
        parent_share_id UUID NULL,
        post_id 		UUID NOT NULL
    );
    
    INSERT INTO tmp_45298
    SELECT ps.share_id, ps.parent_share_id, ps.post_id
    FROM sh_post_shares AS ps
    WHERE ps.application_id = vr_application_id AND ps.share_id = vr_shareID;
    
	SELECT 	vr_parent_share_id = x.parent_share_id,
			vr_post_id = x.post_id
	FROM tmp_45298 AS x;
	
	IF vr_parent_share_id IS NULL OR vr_parent_share_id = vr_share_id THEN
		UPDATE sh_posts AS x
		SET description = vr_description,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
		WHERE x.application_id = vr_application_id AND x.post_id = vr_post_id;
	ELSE
		UPDATE sh_post_shares AS x
		SET description = vr_description,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
		WHERE x.application_id = vr_application_id AND x.share_id = vr_share_id;
	END IF;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

