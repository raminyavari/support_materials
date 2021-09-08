DROP FUNCTION IF EXISTS cn_recycle_nodes;

CREATE OR REPLACE FUNCTION cn_recycle_nodes
(
	vr_application_id	UUID,
    vr_node_ids			guid_table_type[],
    vr_current_user_id	UUID,
    vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER = 0;
BEGIN	
	UPDATE cn_nodes
	SET deleted = FALSE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM UNNEST(vr_node_ids) AS rf
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = rf.value AND nd.deleted = TRUE;
			
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

