DROP VIEW IF EXISTS cn_view_in_related_nodes;

DROP VIEW IF EXISTS cn_view_out_related_nodes;


CREATE VIEW cn_view_in_related_nodes
AS
SELECT  nr.application_id,
		nr.destination_node_id AS node_id,
		rn.node_id AS related_node_id,
		rn.node_type_id AS related_node_type_id,
		nr.property_id
FROM cn_node_relations AS nr
	INNER JOIN cn_nodes AS rn
	ON rn.application_id = nr.application_id AND rn.node_id = nr.source_node_id
WHERE nr.deleted = FALSE AND rn.deleted = FALSE;


CREATE VIEW cn_view_out_related_nodes
AS
SELECT  nr.application_id,
		nr.source_node_id AS node_id,
		rn.node_id AS related_node_id,
		rn.node_type_id AS related_node_type_id,
		nr.property_id
FROM cn_node_relations AS nr
	INNER JOIN cn_nodes AS rn
	ON rn.application_id = nr.application_id AND rn.node_id = nr.destination_node_id
WHERE nr.deleted = FALSE AND rn.deleted = FALSE;