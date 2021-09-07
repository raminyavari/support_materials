DROP FUNCTION IF EXISTS cn_get_node_ids_that_will_be_expired_soon;

CREATE OR REPLACE FUNCTION cn_get_node_ids_that_will_be_expired_soon
(
	vr_application_id	UUID,
    vr_date		 		TIMESTAMP
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT nd.node_id AS "id"
	FROM cn_nodes AS nd
		LEFT JOIN ntfn_dashboards AS d
		ON d.application_id = vr_application_id AND d.node_id = Nd.node_id AND 
			d.deleted = FALSE AND d.done = FALSE AND
			d.type = 'Knowledge' AND d.subtype = 'ExpirationDate'
	WHERE nd.application_id = vr_application_id AND nd.deleted = FALSE AND
		nd.expiration_date IS NOT NULL AND nd.expiration_date <= vr_date AND d.id IS NULL;
END;
$$ LANGUAGE plpgsql;

