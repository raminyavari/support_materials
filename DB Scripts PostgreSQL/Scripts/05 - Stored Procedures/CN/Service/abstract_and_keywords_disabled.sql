DROP FUNCTION IF EXISTS cn_abstract_and_keywords_disabled;

CREATE OR REPLACE FUNCTION cn_abstract_and_keywords_disabled
(
	vr_application_id			UUID,
	vr_node_type_or_node_ids	guid_table_type[],
	vr_value			 		BOOLEAN
)
RETURNS SETOF VARCHAR
AS
$$
DECLARE
	vr_node_type_ids	guid_pair_table_type[];
	vr_result			INTEGER;
BEGIN
	vr_node_type_ids := ARRAY(
		SELECT DISTINCT ROW(COALESCE(nd.node_type_id, x.value), nd.node_id)
		FROM UNNEST(vr_node_type_or_node_ids) AS x
			LEFT JOIN cn_nodes AS nd
			ON nd.application_id = vr_application_id AND nd.node_id = x.value
	);

	IF vr_value IS NULL THEN
		RETURN QUERY
		SELECT COALESCE(nt.second_value, nt.first_value)::VARCHAR AS "id"
		FROM UNNEST(vr_node_type_ids) AS nt
			INNER JOIN cn_services AS s
			ON s.node_type_id = nt.first_value
		WHERE s.application_id = vr_application_id AND s.disable_abstract_and_keywords = TRUE;
	ELSE
		UPDATE cn_services
		SET disable_abstract_and_keywords = vr_value
		FROM UNNEST(vr_node_type_ids) AS nt
			INNER JOIN cn_services AS s
			ON s.node_type_id = nt.first_value
		WHERE s.application_id = vr_application_id AND nt.second_value IS NULL;
		
		GET DIAGNOSTICS vr_result := ROW_COUNT;
		
		RETURN QUERY 
		SELECT vr_result::VARCHAR;
	END IF;
END;
$$ LANGUAGE plpgsql;
