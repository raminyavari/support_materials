DROP VIEW IF EXISTS cn_view_node_relations;

CREATE VIEW cn_view_node_relations
AS
SELECT nr.application_id,
	   nr.source_node_id, 
	   nr.destination_node_id, 
	   nr.property_id AS relation_type_id, 
	   nr.nominal_value, 
       nr.numerical_value, 
       nr.deleted AS relation_deleted, 
       rt.additional_id AS relation_type_additional_id, 
       rt.name AS relation_type, 
       rt.deleted AS relation_type_deleted
FROM   cn_node_relations  AS nr 
	INNER JOIN cn_properties AS rt
	ON rt.application_id = nr.application_id AND rt.property_id = nr.property_id;