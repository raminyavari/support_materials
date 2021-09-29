DROP FUNCTION IF EXISTS dct_get_file_owner_nodes;

CREATE OR REPLACE FUNCTION dct_get_file_owner_nodes
(
	vr_application_id	UUID,
    vr_file_ids			guid_table_type[]
)
RETURNS TABLE (
	file_id		UUID, 
	node_id		UUID, 
	"name"		VARCHAR, 
	node_type	VARCHAR
)
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT x.value
		FROM UNNEST(vr_file_ids) AS x
	);
	
	RETURN QUERY
	SELECT 	rf.file_id, 
			rf.node_id, 
			rf.node_name AS "name", 
			rf.node_type
	FROM dct_fn_get_file_owner_nodes(vr_application_id, vr_ids) AS rf;
END;
$$ LANGUAGE plpgsql;
