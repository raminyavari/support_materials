DROP FUNCTION IF EXISTS prvc_fn_check_node_permission;

CREATE OR REPLACE FUNCTION prvc_fn_check_node_permission
(
	vr_node			 		BOOLEAN,
	vr_node_type		 	BOOLEAN,
	vr_document_tree_node	BOOLEAN,
	vr_document_tree	 	BOOLEAN
)
RETURNS BOOLEAN
AS
$$
BEGIN
	RETURN CASE
		WHEN vr_node IS NOT NULL THEN vr_node
		WHEN vr_node_type IS NULL THEN COALESCE(vr_document_tree_node, vr_document_tree)
		WHEN vr_document_tree_node IS NULL AND vr_document_tree IS NULL THEN vr_node_type
		WHEN vr_node_type < COALESCE(vr_document_tree_node, vr_document_tree) THEN vr_node_type
		ELSE COALESCE(vr_document_tree_node, vr_document_tree)
	END;
END;
$$ LANGUAGE PLPGSQL;