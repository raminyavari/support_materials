DROP FUNCTION IF EXISTS cn_p_update_form_and_wiki_tags;

CREATE OR REPLACE FUNCTION cn_p_update_form_and_wiki_tags
(
	vr_application_id	UUID,
	vr_node_ids			UUID[],
	vr_creator_user_id	UUID,
	vr_form		 		BOOLEAN,
	vr_wiki		 		BOOLEAN
)
RETURNS INTEGER
AS
$$
BEGIN
	vr_node_ids := ARRAY(
		SELECT x
		FROM UNNEST(vr_node_ids) AS x
			LEFT JOIN rv_tagged_items AS "t"
			ON "t".application_id = vr_application_id AND "t".context_id = x AND (
					(vr_form = TRUE AND "t".tagged_type IN ('Node_Form', 'User_Form')) OR 
					(vr_wiki = TRUE AND "t".tagged_type IN ('Node_Wiki', 'User_Wiki'))
				)
		WHERE "t".context_id IS NULL
	);

	WITH RECURSIVE "hierarchy" (element_id, node_id, "level", "type")
 	AS 
	(
		SELECT e.element_id, n.value AS node_id, 0::INTEGER AS "level", e.type::VARCHAR
		FROM UNNEST(vr_node_ids) AS n
			INNER JOIN fg_form_instances AS i
			ON i.application_id = vr_application_id AND i.owner_id = n AND i.deleted = FALSE
			INNER JOIN fg_instance_elements AS e
			ON e.application_id = vr_application_id AND e.instance_id = i.instance_id AND e.deleted = FALSE
		WHERE vr_form = TRUE
		
		UNION ALL
		
		SELECT e.element_id, hr.node_id, "level" + 1, e.type
		FROM "hierarchy" AS hr
			INNER JOIN fg_form_instances AS i
			ON i.application_id = vr_application_id AND i.owner_id = hr.element_id AND i.deleted = FALSE
			INNER JOIN fg_instance_elements AS e
			ON e.application_id = vr_application_id AND e.instance_id = i.instance_id AND e.deleted = FALSE
		WHERE vr_form = TRUE AND e.element_id <> hr.element_id
	),
	"data" AS (
		SELECT "a".node_id, "a".tagged_id, MAX("a".tagged_type) AS tagged_type
		FROM (
				SELECT h.node_id, "t".tagged_id, "t".tagged_type || '_Form' AS tagged_type
				FROM "hierarchy" AS h
					INNER JOIN rv_tagged_items AS "t"
					ON "t".application_id = vr_application_id AND "t".context_id = h.element_id AND 
						"t".tagged_type IN ('Node', 'User')

				UNION

				SELECT h.node_id, s.selected_id AS tagged_id, h.type || '_Form' AS tagged_type
				FROM "hierarchy" AS h
					INNER JOIN fg_selected_items AS s
					ON s.application_id = vr_application_id AND s.element_id = h.element_id AND s.deleted = FALSE
				WHERE h.type IN ('Node', 'User')

				UNION

				SELECT "t".context_id AS node_id, "t".tagged_id, "t".tagged_type || '_Wiki' AS tagged_type
				FROM UNNEST(vr_node_ids) AS x
					INNER JOIN cn_view_tag_relations_wiki_context AS "t"
					ON "t".application_id = vr_application_id AND "t".context_id = x
				WHERE vr_wiki = TRUE
			) AS "a"
		GROUP BY "a".node_id, "a".tagged_id
	)
	INSERT INTO rv_tagged_items (
		application_id, 
		context_id, 
		context_type, 
		tagged_id, 
		tagged_type, 
		unique_id, 
		creator_user_id
	)
	SELECT 	vr_application_id, 
			x.node_id, 
			'Node', 
			x.tagged_id, 
			x.tagged_type, 
			gen_random_uuid(), 
			vr_creator_user_id
	FROM "data" AS x
		LEFT JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = x.tagged_id AND nd.deleted = FALSE
		LEFT JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = x.tagged_id AND un.is_approved = TRUE
		LEFT JOIN rv_tagged_items AS "t"
		ON "t".application_id = vr_application_id AND "t".context_id = x.node_id AND
			"t".tagged_id = x.tagged_id AND "t".creator_user_id = vr_creator_user_id
	WHERE "t".context_id IS NULL AND (nd.node_id IS NOT NULL OR un.user_id IS NOT NULL);
		
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;
