

DROP PROCEDURE IF EXISTS _sh_add_post;

CREATE OR REPLACE PROCEDURE _sh_add_post 
(
	vr_application_id	UUID,
    vr_share_id 		UUID,
    vr_postType_id      INTEGER,
    vr_description      VARCHAR(4000),
    vr_shared_object_id UUID,
    vr_sender_user_id   UUID,
    vr_send_date		TIMESTAMP,
    vr_owner_id			UUID,
    vr_owner_type		VARCHAR(20),
    vr_has_picture		BOOLEAN,
    vr_privacy          VARCHAR(20),
	INOUT vr_result		INTEGER
)
AS
$$
DECLARE 
	vr_post_id 		UUID;
BEGIN
	vr_description := gfn_verify_string(vr_description);
	vr_post_id := gen_random_uuid();

    INSERT INTO sh_posts (
		application_id,
        post_id,
		post_type_id,
		description,
		shared_object_id,
		sender_user_id,
		send_date,
		has_picture,
		deleted
    )
    VALUES (
		vr_application_id,
        vr_post_id,
        vr_post_type_id,
        vr_description,
        vr_shared_object_id,
        vr_sender_user_id,
        vr_send_date,
        COALESCE(vr_has_picture, FALSE)::BOOLEAN,
        FALSE
    );
    
    INSERT INTO sh_post_shares (
		application_id,
		share_id,
        post_id,
		owner_id,
		sender_user_id,
		send_date,
		score_date,
		privacy,
		deleted,
		owner_type
    )
    VALUES (
		vr_application_id,
		vr_share_id,
        vr_post_id,
        vr_owner_id,
        vr_sender_user_id,
        vr_send_date,
        vr_send_date,
        vr_privacy,
        FALSE,
        vr_owner_type
    );
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	COMMIT;
END;
$$ LANGUAGE plpgsql;



DROP FUNCTION IF EXISTS sh_add_post;

CREATE OR REPLACE FUNCTION sh_add_post 
(
	vr_application_id	UUID,
    vr_share_id 		UUID,
    vr_postType_id      INTEGER,
    vr_description      VARCHAR(4000),
    vr_shared_object_id UUID,
    vr_sender_user_id   UUID,
    vr_send_date		TIMESTAMP,
    vr_owner_id			UUID,
    vr_owner_type		VARCHAR(20),
    vr_has_picture		BOOLEAN,
    vr_privacy          VARCHAR(20)
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result INTEGER = 0;
BEGIN
	CALL _sh_add_post(vr_application_id, vr_share_id, vr_postType_id, vr_description, 
				   vr_shared_object_id, vr_sender_user_id, vr_send_date, vr_owner_id, 
				   vr_owner_type, vr_has_picture, vr_privacy, vr_result);	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

