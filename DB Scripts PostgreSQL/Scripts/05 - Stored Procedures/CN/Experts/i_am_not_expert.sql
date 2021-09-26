DROP FUNCTION IF EXISTS cn_i_am_not_expert;

CREATE OR REPLACE FUNCTION cn_i_am_not_expert
(
	vr_application_id	UUID,
	vr_user_id			UUID,
	vr_node_id			UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE cn_experts AS ex
	SET social_approved = NULL
	WHERE ex.application_id = vr_application_id AND 
		ex.node_id = vr_node_id AND ex.user_id = vr_user_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
