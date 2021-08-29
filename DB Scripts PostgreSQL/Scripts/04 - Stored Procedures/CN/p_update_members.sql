DROP PROCEDURE IF EXISTS _cn_p_update_members;

CREATE OR REPLACE PROCEDURE _cn_p_update_members
(
	vr_application_id	UUID,
	vr_members			guid_pair_table_type[],
    vr_membership_date	TIMESTAMP,
    vr_is_admin		 	BOOLEAN,
    vr_is_pending		BOOLEAN,
    vr_acception_date	TIMESTAMP,
    vr_position		 	VARCHAR(255),
    vr_deleted		 	BOOLEAN,
	INOUT vr_result		INTEGER
)
AS
$$
DECLARE
	vr_status		VARCHAR(20);
	vr_temp_result	INTEGER = 0;
BEGIN
	IF COALESCE(ARRAY_LENGTH(vr_members, 1), 0) = 0 THEN
		vr_result := -1;
		RETURN;
	END IF;
	
	IF vr_isPending IS NOT NULL THEN
		vr_status = (CASE WHEN vr_is_pending = TRUE THEN 'Pending' ELSE 'Accepted' END);
	END IF;
	
	DROP TABLE IF EXISTS vr_tbl_54296;
		
	CREATE TEMP TABLE vr_tbl_54296 (
		node_id			UUID,
		user_id			UUID,
		membership_date	TIMESTAMP,
		is_admin		BOOLEAN,
		status			VARCHAR(20),
		acception_date 	TIMESTAMP,
		"position"	 	VARCHAR(255),
		deleted		 	BOOLEAN,
		"exists"	 	BOOLEAN,
		unique_id		UUID
	);
	
	INSERT INTO vr_tbl_54296 (
		node_id,
		user_id,
		membership_date,
		is_admin,
		status,
		acception_date,
		"position",
		deleted,
		"exists",
		unique_id
	)
	SELECT	"m".first_value,
			"m".second_value,
			COALESCE(vr_membershipDate, nm.membership_date),
			COALESCE(COALESCE(vr_is_admin, nm.is_admin), FALSE)::BOOLEAN,
			COALESCE(COALESCE(vr_status, nm.status), 'Accepted')::VARCHAR(20),
			COALESCE(vr_acception_date, nm.acception_date),
			COALESCE(vr_position, nm.position)::VARCHAR(255),
			COALESCE(COALESCE(vr_deleted, nm.deleted), FALSE)::BOOLEAN,
			(CASE WHEN nm.node_id IS NULL THEN FALSE ELSE TRUE END)::BOOLEAN AS "exists",
			COALESCE(nm.unique_id, gen_random_uuid()) AS unique_id
	FROM vr_members AS "m"
		LEFT JOIN cn_node_members AS nm
		ON nm.application_id = vr_application_id AND 
			nm.node_id = "m".first_value AND nm.user_id = "m".second_value;
	
	-- Update Existing Data
	UPDATE nm
	SET membership_date = "t".membership_date,
		is_admin = "t".is_admin,
		status = "t".status,
		acception_date = "t".acception_date,
		"position" = "t".position,
		deleted = "t".deleted
	FROM vr_tbl_54296 AS "t"
		INNER JOIN cn_node_members AS nm
		ON nm.application_id = vr_application_id AND 
			nm.node_id = "t".node_id AND nm.user_id = "t".user_id
	WHERE "t".exists = TRUE;
	-- end of Update Existing Data
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	-- Insert New Data
	INSERT INTO cn_node_members(
		application_id,
		node_id,
		user_id,
		membership_date,
		is_admin,
		status,
		acception_date,
		"position",
		deleted,
		unique_id
	)
	SELECT	vr_application_id,
			r.node_id, 
			r.user_id, 
			r.membership_date, 
			r.is_admin, 
			r.status, 
			r.acception_date, 
			r.position, 
			r.deleted,
			r.unique_id
	FROM vr_tbl_54296 AS r
	WHERE r.exists = FALSE;
	-- end of Insert New Data
    
	GET DIAGNOSTICS vr_temp_result := ROW_COUNT;
	
    vr_result := vr_result + vr_temp_result;
	
	COMMIT;
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS cn_p_update_members;

CREATE OR REPLACE FUNCTION cn_p_update_members
(
	vr_application_id	UUID,
	vr_members			guid_pair_table_type[],
    vr_membership_date	TIMESTAMP,
    vr_is_admin		 	BOOLEAN,
    vr_is_pending		BOOLEAN,
    vr_acception_date	TIMESTAMP,
    vr_position		 	VARCHAR(255),
    vr_deleted		 	BOOLEAN
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER = 0;
BEGIN
	CALL _cn_p_update_members(vr_application_id, vr_members, vr_membership_date, vr_is_admin,
							  vr_is_pending, vr_acception_date, vr_position, vr_deleted, vr_result);
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

