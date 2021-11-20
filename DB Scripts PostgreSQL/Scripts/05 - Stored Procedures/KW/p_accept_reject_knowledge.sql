DROP FUNCTION IF EXISTS kw_p_accept_reject_knowledge;

CREATE OR REPLACE FUNCTION kw_p_accept_reject_knowledge
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_accept		 	BOOLEAN
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_searchable 			BOOLEAN;
	vr_previous_version_id	UUID;
	vr_result				INTEGER;
BEGIN
	vr_searchable := COALESCE(vr_accept, FALSE)::BOOLEAN;
	
	UPDATE cn_nodes AS nd
	SET status = CASE WHEN vr_accept = TRUE THEN 'Accepted' ELSE 'Rejected' END,
		searchable = vr_searchable
	WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	IF vr_result <= 0 THEN
		RETURN -1::INTEGER;
	END IF;
	
	IF vr_searchable = TRUE THEN
		vr_previous_version_id := (
			SELECT nd.previous_version_id
			FROM cn_nodes AS nd
			WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id
			LIMIT 1
		);
		
		IF vr_previous_version_id IS NOT NULL THEN
			UPDATE cn_nodes AS nd
			SET searchable = FALSE
			WHERE nd.application_id = vr_application_id AND nd.node_id = vr_previous_version_id;
		END IF;
	END IF;
	
	RETURN ntfn_p_arithmetic_delete_dashboards(vr_application_id, NULL, vr_node_id, 
											   NULL, 'Knowledge', NULL);
END;
$$ LANGUAGE plpgsql;

