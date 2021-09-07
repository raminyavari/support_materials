DROP FUNCTION IF EXISTS cn_p_arithmetic_delete_all_relations;

CREATE OR REPLACE FUNCTION cn_p_arithmetic_delete_all_relations
(
	vr_application_id	UUID,
	vr_node_id			UUID,
    vr_creator_user_id	UUID,
    vr_creation_date	TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE cn_node_relations
	SET deleted = TRUE,
		last_modifier_user_id = vr_creator_user_id,
		last_modification_date = vr_creation_date
	WHERE applicationID = vr_application_id AND 
		(source_node_id = vr_node_id OR destination_node_id = vr_node_id) AND deleted = FALSE;
		
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN (CASE WHEN vr_result <= 0 THEN 1 ELSE vr_result END);
END;
$$ LANGUAGE plpgsql;

