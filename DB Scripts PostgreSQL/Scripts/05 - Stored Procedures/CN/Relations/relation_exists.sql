DROP FUNCTION IF EXISTS cn_relation_exists;

CREATE OR REPLACE FUNCTION cn_relation_exists
(
	vr_application_id		UUID,
	vr_source_node_id		UUID,
	vr_destination_node_id	UUID,
	vr_reverse_also			BOOLEAN
)
RETURNS BOOLEAN
AS
$$
BEGIN
	RETURN COALESCE((
		SELECT TRUE
		FROM cn_node_relations AS nr
		WHERE nr.application_id = vr_application_id AND 
			((nr.source_node_id = vr_source_node_id AND nr.destination_node_id = vr_destination_node_id) OR
			(vr_reverse_also = TRUE AND nr.source_node_id = vr_destination_node_id AND
			  nr.destination_node_id = vr_source_node_id)) AND nrdeleted = FALSE
		LIMIT 1
	), FALSE)::BOOLEAN;
END;
$$ LANGUAGE plpgsql;
