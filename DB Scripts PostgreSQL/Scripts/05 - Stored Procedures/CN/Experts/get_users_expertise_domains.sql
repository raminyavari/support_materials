DROP FUNCTION IF EXISTS cn_get_users_expertise_domains;

CREATE OR REPLACE FUNCTION cn_get_users_expertise_domains
(
	vr_application_id	UUID,
    vr_user_ids			guid_table_type[],
    vr_node_type_id		UUID,
    vr_approved	 		BOOLEAN,
    vr_social_approved 	BOOLEAN,
    vr_all		 		BOOLEAN
)
RETURNS TABLE (
	node_id				UUID,
	node_additional_id	VARCHAR,
	node_name			VARCHAR,
	node_type_id		UUID,
	node_type			VARCHAR,
	expert_user_id		UUID,
	expert_username		VARCHAR,
	expert_first_name	VARCHAR,
	expert_last_name	VARCHAR,
	approved			BOOLEAN,
	social_approved		BOOLEAN,
	referrals_count		INTEGER,
	confirms_percentage	FLOAT
)
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT x.value
		FROM UNNEST(vr_user_ids) AS x
	);

	RETURN QUERY
	SELECT *
	FROM cn_p_get_users_expertise_domains(vr_application_id, 
		vr_ids, vr_node_type_id, vr_approved, vr_social_approved, vr_all);
END;
$$ LANGUAGE plpgsql;
