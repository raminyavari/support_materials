DROP FUNCTION IF EXISTS cn_get_node_records_count;

CREATE OR REPLACE FUNCTION cn_get_node_records_count
(
	vr_application_id	UUID
)
RETURNS BIGINT
AS
$$
BEGIN
	RETURN (
		SELECT (COUNT(*) + 1)::BIGINT
		FROM cn_nodes AS nd
		WHERE nd.application_id = vr_application_id
	);
END;
$$ LANGUAGE plpgsql;
