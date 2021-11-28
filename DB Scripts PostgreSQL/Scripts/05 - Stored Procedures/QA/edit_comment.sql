DROP FUNCTION IF EXISTS qa_edit_comment;

CREATE OR REPLACE FUNCTION qa_edit_comment
(
	vr_application_id		UUID,
	vr_comment_id	 		UUID,
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
	UPDATE qa_comments AS "c"
	SET body_text = gfn_verify_string(vr_body_text),
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE "c".application_id = vr_application_id AND "c".comment_id = vr_comment_id;
    
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

