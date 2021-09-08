DROP FUNCTION IF EXISTS cn_modify_node_public_description;

CREATE OR REPLACE FUNCTION cn_modify_node_public_description
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_description		VARCHAR
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER = 0;
BEGIN
	UPDATE cn_nodes AS x
	SET public_description = gfn_verify_string(vr_description)
	WHERE x.application_id = vr_application_id AND x.node_id = vr_node_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

