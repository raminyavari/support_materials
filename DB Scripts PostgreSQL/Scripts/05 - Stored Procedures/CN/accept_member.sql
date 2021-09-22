DROP FUNCTION IF EXISTS cn_accept_member;

CREATE OR REPLACE FUNCTION cn_accept_member
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_user_id			UUID,
    vr_acception_date 	TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER = 0;
BEGIN
	vr_result := cn_p_update_member(vr_application_id, vr_node_id, vr_user_id, 
									NULL, NULL, FALSE, vr_acception_date, NULL, NULL);
	
    IF vr_result <= 0 THEN
		CALL gfn_raise_exception();
		RETURN -1;
    END IF;
    
	vr_result := ntfn_p_arithmetic_delete_dashboards(vr_application_id, NULL, vr_node_id, 
													 vr_user_id, 'MembershipRequest', NULL);

	IF vr_result <= 0 THEN
		CALL gfn_raise_exception();
		RETURN -1;
    END IF;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

