DROP FUNCTION IF EXISTS wf_sort_state_connections;

CREATE OR REPLACE FUNCTION wf_sort_state_connections
(
	vr_application_id	UUID,
	vr_ids				guid_table_type[]		
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_workflow_id 	UUID;
	vr_state_id 	UUID;
	vr_result		INTEGER;
BEGIN
	SELECT INTO vr_workflow_id, vr_state_id
				sc.workflow_id, sc.in_state_id
	FROM wf_state_connections AS sc
	WHERE sc.application_id = vr_application_id AND sc.id = (SELECT rf.value FROM UNNEST(vr_ids) AS rf LIMIT 1);
	
	IF vr_workflow_id IS NULL OR vr_state_id IS NULL THEN
		RETURN -1::INTEGER;
	END IF;
	
	vr_ids := ARRAY(
		SELECT x
		FROM UNNEST(vr_ids) AS x
		
		UNION ALL
		
		SELECT ROW(sc.id)
		FROM UNNEST(vr_ids) AS rf
			RIGHT JOIN wf_state_connections AS sc
			ON sc.id = rf.value
		WHERE sc.application_id = vr_application_id AND 
			sc.workflow_id = vr_workflow_id AND sc.in_state_id = vr_state_id AND rf.id IS NULL
		ORDER BY sc.sequence_number	ASC
	);
	
	UPDATE wf_state_connections
	SET sequence_number = rf.seq
	FROM UNNEST(vr_ids) WITH ORDINALITY AS rf("id", seq)
		INNER JOIN wf_state_connections AS sc
		ON sc.id = rf.id
	WHERE sc.application_id = vr_application_id AND 
		sc.workflow_id = vr_workflow_id AND sc.in_state_id = vr_state_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

