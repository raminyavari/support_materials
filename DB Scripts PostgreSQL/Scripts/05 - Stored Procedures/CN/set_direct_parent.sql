DROP FUNCTION IF EXISTS cn_set_direct_parent;

CREATE OR REPLACE FUNCTION cn_set_direct_parent
(
	vr_application_id	UUID,
	vr_node_ids			guid_table_type[],
	vr_parent_node_id	UUID,
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS TABLE (
	"result"	INTEGER,
	"message"	VARCHAR
)
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	DROP TABLE IF EXISTS parent_hr_23472;
	
	CREATE TEMP TABLE parent_hr_23472 (
		"id"		UUID,
		parent_id	UUID,
		"level"		INTEGER,
		"name"		VARCHAR
	);
	
	IF vr_parent_node_id IS NOT NULL THEN
		INSERT INTO parent_hr_23472 ("id", parent_id, "level", "name")
		SELECT x.id, x.parent_id, x.level, x.name
		FROM cn_p_get_node_hierarchy(vr_application_id, vr_parent_node_id, FALSE) AS x;
	END IF;
	
	IF EXISTS(
		SELECT 1
		FROM parent_hr_23472 AS "p"
			INNER JOIN UNNEST(vr_node_ids) AS n
			ON n.value = "p".node_id
		LIMIT 1
	) THEN
		RETURN QUERY
		SELECT -1::INTEGER, 'CannotTransferToChilds'::VARCHAR;
		
		RETURN;
	END IF;

	UPDATE cn_nodes
	SET last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now,
		parent_node_id = vr_parent_node_id
	FROM UNNEST(vr_node_ids) AS "ref"
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = "ref".value
	WHERE vr_parent_node_id IS NULL OR nd.node_id <> vr_parent_node_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN QUERY
	SELECT vr_result, ''::VARCHAR;
END;
$$ LANGUAGE plpgsql;
