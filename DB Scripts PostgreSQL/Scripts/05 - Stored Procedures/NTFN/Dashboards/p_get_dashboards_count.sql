DROP FUNCTION IF EXISTS ntfn_p_get_dashboards_count;

CREATE OR REPLACE FUNCTION ntfn_p_get_dashboards_count
(
	vr_application_id	UUID,
	vr_user_id			UUID,
    vr_node_id			UUID,
    vr_ref_item_id		UUID,
    vr_type				VARCHAR(20),
    vr_subtype			VARCHAR(20)
)
RETURNS INTEGER
AS
$$
BEGIN
	RETURN COALESCE((
		SELECT COUNT(d.id)
		FROM ntfn_dashboards AS d
		WHERE d.application_id = vr_application_id AND
			(vr_user_id IS NULL OR d.user_id = vr_user_id) AND
			(vr_node_id IS NULL OR d.node_id = vr_node_id) AND 
			(vr_ref_item_id IS NULL OR d.ref_item_id = vr_ref_item_id) AND 
			(vr_type IS NULL OR d.type = vr_type) AND
			(vr_subtype IS NULL OR d.subtype = vr_subtype) AND 
			d.done = FALSE AND d.deleted = FALSE
	), 0)::INTEGER;
END;
$$ LANGUAGE plpgsql;

