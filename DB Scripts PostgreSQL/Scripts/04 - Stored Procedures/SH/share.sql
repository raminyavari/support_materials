DROP FUNCTION IF EXISTS sh_share;

CREATE OR REPLACE FUNCTION sh_share 
(
	vr_application_id	UUID,
	vr_shareID			UUID,
	vr_parent_share_id	UUID,
    vr_owner_id			UUID,
    vr_description 		VARCHAR(4000),
    vr_sender_user_id	UUID,
    vr_send_date	 	TIMESTAMP,
    vr_owner_type		VARCHAR(20),
	vr_privacy			VARCHAR(20)
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
	
	vr_post_id := (
		SELECT post_id
		FROM sh_post_shares
		WHERE application_id = vr_application_id AND share_id = vr_parent_share_id
		LIMIT 1
	);

    INSERT INTO sh_post_shares (
		application_id,	
		share_id,
		parent_share_id,
        post_id,
		owner_id,
		description,
		sender_user_id,
		send_date,
		score_date,
		privacy,
		owner_type,
		deleted
    )
    VALUES (
		vr_application_id,
		vr_share_id,
		vr_parent_share_id,
        vr_post_id,
        vr_owner_id,
        vr_description,
        vr_sender_user_id,
        vr_send_date,
        vr_send_date,
        vr_privacy,
        vr_owner_type,
        FALSE
    );
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

