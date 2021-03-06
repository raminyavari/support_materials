DROP FUNCTION IF EXISTS sh_arithmetic_delete_comment;

CREATE OR REPLACE FUNCTION sh_arithmetic_delete_comment
(
	vr_application_id	UUID,
    vr_comment_id	 	UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result 			INTEGER = 0;
BEGIN
    UPDATE sh_comments AS x
	SET deleted = TRUE
	WHERE x.application_id = vr_application_id AND x.comment_id = vr_comment_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

