DROP FUNCTION IF EXISTS cn_set_member_position;

CREATE OR REPLACE FUNCTION cn_set_member_position
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_user_id			UUID,
    vr_position	 		VARCHAR(255)
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER = 0;
BEGIN
	vr_result := cn_p_update_member(vr_application_id, vr_node_id, vr_user_id, 
									NULL, NULL, NULL, NULL, vr_position, NULL);
	
	IF vr_result <= 0 THEN
		CALL gfn_raise_exception();
		RETURN -1;
    END IF;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

