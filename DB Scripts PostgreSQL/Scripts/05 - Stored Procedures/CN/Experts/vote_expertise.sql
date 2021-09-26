DROP FUNCTION IF EXISTS cn_vote_expertise;

CREATE OR REPLACE FUNCTION cn_vote_expertise
(
	vr_application_id								UUID,
	vr_referrer_user_id								UUID,
	vr_node_id										UUID,
	vr_user_id										UUID,
	vr_status								 		BOOLEAN,
	vr_send_date							 		TIMESTAMP,
	vr_default_min_acceptable_referrals_count	 	INTEGER,
	vr_default_min_acceptable_confirms_percentage	INTEGER
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF EXISTS(
		SELECT * 
		FROM cn_expertise_referrals AS ex
		WHERE ex.application_id = vr_application_id AND ex.referrer_user_id = vr_referrer_user_id AND 
			ex.node_id = vr_node_id AND ex.user_id = vr_user_id
		LIMIT 1
	) THEN
		UPDATE cn_expertise_referrals AS ex
			SET status = vr_status,
				send_date = vr_send_date
		WHERE ex.application_id = vr_application_id AND ex.referrer_user_id = vr_referrer_user_id AND 
			ex.node_id = vr_node_id AND ex.user_id = vr_user_id;
	ELSE
		INSERT INTO cn_expertise_referrals (
			application_id,
			referrer_user_id,
			node_id,
			user_id,
			status,
			send_date
		)
		VALUES(
			vr_application_id,
			vr_referrer_user_id,
			vr_node_id,
			vr_user_id,
			vr_status,
			vr_send_date
		);
	END IF;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	IF vr_result <= 0 THEN
		CALL gfn_raise_exception();
		RETURN -1;
	END IF;
	
	vr_result := cn_p_calculate_social_expertise(vr_application_id, vr_node_id, vr_user_id, 
		vr_default_min_acceptable_referrals_count, vr_default_min_acceptable_confirms_percentage);
		
	IF vr_result <= 0 THEN
		CALL gfn_raise_exception();
		RETURN -1;
	END IF;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
