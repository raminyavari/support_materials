
DROP FUNCTION IF EXISTS sh_arithmetic_delete_post;

CREATE OR REPLACE FUNCTION sh_arithmetic_delete_post 
(
	vr_application_id	UUID,
    vr_share_id	 		UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result 			INTEGER = 0;
BEGIN
    UPDATE sh_post_shares
	SET deleted = TRUE
	WHERE application_id = vr_application_id AND share_id = vr_share_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

