DROP FUNCTION IF EXISTS cn_get_services_by_ids;

CREATE OR REPLACE FUNCTION cn_get_services_by_ids
(
	vr_application_id	UUID,
	vr_node_type_ids	guid_table_type[]
)
RETURNS SETOF cn_service_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT x.value
		FROM UNNEST(vr_node_type_ids) AS x
	);

	RETURN QUERY
	SELECT *
	FROM cn_p_get_services_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;
