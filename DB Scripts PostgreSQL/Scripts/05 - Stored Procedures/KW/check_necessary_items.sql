DROP FUNCTION IF EXISTS kw_check_necessary_items;

CREATE OR REPLACE FUNCTION kw_check_necessary_items
(
	vr_application_id	UUID,
    vr_node_id			UUID
)
RETURNS SETOF VARCHAR
AS
$$
DECLARE
	vr_node_type_id UUID;
BEGIN
	SELECT vr_node_type_id = nd.node_type_id
	FROM cn_nodes AS nd
	WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id
	LIMIT 1;
	
	RETURN QUERY
	WITH elem_limits AS
	(
		SELECT 	el.element_id::UUID, 
				COALESCE(el.necessary, FALSE)::BOOLEAN AS necessary
		FROM fg_element_limits AS el
		WHERE el.application_id = vr_application_id AND 
			el.owner_id = vr_node_type_id AND el.deleted = FALSE
	),
	has_limit AS
	(
		SELECT 	CASE 
					WHEN (SELECT COUNT(*) FROM elem_limits) > 0 THEN TRUE 
					ELSE FALSE 
				END::BOOLEAN AS val
	),
	new_elem_limits AS
	(
		SELECT *
		FROM elem_limits AS l
		WHERE l.necessary = FALSE
	),
	node AS
	(
		SELECT *
		FROM cn_nodes AS nd
		WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id
		LIMIT 1
	)
	(
		(SELECT 'Abstract' AS item_name
		FROM node AS n
		WHERE COALESCE(n.description, '') <> ''
		LIMIT 1)

		UNION

		(SELECT 'Keywords' AS item_name
		FROM node AS n
		WHERE COALESCE(n.tags, '') <> ''
		LIMIT 1)

		UNION

		(SELECT 'Wiki' AS item_name
		FROM node AS n
			INNER JOIN wk_titles AS "t"
			ON "t".application_id = vr_application_id AND "t".owner_id = n.node_id AND "t".deleted = FALSE
			INNER JOIN wk_paragraphs AS "p"
			ON "p".application_id = vr_application_id AND "p".title_id = "t".title_id AND "p".deleted = FALSE AND
				("p".status = 'Accepted' OR "p".status = 'CitationNeeded')
		LIMIT 1)

		UNION

		(SELECT 'RelatedNodes' AS item_name
		FROM node AS n
			LEFT JOIN cn_view_out_related_nodes AS nr
			ON nr.application_id = vr_application_id AND 
				nr.node_id = n.node_id AND nr.related_node_id <> n.node_id
			LEFT JOIN cn_view_in_related_nodes AS nrin
			ON nrin.application_id = vr_application_id AND
				nrin.node_id = n.node_id AND nrin.related_node_id <> n.node_id
		WHERE nr.node_id IS NOT NULL OR nrin.node_id IS NOT NULL
		LIMIT 1)

		UNION

		(SELECT 'Attachments' AS item_name
		FROM node AS n
			INNER JOIN dct_files AS att
			ON att.application_id = vr_application_id AND att.owner_id = n.node_id AND att.deleted = FALSE
		LIMIT 1)

		UNION

		(SELECT 'DocumentTree' AS item_name
		FROM node AS n
		WHERE n.document_tree_node_id IS NOT NULL
		LIMIT 1)

		UNION

		SELECT 'NecessaryFieldsOfForm' AS item_name
		WHERE NOT EXISTS (
				SELECT 1
				FROM node AS n 
					INNER JOIN fg_form_owners AS o
					ON o.application_id = vr_application_id AND 
						o.owner_id = n.node_type_id AND o.deleted = FALSE
					INNER JOIN fg_form_instances AS i
					ON i.application_id = vr_application_id AND 
						i.form_id = o.form_id AND i.owner_id = vr_node_id AND i.deleted = FALSE
					CROSS JOIN has_limit AS ab
					INNER JOIN fg_extended_form_elements AS fe
					ON fe.application_id = vr_application_id AND 
						fe.form_id = o.form_id AND fe.deleted = FALSE AND
						(ab.val = TRUE OR fe.necessary = TRUE)
					LEFT JOIN fg_instance_elements AS e
					ON e.application_id = vr_application_id AND e.instance_id = i.instance_id AND 
						e.ref_element_id = fe.element_id AND e.deleted = FALSE
				WHERE (
						ab.val = FALSE OR 
						fe.element_id IN (SELECT y.element_id FROM new_elem_limits AS y)
					) AND
					COALESCE(fg_fn_to_string(
						vr_application_id,
						e.element_id,
						e.type,
						e.text_value, 
						e.float_value,
						e.bit_value, 
						e.date_value
					), '') = ''
				LIMIT 1
			)
	);
END;
$$ LANGUAGE plpgsql;

