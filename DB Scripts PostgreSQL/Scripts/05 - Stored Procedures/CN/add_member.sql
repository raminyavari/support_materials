DROP FUNCTION IF EXISTS cn_add_member;

CREATE OR REPLACE FUNCTION cn_add_member
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_user_id			UUID,
    vr_membership_date	TIMESTAMP,
    vr_is_admin		 	BOOLEAN,
    vr_is_pending		BOOLEAN,
    vr_acception_date	TIMESTAMP,
    vr_position		 	VARCHAR(255)
)
RETURNS SETOF REFCURSOR
AS
$$
DECLARE
	vr_result		INTEGER = 0;
	vr_dashboards	dashboard_table_type[];
	vr_admin_ids	UUID[];
	vr_ref_val		REFCURSOR;
	vr_ref_dash		REFCURSOR;
BEGIN
	vr_result := cn_p_add_member(vr_application_id, vr_node_id, vr_user_id, vr_membership_date, 
								 vr_is_admin, vr_is_pending, vr_acception_date, vr_position);
	
	IF vr_result <= 0 THEN
		CALL gfn_raise_exception();
		RETURN;
	END IF;
	
	-- Send new dashboards
	IF vr_is_pending = TRUE THEN
		vr_admin_ids := ARRAY(
			SELECT nm.user_id
			FROM cn_view_node_members AS nm
			WHERE nm.application_id = vr_application_id AND nm.node_id = vr_node_id AND 
				nm.is_admin = TRUE AND nm.is_pending = FALSE AND nm.user_id <> vr_user_id
		);
	
		DROP TABLE IF EXISTS vr_dash_08470;
	
		CREATE TEMP TABLE vr_dash_08470 OF dashboard_table_type;
	
		INSERT INTO vr_dash_08470 (user_id, node_id, ref_item_id, "type", removable, send_date)
		SELECT	x, 
				vr_node_id,
				vr_user_id,
				'MembershipRequest',
				FALSE,
				vr_membership_date
		FROM UNNEST(vr_admin_ids) AS x;
		
		vr_dashboards := ARRAY(
			SELECT x
			FROM vr_dash_08470 AS x
		);
		
		vr_result := ntfn_p_send_dashboards(vr_application_id, vr_dashboards);
		
		IF vr_result <= 0 THEN
			CALL gfn_raise_exception();
			RETURN;
		ELSE
			OPEN vr_ref_val FOR
			SELECT vr_result;
			RETURN NEXT vr_ref_val;
		
			OPEN vr_ref_dash FOR
			SELECT * 
			FROM vr_dashboards;
			RETURN NEXT vr_ref_dash;
		END IF;
	ELSE 
		OPEN vr_ref_val FOR
		SELECT vr_result;
		RETURN NEXT vr_ref_val;
	END IF;
	-- end of send new dashboards;
END;
$$ LANGUAGE plpgsql;
