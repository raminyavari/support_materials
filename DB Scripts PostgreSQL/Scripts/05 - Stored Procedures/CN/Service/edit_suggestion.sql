DROP FUNCTION IF EXISTS cn_edit_suggestion;

CREATE OR REPLACE FUNCTION cn_edit_suggestion
(
	vr_application_id	UUID,
	vr_node_type_id		UUID,
	vr_enable	 		BOOLEAN
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE cn_services AS s
	SET edit_suggestion = vr_enable
	WHERE s.application_id = vr_application_id AND s.node_type_id = vr_node_type_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
