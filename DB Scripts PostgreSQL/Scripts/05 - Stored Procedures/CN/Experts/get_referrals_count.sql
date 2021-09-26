DROP FUNCTION IF EXISTS cn_get_referrals_count;

CREATE OR REPLACE FUNCTION cn_get_referrals_count
(
	vr_application_id	UUID,
	vr_user_id			UUID,
	vr_node_id			UUID
)
RETURNS INTEGER
AS
$$
BEGIN
	RETURN COALESCE((
		SELECT ex.referrals_count
		FROM cn_experts AS ex
		WHERE ex.application_id = vr_application_id AND 
			ex.node_id = vr_node_id AND ex.user_id = vr_user_id
		LIMIT 1
	), 0)::INTEGER;
END;
$$ LANGUAGE plpgsql;
