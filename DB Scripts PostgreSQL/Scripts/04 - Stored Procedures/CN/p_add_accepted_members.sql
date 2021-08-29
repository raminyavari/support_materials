DROP PROCEDURE IF EXISTS _cn_p_add_accepted_members;

CREATE OR REPLACE PROCEDURE _cn_p_add_accepted_members
(
	vr_application_id	UUID,
	vr_members			guid_pair_table_type[],
    vr_now		 		TIMESTAMP,
	INOUT vr_result		INTEGER
)
AS
$$
DECLARE
	vr_status		VARCHAR(20) = 'Accepted';
	vr_temp_result	INTEGER = 0;
BEGIN
	IF COALESCE(ARRAY_LENGTH(vr_members, 1), 0) = 0 THEN
		vr_result := -1;
		RETURN;
	END IF;
	
	DROP TABLE IF EXISTS vr_tbl_63464;

	CREATE TEMP TABLE vr_tbl_63464 (
		node_id				UUID,
		user_id				UUID,
		node_type_id		UUID,
		unique_membership	BOOLEAN
	);
	
	INSERT INTO vr_tbl_63464 (node_id, user_id, node_type_id, unique_membership)
	SELECT nd.node_id, "m".second_value, nd.node_type_id, COALESCE(s.unique_membership, FALSE)::BOOLEAN
	FROM UNNEST(vr_members) AS "m"
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = "m".first_value
		LEFT JOIN cn_services AS s
		ON s.application_id = vr_application_id AND s.node_type_id = nd.node_type_id;
	
	-- Remove existing members with UniqueMembership enabled
	UPDATE nm
	SET deleted = TRUE
	FROM (
			SELECT "t".user_id, "t".node_type_id
			FROM vr_tbl_63464 AS "t"
			WHERE "t".unique_membership = TRUE
			GROUP BY "t".user_id, "t".node_type_id
		) AS x
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_type_id = x.node_type_id
		INNER JOIN cn_node_members AS nm
		ON nm.application_id = vr_application_id AND 
			nm.node_id = nd.node_id AND nm.user_id = x.user_id;
	-- end of Remove existing members with UniqueMembership enabled
	
	-- Update existing items
	UPDATE NM
	SET deleted = FALSE,
		status = vr_status,
		acception_date = COALESCE(acception_date, vr_now)::TIMESTAMP,
		is_admin = CASE WHEN deleted = TRUE THEN FALSE ELSE is_admin END,
		membership_date = COALESCE(membership_date, vr_now)::TIMESTAMP
	FROM vr_tbl_63464 AS "t"
		INNER JOIN cn_node_members AS nm
		ON nm.application_id = vr_application_id AND 
			nm.node_id = "t".node_id AND nm.user_id = "t".user_id;
	-- end of Update existing items
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	-- Insert New Items
	INSERT INTO cn_node_members(
		application_id,
		node_id,
		user_id,
		membership_date,
		is_admin,
		status,
		acception_date,
		deleted,
		unique_id
	)
	SELECT vr_application_id, "t".node_id, "t".user_id, vr_now, FALSE, vr_status, vr_now, FALSE, gen_random_uuid()
	FROM vr_tbl_63464 AS "t"
		LEFT JOIN cn_node_members AS nm
		ON nm.application_id = vr_application_id AND 
			nm.node_id = "t".node_id AND nm.user_id = "t".user_id
	WHERE nm.node_id IS NULL;
	-- end of Insert New Items
    
	GET DIAGNOSTICS vr_temp_result := ROW_COUNT;
	
    vr_result := vr_result + vr_temp_result;
	
	COMMIT;
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS cn_p_add_accepted_members;

CREATE OR REPLACE FUNCTION cn_p_add_accepted_members
(
	vr_application_id	UUID,
	vr_members			guid_pair_table_type[],
    vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER = 0;
BEGIN
	CALL _cn_p_add_accepted_members(vr_application_id, vr_members, vr_now, vr_result);
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

