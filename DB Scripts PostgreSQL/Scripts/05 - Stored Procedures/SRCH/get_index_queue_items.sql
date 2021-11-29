DROP FUNCTION IF EXISTS srch_get_index_queue_items;

CREATE OR REPLACE FUNCTION srch_get_index_queue_items
(
	vr_application_id	UUID,
    vr_count		 	INTEGER,
	vr_item_type		VARCHAR(20)
)
RETURNS TABLE (
	"id"			UUID,
	deleted			BOOLEAN,
	type_id			UUID,
	"type"			VARCHAR,
	additional_id	VARCHAR,
	title			VARCHAR,
	description		VARCHAR,
	tags			VARCHAR,
	"content"		VARCHAR,
	file_content	VARCHAR
)
AS
$$
BEGIN
	vr_count := COALESCE(vr_count, 10)::INTEGER;
	vr_item_type := COALESCE(vr_item_type, 'Node')::VARCHAR(20);

	IF vr_item_type = 'Node' THEN
		RETURN QUERY
		SELECT	nd.node_id AS "id",
				CASE
					WHEN nd.deleted = TRUE OR COALESCE(nd.searchable, TRUE)::BOOLEAN = FALSE OR 
						COALESCE(s.no_content, FALSE)::BOOLEAN = TRUE THEN TRUE
					ELSE FALSE
				END::BOOLEAN AS deleted,
				CASE
					WHEN nd.deleted = TRUE OR COALESCE(nd.searchable, TRUE)::BOOLEAN = FALSE OR 
						COALESCE(s.no_content, FALSE)::BOOLEAN = TRUE THEN NULL
					ELSE nd.node_type_id
				END AS type_id,
				CASE
					WHEN nd.deleted = TRUE OR COALESCE(nd.searchable, TRUE)::BOOLEAN = FALSE OR 
						COALESCE(s.no_content, FALSE)::BOOLEAN = TRUE THEN NULL
					ELSE nd.type_name
				END AS "type",
				CASE
					WHEN nd.deleted = TRUE OR COALESCE(nd.searchable, TRUE)::BOOLEAN = FALSE OR 
						COALESCE(s.no_content, FALSE)::BOOLEAN = TRUE THEN NULL
					ELSE nd.node_additional_id
				END AS additional_id,
				CASE
					WHEN nd.deleted = TRUE OR COALESCE(nd.searchable, TRUE)::BOOLEAN = FALSE OR 
						COALESCE(s.no_content, FALSE)::BOOLEAN = TRUE THEN NULL
					ELSE nd.node_name
				END AS title,
				CASE
					WHEN nd.deleted = TRUE OR COALESCE(nd.searchable, TRUE)::BOOLEAN = FALSE OR 
						COALESCE(s.no_content, FALSE)::BOOLEAN = TRUE THEN NULL
					ELSE nd.description
				END AS description,
				CASE
					WHEN nd.deleted = TRUE OR COALESCE(nd.searchable, TRUE)::BOOLEAN = FALSE OR 
						COALESCE(s.no_content, FALSE)::BOOLEAN = TRUE THEN NULL
					ELSE REPLACE(nd.tags, '~', ' ')
				END AS tags,
				CASE
					WHEN nd.deleted = TRUE OR COALESCE(nd.searchable, TRUE)::BOOLEAN = FALSE OR 
						COALESCE(s.no_content, FALSE)::BOOLEAN = TRUE THEN NULL
					ELSE COALESCE(wk_fn_get_wiki_content(vr_application_id, nd.node_id), '') ||  ' ' ||
						COALESCE(fg_fn_get_owner_form_contents(vr_application_id, nd.node_id, 3), '')
				END AS "content",
				CASE
					WHEN nd.deleted = TRUE OR COALESCE(nd.searchable, TRUE)::BOOLEAN = FALSE OR 
						COALESCE(s.no_content, FALSE)::BOOLEAN = TRUE THEN NULL
					ELSE cn_fn_get_node_file_contents(vr_application_id, nd.node_id)
				END AS file_content
		FROM cn_view_nodes_normal AS nd
			LEFT JOIN cn_services AS s
			ON s.application_id = vr_application_id AND s.node_type_id = nd.node_type_id AND s.deleted = FALSE
		WHERE nd.application_id = vr_application_id
		ORDER BY COALESCE(nd.index_last_update_date, '1977-01-01 00:00:00.000'::TIMESTAMP) ASC
		LIMIT vr_count;
	ELSEIF vr_item_type = 'NodeType' THEN
		RETURN QUERY
		SELECT	nt.node_type_id AS "id",
				CASE
					WHEN nt.deleted = TRUE OR COALESCE(s.no_content, FALSE)::BOOLEAN = TRUE THEN TRUE
					ELSE FALSE
				END::BOOLEAN AS deleted,
				NULL::UUID AS type_id,
				NULL::VARCHAR AS "type",
				NULL::VARCHAR AS additional_id,
				CASE
					WHEN nt.deleted = TRUE OR COALESCE(s.no_content, FALSE)::BOOLEAN = TRUE THEN NULL
					ELSE nt.name
				END AS title,
				CASE
					WHEN nt.deleted = TRUE OR COALESCE(s.no_content, FALSE)::BOOLEAN = TRUE THEN NULL
					ELSE nt.description
				END AS description,
				NULL::VARCHAR AS tags,
				NULL::VARCHAR AS "content",
				NULL::VARCHAR AS file_content
		FROM cn_node_types AS nt
			LEFT JOIN cn_services AS s
			ON s.application_id = vr_application_id AND s.node_type_id = nt.node_type_id AND s.deleted = FALSE
		WHERE nt.application_id = vr_application_id
		ORDER BY COALESCE(nt.index_last_update_date, '1977-01-01 00:00:00.000'::TIMESTAMP) ASC
		LIMIT vr_count;
	ELSEIF vr_item_type = 'Question' THEN
		RETURN QUERY
		SELECT	qa.question_id AS "id",
				qa.deleted AS deleted,
				NULL::UUID AS type_id,
				NULL::VARCHAR AS "type",
				NULL::VARCHAR AS additional_id,
				CASE
					WHEN qa.deleted = TRUE THEN NULL
					ELSE qa.title
				END AS title,
				CASE
					WHEN qa.deleted = TRUE THEN NULL
					ELSE qa.description
				END AS description,
				NULL::VARCHAR AS tags,
				CASE
					WHEN qa.deleted = TRUE THEN NULL
					ELSE qa_fn_get_question_content(vr_application_id, qa.question_id)
				END AS "content",
				NULL::VARCHAR AS file_content
		FROM qa_questions AS qa
		WHERE qa.application_id = vr_application_id
		ORDER BY COALESCE(qa.index_last_update_date, '1977-01-01 00:00:00.000'::TIMESTAMP)
		LIMIT vr_count;
	ELSEIF vr_item_type = 'File' THEN
		RETURN QUERY
		WITH "data" AS
		(
			SELECT	fc.file_id AS "id",
					af.owner_id,
					af.extension AS "type",
					af.file_name AS title,
					fc.content AS file_content
			FROM dct_file_contents AS fc
				INNER JOIN (
					SELECT DISTINCT af.owner_id, af.file_name_guid, af.file_name, af.extension
					FROM dct_files AS af
					WHERE af.application_id = vr_application_id
				) AS af
				ON af.file_name_guid = fc.file_id
			WHERE fc.application_id = vr_application_id AND 
				COALESCE(fc.not_extractable, FALSE) = FALSE AND COALESCE(fc.file_not_found, FALSE) = FALSE
			ORDER BY COALESCE(fc.index_last_update_date, '1977-01-01 00:00:00.000'::TIMESTAMP)
			LIMIT vr_count
		)
		SELECT	x.id,
				b.deleted::BOOLEAN AS deleted,
				NULL::UUID AS type_id,
				CASE WHEN b.deleted = TRUE THEN NULL ELSE x.type END AS "type",
				NULL::VARCHAR AS additional_id,
				CASE WHEN b.deleted = TRUE THEN NULL ELSE x.title END AS title,
				NULL::VARCHAR AS description,
				NULL::VARCHAR AS tags,
				NULL::VARCHAR AS "content",
				CASE WHEN b.deleted = TRUE THEN NULL ELSE x.file_content END AS file_content
		FROM "data" AS x
			LEFT JOIN (
				SELECT 	"a".id, 
						MAX("a".type) AS "type", 
						MAX("a".title) AS title, 
						MAX("a".file_content) AS file_content, 
						MIN("a".deleted::INTEGER)::BOOLEAN AS deleted
				FROM (
						SELECT 	x.id, 
								x.type, 
								x.title, 
								x.file_content, 
								nd.deleted
						FROM "data" AS x
							INNER JOIN cn_nodes AS nd
							ON nd.application_id = vr_application_id AND nd.node_id = x.owner_id

						UNION ALL

						SELECT 	x.id, 
								x.type, 
								x.title, 
								x.file_content,
								CASE 
									WHEN e.deleted = TRUE OR i.deleted = TRUE OR nd.deleted = TRUE THEN TRUE 
									ELSE FALSE 
								END::BOOLEAN AS deleted
						FROM "data" AS x
							INNER JOIN fg_instance_elements AS e
							ON e.application_id = vr_application_id AND e.element_id = x.owner_id
							INNER JOIN fg_form_instances AS i
							ON i.application_id = vr_application_id AND i.instance_id = e.instance_id
							INNER JOIN cn_nodes AS nd
							ON nd.application_id = vr_application_id AND nd.node_id = i.owner_id
					) AS "a"
				GROUP BY "a".id
			) AS b
			ON b.id = x.id;
	ELSEIF vr_item_type = 'User' THEN
		RETURN QUERY
		SELECT 	un.user_id AS "id",
				CASE
					WHEN un.is_approved = TRUE THEN FALSE
					ELSE TRUE
				END::BOOLEAN AS deleted,
				NULL::UUID AS type_id,
				NULL::VARCHAR AS "type",
				un.username AS additional_id,
				COALESCE(un.first_name, '') || ' ' || COALESCE(un.last_name, '') AS title,
				NULL::VARCHAR AS description,
				NULL::VARCHAR AS tags,
				NULL::VARCHAR AS "content",
				NULL::VARCHAR AS file_content
		FROM users_normal AS un
		WHERE un.application_id = vr_application_id
		ORDER BY COALESCE(un.index_last_update_date, '1977-01-01 00:00:00.000'::TIMESTAMP)
		LIMIT vr_count;
	END IF;
END;
$$ LANGUAGE plpgsql;

