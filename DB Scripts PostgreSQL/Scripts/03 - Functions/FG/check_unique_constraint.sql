DROP FUNCTION IF EXISTS fg_fn_check_unique_constraint;

CREATE OR REPLACE FUNCTION fg_fn_check_unique_constraint
(
	vr_application_id	UUID,
	vr_elements			form_element_table_type[]
)
RETURNS TABLE (
	element_id 		UUID,
	ref_element_id	UUID
)
AS
$$
DECLARE
	vr_owner_ids UUID[];
BEGIN
	vr_owner_ids := ARRAY(
		SELECT DISTINCT i.owner_id
		FROM UNNEST(vr_elements) AS e
			INNER JOIN fg_form_instances AS i
			ON i.application_id = vr_application_id AND i.instance_id = e.instance_id
	);

	RETURN QUERY
	SELECT DISTINCT "ref".element_id, "ref".ref_element_id
	FROM UNNEST(vr_elements) AS "ref"
		INNER JOIN fg_extended_form_elements AS e
		ON e.application_id = vr_application_id AND 
			(e.element_id = "ref".element_id OR e.element_id = "ref".ref_element_id) AND 
			e.unique_value = TRUE AND (e.type = 'Text' OR e.type = 'Numeric')
		INNER JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND ie.ref_element_id = e.element_id AND
			("ref".element_id IS NULL OR ie.element_id <> "ref".element_id) AND
			(
				CASE 
					WHEN e.type = 'Text' AND COALESCE("ref".text_value, N'') <> N'' AND 
						COALESCE("ref".text_value, N'') = COALESCE(ie.text_value, N'') THEN 1
					WHEN e.type = N'Numeric' AND "ref".float_value IS NOT NULL AND 
						ie.float_value IS NOT NULL AND "ref".float_value = ie.float_value THEN 1
					ELSE 0
				END
			) = 1
		INNER JOIN (
			SELECT fi.instance_id
			FROM fg_form_instances AS fi
				INNER JOIN (
					SELECT nd.node_id AS id
					FROM UNNEST(vr_owner_ids) AS "id"
						INNER JOIN cn_node_types AS nt
						ON nt.application_id = vr_application_id AND nt.node_type_id = "id"
						INNER JOIN cn_nodes AS nd
						ON nd.application_id = vr_application_id AND 
							nd.node_type_id = nt.node_type_id AND nd.deleted = FALSE

					UNION

					SELECT nd.node_id
					FROM UNNEST(vr_owner_ids) AS "id"
						INNER JOIN cn_nodes AS nt
						ON nt.application_id = vr_application_id AND nt.node_id = "id"
						INNER JOIN cn_nodes AS nd
						ON nd.application_id = vr_application_id AND 
							nd.node_type_id = nt.node_type_id AND nd.deleted = FALSE

					UNION

					SELECT UNNEST(vr_owner_ids)
				) AS owners
				ON fi.owner_id = owners.id
			WHERE fi.application_id = vr_application_id
		) AS x
		ON x.instance_id = ie.instance_id;
END;
$$ LANGUAGE PLPGSQL;