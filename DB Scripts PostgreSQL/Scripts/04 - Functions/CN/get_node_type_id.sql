DROP FUNCTION IF EXISTS cn_fn_get_node_type_id;

CREATE OR REPLACE FUNCTION cn_fn_get_node_type_id
(
	vr_application_id	UUID,
	vr_additional_id 	VARCHAR(50)
)
RETURNS UUID
AS
$$
BEGIN
	RETURN (
		SELECT nt.node_type_id 
		FROM cn_node_types AS nt
		WHERE nt.application_id = vr_application_id AND 
			nt.additional_id = vr_additional_id AND COALESCE(vr_additional_id, '') <> ''
		LIMIT 1
	);
END;
$$ LANGUAGE PLPGSQL;