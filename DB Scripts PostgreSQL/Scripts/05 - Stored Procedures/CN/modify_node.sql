DROP FUNCTION IF EXISTS cn_modify_node;

CREATE OR REPLACE FUNCTION cn_modify_node
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_name				VARCHAR(255),
    vr_description		VARCHAR,
    vr_tags				VARCHAR(2000),
    vr_current_user_id	UUID,
    vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
BEGIN
	RETURN cn_p_modify_node(vr_application_id, vr_node_id, vr_name, vr_description, vr_tags, vr_current_user_id, vr_now);
END;
$$ LANGUAGE plpgsql;

