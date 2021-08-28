DROP FUNCTION IF EXISTS cn_move_node_type;

CREATE OR REPLACE FUNCTION cn_move_node_type
(
	vr_application_id	UUID,
    vr_node_type_ids 	guid_table_type[],
    vr_parent_id		UUID,
    vr_current_user_id	UUID,
    vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER = 0;
BEGIN
	UPDATE cn_node_types
	SET parent_id = vr_parent_id,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM UNNEST(vr_node_type_ids) AS ids 
		INNER JOIN cn_node_types AS nt
		ON nt.application_id = vr_application_id AND nt.node_type_id = ids.value;

	GET DIAGNOSTICS vr_result := ROW_COUNT;

	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

