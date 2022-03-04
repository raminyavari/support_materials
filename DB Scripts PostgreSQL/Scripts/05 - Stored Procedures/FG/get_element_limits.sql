DROP FUNCTION IF EXISTS fg_get_element_limits;

CREATE OR REPLACE FUNCTION fg_get_element_limits
(
	vr_application_id	UUID,
	vr_owner_id			UUID
)
RETURNS TABLE (
	element_id	UUID,
	title		VARCHAR,
	necessary	BOOLEAN,
	"type"		VARCHAR,
	"info"		VARCHAR
)
AS
$$
DECLARE
	vr_form_id 	UUID;
BEGIN
	SELECT INTO vr_form_id 
				o.form_id 
	FROM fg_form_owners AS o
	WHERE o.application_id = vr_application_id AND 
		o.owner_id = vr_owner_id AND o.deleted = FALSE
	LIMIT 1;
	
	IF vr_form_id IS NULL THEN
		SELECT INTO vr_form_id, vr_owner_id
					fo.form_id, nd.node_type_id
		FROM fg_form_owners AS fo
			INNER JOIN cn_nodes AS nd
			ON nd.application_id = vr_application_id AND nd.node_type_id = fo.owner_id
		WHERE fo.application_id = vr_application_id AND nd.node_id = vr_owner_id AND fo.deleted = FALSE;
	END IF;
	
	RETURN QUERY
	SELECT el.element_id,
		   efe.title,
		   el.necessary,
		   efe.type,
		   efe.info
	FROM fg_element_limits AS el
		INNER JOIN fg_extended_form_elements AS efe
		ON efe.application_id = vr_application_id AND 
			efe.element_id = el.element_id AND efe.deleted = FALSE
	WHERE vr_form_id IS NOT NULL AND el.application_id = vr_application_id AND 
		el.owner_id = vr_owner_id AND efe.form_id = vr_form_id AND el.deleted = FALSE
	ORDER BY efe.sequence_number ASC;
END;
$$ LANGUAGE plpgsql;

