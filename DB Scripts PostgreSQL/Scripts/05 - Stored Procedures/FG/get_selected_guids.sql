DROP FUNCTION IF EXISTS fg_get_selected_guids;

CREATE OR REPLACE FUNCTION fg_get_selected_guids
(
	vr_application_id	UUID,
	vr_element_ids		guid_table_type[]
)
RETURNS TABLE (
	element_id	UUID,
	"id"		UUID,
	"name"		VARCHAR
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT	s.element_id,
			s.selected_id AS "id",
			CASE
				WHEN nd.node_id IS NOT NULL THEN nd.name
				ELSE LTRIM(RTRIM(COALESCE(un.first_name, '') || ' ' || COALESCE(un.last_name, '')))
			END AS "name"
	FROM UNNEST(vr_element_ids) AS ids
		INNER JOIN fg_selected_items AS s
		ON s.application_id = vr_application_id AND s.element_id = ids.value AND s.deleted = FALSE
		LEFT JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = s.selected_id AND nd.deleted = FALSE
		LEFT JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = s.selected_id
	WHERE nd.node_id IS NOT NULL OR un.user_id IS NOT NULL;
END;
$$ LANGUAGE plpgsql;

