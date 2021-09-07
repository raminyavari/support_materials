DROP FUNCTION IF EXISTS cn_set_node_type_additional_id;

CREATE OR REPLACE FUNCTION cn_set_node_type_additional_id
(
	vr_application_id	UUID,
    vr_node_type_id 	UUID,
    vr_additional_id	VARCHAR(255),
    vr_current_user_id	UUID,
    vr_now 				TIMESTAMP
)
RETURNS TABLE (
	"result"	INTEGER,
	"message"	VARCHAR(100)
)
AS
$$
DECLARE
	vr_current_additional_id 	VARCHAR(255);
	vr_result					INTEGER = 0;
BEGIN
	vr_current_additional_id := (
		SELECT additional_id
		FROM cn_node_types
		WHERE application_id = vr_application_id AND node_type_id = vr_node_type_id
		LIMIT 1
	);
	
	IF LTRIM(RTRIM(COALESCE(vr_current_additional_id, ''))) = '6' THEN
		RETURN QUERY
		SELECT (-1)::INTEGER, 'CannotChangeTheAdditionalIDOFThisNodeType'::VARCHAR(100);
		
		RETURN;
	ELSEIF Exists(
		SELECT *
		FROM cn_node_types
		WHERE application_id = vr_application_id AND node_type_id <> vr_node_type_id AND 
			LOWER(additional_id) = LOWER(vr_additional_id)
		LIMIT 1
	) THEN
		RETURN QUERY
		SELECT (-1)::INTEGER, 'ThereIsAlreadyANodeTypeWithTheSameAdditionalID'::VARCHAR(100);
		
		RETURN;
	ELSE
		UPDATE cn_node_types
		SET additional_id = vr_additional_id,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
		WHERE application_id = vr_application_id AND node_type_id = vr_node_type_id;

		GET DIAGNOSTICS vr_result := ROW_COUNT;

		RETURN QUERY
		SELECT vr_result, NULL::VARCHAR(100);
	END IF;
END;
$$ LANGUAGE plpgsql;

