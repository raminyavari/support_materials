DROP FUNCTION IF EXISTS ntfn_p_send_dashboards;

CREATE OR REPLACE FUNCTION ntfn_p_send_dashboards
(
	vr_application_id	UUID,
	vr_dashboards		dashboard_table_type[]
)
RETURNS INTEGER
AS
$$
BEGIN
	INSERT INTO ntfn_dashboards (
		application_id,
		user_id,
		node_id,
		ref_item_id,
		"type",
		subtype,
		"info",
		removable,
		sender_user_id,
		send_date,
		expiration_date,
		seen,
		view_date,
		done,
		action_date,
		Deleted
	)
	SELECT DISTINCT
		vr_application_id,
		rf.user_id,
		rf.node_id,
		COALESCE(rf.ref_item_id, rf.node_id),
		rf.type,
		rf.subtype,
		rf.info,
		COALESCE(rf.removable, FALSE)::BOOLEAN,
		rf.sender_user_id,
		rf.send_date,
		rf.expiration_date,
		COALESCE(rf.seen, FALSE)::BOOLEAN,
		rf.view_date,
		COALESCE(rf.done, FALSE)::BOOLEAN,
		ref.action_date,
		FALSE
	FROM UNNEST(vr_dashboards) AS rf
		LEFT JOIN ntfn_dashboards AS d
		ON d.application_id = vr_application_id AND 
			d.user_id = rf.user_id AND d.node_id = rf.node_id AND 
			d.ref_item_id = rf.ref_item_id AND d.type = rf.type AND 
			((d.subtype IS NULL AND ref.subtype IS NULL) OR d.subtype = rf.subtype) AND
			rf.removable = d.removable AND d.done = FALSE AND d.deleted = FALSE
	WHERE d.id IS NULL;
	
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

