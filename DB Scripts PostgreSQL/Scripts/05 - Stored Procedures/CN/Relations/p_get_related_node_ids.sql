DROP FUNCTION IF EXISTS cn_p_get_related_node_ids;

CREATE OR REPLACE FUNCTION cn_p_get_related_node_ids
(
	vr_application_id		UUID,
	vr_node_id_or_user_id	UUID,
	vr_related_node_type_id	UUID,
	vr_search_text		 	VARCHAR(1000),
	vr_in				 	BOOLEAN,
	vr_out			 		BOOLEAN,
	vr_in_tags			 	BOOLEAN,
	vr_out_tags		 		BOOLEAN,
	vr_count			 	INTEGER,
	vr_lower_boundary	 	INTEGER
)
RETURNS SETOF UUID
AS
$$
DECLARE
	vr_source_ids		UUID[];
	vr_related_type_ids	UUID[];
	vr_node_ids			UUID[];
BEGIN
	vr_search_text := gfn_verify_string(vr_search_text);

	IF vr_node_id_or_user_id IS NOT NULL THEN
		vr_source_ids := ARRAY(
			SELECT vr_node_id_or_user_id
		);
	END IF;
	
	IF vr_related_node_type_id IS NOT NULL THEN
		vr_related_type_ids := ARRAY(
			SELECT vr_related_node_type_id
		);
	END IF;
	
	IF EXISTS(
		SELECT un.user_id
		FROM users_normal AS un 
		WHERE un.application_id = vr_application_id AND un.user_id = vr_node_id_or_user_id
		LIMIT 1
	) THEN
		vr_node_ids := ARRAY(
			SELECT "ref".related_node_id
			FROM cn_fn_get_user_related_node_ids(vr_application_id, vr_source_ids, vr_related_type_ids) AS "ref"
		);
	ELSE
		vr_node_ids := ARRAY(
			SELECT "ref".related_node_id
			FROM cn_fn_get_related_node_ids(vr_application_id, 
				vr_source_ids, NULL, vr_related_type_ids, vr_in, vr_out, vr_in_tags, vr_out_tags) AS "ref"
		);
	END IF;
	
	
	IF COALESCE(vr_search_text, N'') = N'' THEN
		RETURN QUERY
		SELECT nd.id AS "id"
		FROM UNNEST(vr_node_ids) WITH ORDINALITY AS nd("id", seq)
		WHERE nd.seq >= COALESCE(vr_lower_boundary, 0)
		ORDER BY nd.seq ASC
		LIMIT COALESCE(vr_count, 1000000);
	ELSE
		RETURN QUERY
		SELECT x.node_id AS "id"
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY pgroonga_score(n.tableoid, n.ctid)::FLOAT DESC, nd.seq ASC) AS "row_number",
						nd.id AS node_id
				FROM cn_nodes AS n
					INNER JOIN UNNEST(vr_node_ids) WITH ORDINALITY AS nd("id", seq)
					ON nd.id = n.node_id
				WHERE n.application_id = vr_application_id AND (
						n.name &@~ vr_search_text OR n.tags &@~ vr_search_text OR 
						n.additional_id &@~ vr_search_text
					)
			) AS x
		WHERE x.row_number >= COALESCE(vr_lower_boundary, 0)
		ORDER BY x.row_number ASC
		LIMIT COALESCE(vr_count, 1000000);
	END IF;
END;
$$ LANGUAGE plpgsql;

