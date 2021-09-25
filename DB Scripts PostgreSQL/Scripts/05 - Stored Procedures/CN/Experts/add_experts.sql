DROP FUNCTION IF EXISTS cn_add_experts;

CREATE OR REPLACE FUNCTION cn_add_experts
(
	vr_application_id	UUID,
    vr_node_id 			UUID,
    vr_user_ids			guid_table_type[]
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT x.value
		FROM UNNEST(vr_user_ids) AS x
	);
	
	RETURN cn_p_add_experts(vr_application_id, vr_node_id, vr_user_ids);
END;
$$ LANGUAGE plpgsql;
