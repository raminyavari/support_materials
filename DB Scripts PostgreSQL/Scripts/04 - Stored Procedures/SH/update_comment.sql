
DROP FUNCTION IF EXISTS sh_update_comment;

CREATE OR REPLACE FUNCTION sh_update_comment
(
	vr_application_id	UUID,
    vr_comment_id		UUID,
	vr_description		VARCHAR(4000),
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result 	INTEGER = 0;
BEGIN
	vr_description := gfn_verify_string(vr_description);
	
	UPDATE sh_comments
		SET description = vr_description,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
	WHERE application_id = vr_application_id AND comment_id = vr_comment_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

