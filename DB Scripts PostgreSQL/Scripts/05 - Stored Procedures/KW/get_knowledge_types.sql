DROP FUNCTION IF EXISTS kw_get_knowledge_types;

CREATE OR REPLACE FUNCTION kw_get_knowledge_types
(
	vr_application_id		UUID,
	vr_knowledge_type_ids	guid_table_type[]
)
RETURNS SETOF kw_knowledge_type_ret_composite
AS
$$
DECLARE
	vr_id	UUID;
	vr_ids	UUID[];
BEGIN
	IF ARRAY_LENGTH(vr_knowledge_type_ids, 1) = 1 THEN
		vr_id := (SELECT x.value FROM UNNEST(vr_knowledge_type_ids) AS x LIMIT 1);
		
		IF vr_id IS NOT NULL THEN
			vr_knowledge_type_ids := ARRAY(
				SELECT COALESCE((
					SELECT nd.node_type_id 
					FROM cn_nodes AS nd
					WHERE nd.application_id = vr_application_id AND nd.node_id = vr_id
					LIMIT 1
				), vr_id)
			);
		END IF;
	END IF;
	
	IF ARRAY_LENGTH(vr_knowledge_type_ids, 1) = 0 THEN
		vr_knowledge_type_ids := ARRAY(
			SELECT kt.knowledge_type_id
			FROM kw_knowledge_types AS kt
			WHERE kt.application_id = vr_application_id AND kt.deleted = FALSE
		);
	END IF;
	
	RETURN QUERY
	SELECT *
	FROM kw_p_get_knowledge_types_by_ids(vr_application_id, vr_knowledge_type_ids);
END;
$$ LANGUAGE plpgsql;

