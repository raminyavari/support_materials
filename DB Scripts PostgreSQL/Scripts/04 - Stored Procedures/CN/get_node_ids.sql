DROP FUNCTION IF EXISTS cn_get_node_ids;

CREATE OR REPLACE FUNCTION cn_get_node_ids
(
	vr_application_id			UUID,
	vr_node_additional_ids		string_table_type[],
	vr_node_type_id				UUID,
    vr_node_type_addtional_id	VARCHAR(255)
)
RETURNS SETOF UUID
AS
$$
BEGIN
	IF vr_node_type_id IS NULL THEN
		vr_node_type_id := cn_fn_get_node_type_id(vr_application_id, vr_node_type_addtional_id);
	END IF;
	
	RETURN QUERY
	SELECT nd.node_id AS "id"
	FROM UNNEST(vr_node_additional_ids) AS external_ids 
		INNER JOIN cn_nodes AS nd
		ON nd.additional_id = external_ids.value
	WHERE nd.application_id = vr_application_id AND nd.node_type_id = vr_node_type_id;
END;
$$ LANGUAGE plpgsql;
