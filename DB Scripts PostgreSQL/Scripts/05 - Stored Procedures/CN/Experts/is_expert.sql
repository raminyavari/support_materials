DROP FUNCTION IF EXISTS cn_is_expert;

CREATE OR REPLACE FUNCTION cn_is_expert
(
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_node_id			UUID,
    vr_approved	 		BOOLEAN,
    vr_social_approved 	BOOLEAN
)
RETURNS BOOLEAN
AS
$$
BEGIN
	RETURN COALESCE((
		SELECT TRUE 
		FROM cn_experts AS ex
		WHERE ex.application_id = vr_application_id AND 
			((vr_approved = TRUE AND ex.approved = TRUE) OR 
			(vr_social_approved = TRUE AND ex.social_approved = TRUE)) AND
			ex.user_id = vr_user_id AND ex.node_id = vr_node_id
		LIMIT 1
	), FALSE)::BOOLEAN;
END;
$$ LANGUAGE plpgsql;
