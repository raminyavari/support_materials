DROP FUNCTION IF EXISTS cn_set_admin_area;

CREATE OR REPLACE FUNCTION cn_set_admin_area
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_area_id			UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE cn_nodes AS nd
	SET area_id = vr_area_id
	WHERE nd.application_id = vr_application_id AND nd.node_id = vr_node_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
