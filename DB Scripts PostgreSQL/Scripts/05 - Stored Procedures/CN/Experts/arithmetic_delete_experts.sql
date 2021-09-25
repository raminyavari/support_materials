DROP FUNCTION IF EXISTS cn_arithmetic_delete_experts;

CREATE OR REPLACE FUNCTION cn_arithmetic_delete_experts
(
	vr_application_id	UUID,
    vr_node_id 			UUID,
    vr_user_ids			guid_table_type[]
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE cn_experts
    SET approved = FALSE
	FROM UNNEST(vr_user_ids) AS rf
		INNER JOIN cn_experts AS ex
		ON ex.application_id = vr_application_id AND 
			ex.node_id = vr_node_id AND ex.user_id = rf.value;
			
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
