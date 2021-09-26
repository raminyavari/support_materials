DROP FUNCTION IF EXISTS cn_p_calculate_social_expertise;

CREATE OR REPLACE FUNCTION cn_p_calculate_social_expertise
(
	vr_application_id								UUID,
	vr_node_id										UUID,
	vr_user_id										UUID,
	vr_default_min_acceptable_referrals_count	 	INTEGER,
	vr_default_min_acceptable_confirms_percentage	INTEGER
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_referrals_count		INTEGER;
	vr_confirms_percentage 	FLOAT;
	vr_social_approved 		BOOLEAN DEFAULT FALSE;
	vr_result				INTEGER;
BEGIN
	SELECT vr_referrals_count = COUNT(*)
	FROM cn_expertise_referrals AS ex
	WHERE ex.application_id = vr_application_id AND ex.node_id = vr_node_id AND 
		ex.user_id = vr_user_id AND ex.status IS NOT NULL;
	
	SELECT vr_confirms_percentage = (
			CASE
				WHEN vr_referrals_count = 0 THEN 0::FLOAT
				ELSE (COUNT(*)::FLOAT / vr_referrals_count::FLOAT) * 100 
			END
		)
	FROM cn_expertise_referrals AS ex
	WHERE ex.application_id = vr_application_id AND 
		ex.node_id = vr_node_id AND ex.user_id = vr_user_id AND ex.status = TRUE;
	
	IF vr_referrals_count >= vr_default_min_acceptable_referrals_count AND
		vr_confirms_percentage >= vr_default_min_acceptable_confirms_percentage THEN
		vr_social_approved := TRUE;
	END IF;
		
	UPDATE cn_experts AS ex
	SET referrals_count = vr_referrals_count,
		confirms_percentage = vr_confirms_percentage,
		social_approved = vr_social_approved
	WHERE ex.application_id = vr_application_id AND 
		ex.node_id = vr_node_id AND ex.user_id = vr_user_id;
		
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
