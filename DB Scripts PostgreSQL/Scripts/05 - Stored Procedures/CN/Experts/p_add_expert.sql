DROP FUNCTION IF EXISTS cn_p_add_expert;

CREATE OR REPLACE FUNCTION cn_p_add_expert
(
	vr_application_id	UUID,
    vr_node_id 			UUID,
    vr_user_id			UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT vr_user_id
	);
	
	RETURN cn_p_add_experts(vr_application_id, vr_node_id, vr_user_ids);
END;
$$ LANGUAGE plpgsql;
