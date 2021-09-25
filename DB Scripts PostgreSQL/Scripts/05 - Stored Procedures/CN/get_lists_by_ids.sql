DROP FUNCTION IF EXISTS cn_get_lists_by_ids;

CREATE OR REPLACE FUNCTION cn_get_lists_by_ids
(
	vr_application_id	UUID,
    vr_list_ids			guid_table_type[]
)
RETURNS SETOF cn_list_ret_composite
AS
$$
DECLARE
	vr_ret_ids	UUID[];
BEGIN
	vr_ret_ids := ARRAY(
		SELECT x.value
		FROM UNNEST(vr_list_ids) AS x
	);
	
	RETURN QUERY
	SELECT *
	FROM cn_p_get_lists_by_ids(vr_application_id, vr_ret_ids);
END;
$$ LANGUAGE plpgsql;
