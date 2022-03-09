DROP FUNCTION IF EXISTS ntfn_p_dashboard_exists;

CREATE OR REPLACE FUNCTION ntfn_p_dashboard_exists
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
	RETURN COALESCE((
		SELECT 1
		FROM ntfn_dashboards AS d
		WHERE d.application_id = vr_application_id AND 
			(vr_user_id IS NULL OR d.user_id = vr_user_id) AND
			(vr_node_id IS NULL OR d.node_id = vr_node_id) AND
			(vr_dashboard_type IS NULL OR d.type = vr_dashboard_type) AND
			(vr_subtype IS NULL OR d.subtype = vr_subtype) AND
			(vr_seen IS NULL OR d.seen = vr_seen) AND
			(vr_done IS NULL OR d.done = vr_done) AND
			(vr_lower_date_limit IS NULL OR d.send_date >= vr_lower_date_limit) AND
			(vr_upper_date_limit IS NULL OR d.send_date <= vr_upper_date_limit) AND 
			d.deleted = FALSE
		LIMIT 1
	), -1)::INTEGER;
END;
$$ LANGUAGE plpgsql;

