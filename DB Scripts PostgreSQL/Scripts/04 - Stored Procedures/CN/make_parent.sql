DROP FUNCTION IF EXISTS cn_make_parent;

CREATE OR REPLACE FUNCTION cn_make_parent
(
	vr_application_id	UUID,
	vr_pair_node_ids	guid_pair_table_type[],
    vr_creator_user_id	UUID,
    vr_creation_date	TIMESTAMP
)
RETURNS INTEGER
AS
$$
BEGIN
	RETURN cn_p_make_parent(vr_application_id, vr_pair_node_ids, vr_creator_user_id, vr_creation_date);
END;
$$ LANGUAGE plpgsql;

