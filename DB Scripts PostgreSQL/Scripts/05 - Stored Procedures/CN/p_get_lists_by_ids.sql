DROP FUNCTION IF EXISTS cn_p_get_lists_by_ids;

CREATE OR REPLACE FUNCTION cn_p_get_lists_by_ids
(
	vr_application_id	UUID,
    vr_list_ids			UUID[],
	vr_total_count		INTEGER DEFAULT 0
)
RETURNS SETOF cn_list_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT ls.list_id,
		   ls.name AS list_name,
		   ls.description,
		   ls.additional_id,
		   ls.node_type_id,
		   nt.name AS node_type,
		   ls.owner_id,
		   ls.owner_type,
		   vr_total_count AS total_count
	FROM UNNEST(vr_list_ids) AS x
		INNER JOIN cn_lists AS ls
		ON ls.application_id = vr_application_id AND ls.list_id = x
		INNER JOIN cn_node_types AS nt
		ON nt.application_id = vr_application_id AND nt.node_type_id = ls.node_type_id;
END;
$$ LANGUAGE plpgsql;
