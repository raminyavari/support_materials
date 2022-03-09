DROP FUNCTION IF EXISTS ntfn_p_arithmetic_delete_dashboards;

CREATE OR REPLACE FUNCTION ntfn_p_arithmetic_delete_dashboards
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
DECLARE
	vr_result	INTEGER;
BEGIN
	IF EXISTS (
		SELECT 1
		FROM ntfn_dashboards AS n
		WHERE n.application_id = vr_application_id AND
			(vr_user_id IS NULL OR n.user_id = vr_user_id) AND
			(vr_node_id IS NULL OR n.node_id = vr_node_id) AND 
			(vr_ref_item_id IS NULL OR n.ref_item_id = vr_ref_item_id) AND 
			(vr_type IS NULL OR n.type = vr_type) AND
			(vr_subtype IS NULL OR n.subtype = vr_subtype) AND 
				n.done = FALSE AND n.deleted = FALSE
		LIMIT 1
	) THEN
		UPDATE ntfn_dashboards AS n
		SET deleted = TRUE
		WHERE n.application_id = vr_application_id AND 
			(vr_user_id IS NULL OR n.user_id = vr_user_id) AND
			(vr_node_id IS NULL OR n.node_id = vr_node_id) AND 
			(vr_ref_item_id IS NULL OR n.ref_item_id = vr_ref_item_id) AND 
			(vr_type IS NULL OR n.type = vr_type) AND
			(vr_subtype IS NULL OR n.subtype = vr_subtype) AND 
			n.done = FALSE AND n.deleted = FALSE;
			
		GET DIAGNOSTICS vr_result := ROW_COUNT;
		
		RETURN vr_result;
	ELSE
		RETURN 1::INTEGER;
	END IF;
END;
$$ LANGUAGE plpgsql;

