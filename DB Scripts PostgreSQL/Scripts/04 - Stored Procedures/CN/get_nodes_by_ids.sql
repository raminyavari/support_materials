DROP FUNCTION IF EXISTS cn_get_nodes_by_ids;

CREATE OR REPLACE FUNCTION cn_get_nodes_by_ids
(
	vr_application_id	UUID,
    vr_node_ids 		guid_table_type[],
    vr_full		 		BOOLEAN,
    vr_viewer_user_id	UUID
)
RETURNS SETOF UUID
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT DISTINCT x.value
		FROM UNNEST(vr_node_ids) AS x
	);

	RETURN QUERY
	SELECT *
	FROM cn_p_get_nodes_by_ids(vr_application_id, vr_ids, vr_full, vr_viewer_user_id);
END;
$$ LANGUAGE plpgsql;
