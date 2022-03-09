DROP FUNCTION IF EXISTS ntfn_dashboard_exists;

CREATE OR REPLACE FUNCTION ntfn_dashboard_exists
(
	vr_application_id	UUID,
	vr_user_id			UUID,
	vr_node_id			UUID,
	vr_dashboard_type	VARCHAR(20),
	vr_subtype			VARCHAR(20),
	vr_seen			 	BOOLEAN,
	vr_done			 	BOOLEAN,
	vr_lower_date_limit	TIMESTAMP,
	vr_upper_date_limit	TIMESTAMP
)
RETURNS INTEGER
AS
$$
BEGIN
	RETURN ntfn_p_dashboard_exists(vr_application_id, vr_user_id, vr_node_id, vr_dashboard_type, 
								   vr_subtype, vr_seen, vr_done, vr_lower_date_limit, vr_upper_date_limit);
END;
$$ LANGUAGE plpgsql;

