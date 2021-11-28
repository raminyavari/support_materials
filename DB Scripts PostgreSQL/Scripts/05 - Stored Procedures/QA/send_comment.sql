DROP FUNCTION IF EXISTS qa_send_comment;

CREATE OR REPLACE FUNCTION qa_send_comment
(
	vr_application_id		UUID,
	vr_comment_id	 		UUID,
    vr_owner_id	 			UUID,
    vr_reply_to_comment_id	UUID,
    vr_body_text		 	VARCHAR,
    vr_current_user_id		UUID,
    vr_now			 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
    INSERT INTO qa_comments (
		application_id,
		comment_id,
        owner_id,
        reply_to_comment_id,
        body_text,
        sender_user_id,
        send_date,
        deleted
    )
    VALUES (
		vr_application_id,
		vr_comment_id,
        vr_owner_id,
        vr_reply_to_comment_id,
        gfn_verify_string(vr_body_text),
        vr_current_user_id,
        vr_now,
        FALSE
    );
    
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

