DROP FUNCTION IF EXISTS de_update_experts;

CREATE OR REPLACE FUNCTION de_update_experts
(
	vr_application_id	UUID,
	vr_experts			exchange_member_table_type[],
    vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_x_ids 	guid_pair_table_type[];
BEGIN
	vr_x_ids := ARRAY(
		SELECT	ROW(nd.node_id, un.user_id)
		FROM UNNEST(vr_experts) AS "x"
			INNER JOIN cn_view_nodes_normal AS nd
			ON nd.application_id = vr_application_id AND 
				("x".node_id IS NULL AND nd.type_additional_id = "x".node_type_additional_id AND
				nd.node_additional_id = "x".node_additional_id) OR
				("x".node_id IS NOT NULL AND nd.node_id = "x".node_id)
			LEFT JOIN cn_services AS s
			ON s.application_id = vr_application_id AND s.node_type_id = nd.node_type_id
			INNER JOIN users_normal AS un
			ON un.application_id = vr_application_id AND LOWER(un.username) = LOWER("x".username)
		GROUP BY nd.node_id, un.user_id
	);
	
	UPDATE cn_experts
	SET approved = TRUE
	FROM UNNEST(vr_x_ids) AS x
		INNER JOIN cn_experts AS ex
		ON ex.application_id = vr_application_id AND
			ex.node_id = x.first_value AND ex.user_id = x.second_value;
	
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
	SELECT	vr_application_id,
			x.first_value,
			x.second_value,
			TRUE,
			0::INTEGER,
			0::FLOAT,
			FALSE,
			gen_random_uuid()
	FROM UNNEST(vr_x_ids) AS x
		LEFT JOIN cn_experts AS ex
		ON ex.application_id = vr_application_id AND
			ex.node_id = x.first_value AND ex.user_id = x.second_value
	WHERE ex.node_id IS NULL;
	
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

