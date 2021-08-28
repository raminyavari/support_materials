
DROP FUNCTION IF EXISTS cn_get_node_types;

CREATE OR REPLACE FUNCTION cn_get_node_types
(
	vr_application_id	UUID,
	vr_search_text	 	VARCHAR(1000),
	vr_is_knowledge 	BOOLEAN,
	vr_is_document	 	BOOLEAN,
	vr_archive	 		BOOLEAN,
	vr_extensions 		VARCHAR(100)[],
	vr_count		 	INTEGER,
	vr_lower_boundary	BIGINT
)
RETURNS SETOF cn_node_type_ret_composite
AS
$$
DECLARE
	vr_node_type_ids	UUID[];
	vr_extensions_count INTEGER;
	vr_total_count		INTEGER;
BEGIN
	vr_node_type_ids = ARRAY(
		SELECT '3b34bbb2-0100-4bf4-a043-d134a94807e0'
	);
	
	DROP TABLE IF EXISTS vr_ids_45345;
	
	CREATE TEMP TABLE vr_ids_45345 (node_type_id UUID, total_count INTEGER);
	
	vr_extensions_count := COALESCE(ARRAY_LENGTH(vr_extensions, 1), 0)::INTEGER;
	
	IF COALESCE(vr_count, 0) <= 0 THEN
		vr_count := 1000000;
	END IF;
	
	IF COALESCE(vr_search_text, N'') = N'' THEN
		INSERT INTO vr_ids_45345 (node_type_id, total_count)
		SELECT	rf.node_type_id,
				(rf.row_number + rf.rev_row_number - 1) AS total_count
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY COALESCE(MAX(nt.creation_date), 
							'2000-02-15 10:48:39.330') DESC, nt.node_type_id DESC) AS "row_number",
						ROW_NUMBER() OVER (ORDER BY COALESCE(MAX(nt.creation_date), 
							'2000-02-15 10:48:39.330') ASC, nt.node_type_id ASC) AS rev_row_number,
						nt.node_type_id,
						MAX(nt.sequence_number) AS sequence_number
				FROM cn_node_types AS nt
					LEFT JOIN cn_services AS s
					ON s.application_id = vr_application_id AND 
						s.node_type_id = nt.node_type_id AND s.deleted = FALSE
					LEFT JOIN cn_extensions AS ex
					ON vr_extensions_count > 0 AND ex.application_id = vr_application_id AND 
						ex.owner_id = nt.node_type_id AND 
						ex.extension IN (SELECT UNNEST(vr_extensions))
				WHERE nt.application_id = vr_application_id AND 
					(COALESCE(vr_is_knowledge, FALSE) = FALSE OR s.is_knowledge = TRUE) AND
					(COALESCE(vr_is_document, FALSE) = FALSE OR s.is_document = TRUE) AND
					(nt.deleted = COALESCE(vr_archive, FALSE)) AND
					(vr_extensions_count = 0 OR ex.owner_id IS NOT NULL)
				GROUP BY nt.node_type_id
			) AS rf
		WHERE rf.row_number >= COALESCE(vr_lower_boundary, 0)
		ORDER BY rf.sequence_number ASC, rf.row_number ASC
		LIMIT vr_count;
	ELSE
		INSERT INTO vr_ids_45345 (node_type_id, total_count)
		SELECT	rf.node_type_id,
				(rf.row_number + rf.rev_row_number - 1) AS total_count
		FROM (
				SELECT 	ROW_NUMBER() OVER (ORDER BY MAX(x.score) DESC, x.node_type_id DESC) AS "row_number",
						ROW_NUMBER() OVER (ORDER BY MAX(x.score) ASC, x.node_type_id ASC) AS rev_row_number,
						x.node_type_id,
						MAX(x.sequence_number) AS sequence_number
				FROM (
						SELECT	nt.node_type_id,
								nt.sequence_number,
								pgroonga_score(nt.tableoid, nt.ctid) AS score
						FROM cn_node_types AS nt
							LEFT JOIN cn_services AS s
							ON s.application_id = vr_application_id AND 
								s.node_type_id = nt.node_type_id AND s.deleted = FALSE
							LEFT JOIN cn_extensions AS ex
							ON vr_extensions_count > 0 AND ex.application_id = vr_application_id AND 
								ex.owner_id = nt.node_type_id AND 
								ex.extension IN (SELECT UNNEST(vr_extensions))
						WHERE nt.application_id = vr_application_id AND 
							nt.name &@~ vr_search_text AND
							(COALESCE(vr_is_knowledge, FALSE) = FALSE OR s.is_knowledge = TRUE) AND
							(COALESCE(vr_is_document, FALSE) = FALSE OR s.is_document = TRUE) AND
							(nt.deleted = COALESCE(vr_archive, FALSE)) AND
							(vr_extensions_count = 0 OR ex.owner_id IS NOT NULL)
					) AS x
				GROUP BY x.node_type_id
			) AS rf
		WHERE rf.row_number >= COALESCE(vr_lower_boundary, 0)
		ORDER BY rf.sequence_number ASC, rf.row_number ASC
		LIMIT vr_count;
	END IF;
	
	vr_node_type_ids = ARRAY(
		SELECT rf.node_type_id
		FROM vr_ids_45345 AS rf
	);
	
	vr_total_count := (
		SELECT total_count
		FROM vr_ids_45345
		LIMIT 1
	);
	
	RETURN QUERY
	SELECT *
	FROM cn_p_get_node_types_by_ids(vr_application_id, vr_node_type_ids, vr_total_count);
END;
$$ LANGUAGE plpgsql;
