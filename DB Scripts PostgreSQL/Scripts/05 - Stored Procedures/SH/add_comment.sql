DROP FUNCTION IF EXISTS sh_add_comment;

CREATE OR REPLACE FUNCTION sh_add_comment
(
	vr_application_id	UUID,
	vr_comment_id		UUID,
    vr_share_id			UUID,
	vr_description 		VARCHAR(4000),
	vr_sender_user_id	UUID,
	vr_send_date	 	TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result 			INTEGER = 0;
BEGIN
	vr_description := gfn_verify_string(vr_description);
	
	INSERT INTO sh_comments (
		application_id,
		comment_id,
		share_id,
        description,
		sender_user_id,
		send_date,
		deleted
    )
    VALUES (
		vr_application_id,
		vr_comment_id,
		vr_share_id,
		vr_description,
        vr_sender_user_id,
        vr_send_date,
        FALSE
    );
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

