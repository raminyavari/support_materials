DROP FUNCTION IF EXISTS cn_p_add_experts;

CREATE OR REPLACE FUNCTION cn_p_add_experts
(
	vr_application_id	UUID,
    vr_node_id 			UUID,
    vr_user_ids			UUID[]
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_upd_result	INTEGER;
	vr_ins_result	INTEGER;
BEGIN
	UPDATE cn_experts
	SET approved = TRUE
	FROM UNNEST(vr_user_ids) AS rf
		INNER JOIN cn_experts AS ex
		ON ex.user_id = rf AND ex.application_id = vr_application_id AND ex.node_id = vr_node_id;
		
	GET DIAGNOSTICS vr_upd_result := ROW_COUNT;
	
	INSERT INTO cn_experts (
		application_id,
		node_id,
		user_id,
		approved,
		referrals_count,
		confirms_percentage,
		social_approved,
		unique_id
	)
	SELECT vr_application_id, vr_node_id, rf, TRUE, 0, 0::FLOAT, FALSE, gen_random_uuid()
	FROM UNNEST(vr_user_ids) AS rf
		LEFT JOIN cn_experts AS ex
		ON ex.user_id = rf AND ex.application_id = vr_application_id AND ex.node_id = vr_node_id
	WHERE ex.node_id IS NULL;

	GET DIAGNOSTICS vr_ins_result := ROW_COUNT;

	RETURN vr_upd_result + vr_ins_result;
END;
$$ LANGUAGE plpgsql;
