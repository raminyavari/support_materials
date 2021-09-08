DROP FUNCTION IF EXISTS cn_set_nodes_searchability;

CREATE OR REPLACE FUNCTION cn_set_nodes_searchability
(
	vr_application_id	UUID,
    vr_node_ids			guid_table_type[],
    vr_searchable		BOOLEAN,
    vr_current_user_id	UUID,
    vr_now 				TIMESTAMP
)
RETURNS VARCHAR
AS
$$
DECLARE
	vr_result	INTEGER = 0;
BEGIN
    UPDATE cn_nodes
	SET searchable = vr_searchable,
		last_modifier_user_id = vr_current_user_id,
		Last_modification_date = vr_now
    FROM UNNEST(vr_node_ids) AS rf
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = rf.value;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

