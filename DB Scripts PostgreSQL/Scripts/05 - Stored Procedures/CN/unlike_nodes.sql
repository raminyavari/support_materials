DROP FUNCTION IF EXISTS cn_unlike_nodes;

CREATE OR REPLACE FUNCTION cn_unlike_nodes
(
	vr_application_id	UUID,
	vr_node_ids			guid_table_type[],
    vr_user_id			UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE cn_node_likes
	SET	deleted = TRUE
	FROM UNNEST(vr_node_ids) AS rf
		INNER JOIN cn_node_likes AS nl
		ON nl.application_id = vr_application_id AND 
			nl.node_id = rf.value AND nl.user_id = vr_user_id;
			
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
