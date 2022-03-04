DROP FUNCTION IF EXISTS fg_set_element_limits;

CREATE OR REPLACE FUNCTION fg_set_element_limits
(
	vr_application_id	UUID,
	vr_owner_id			UUID,
	vr_element_ids		guid_table_type[],
    vr_current_user_id	UUID,
    vr_now				TIMESTAMP
)
RETURNS INTEGER
AS
$$
BEGIN
	UPDATE fg_element_limits
	SET deleted = CASE WHEN e.value IS NULL THEN TRUE ELSE FALSE END::BOOLEAN,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM fg_element_limits AS el
		RIGHT JOIN UNNEST(vr_element_ids) AS e
		ON e.value = el.element_id
	WHERE el.application_id = vr_application_id AND el.owner_id = vr_owner_id;
	
	INSERT INTO fg_element_limits (
		application_id,
		owner_id,
		element_id,
		necessary,
		creator_user_id,
		creation_date,
		deleted
	)
	SELECT 	vr_application_id, 
			vr_owner_id, 
			x.value, 
			COALESCE(efe.necessary, FALSE), 
			vr_current_user_id, 
			vr_now, 
			FALSE
	FROM UNNEST(vr_element_ids) AS x
		LEFT JOIN fg_element_limits AS el
		ON el.application_id = vr_application_id AND 
			el.element_id = x.value AND el.owner_id = vr_owner_id
		INNER JOIN fg_extended_form_elements AS efe
		ON efe.application_id = vr_application_id AND efe.element_id = x.value
	WHERE el.element_id IS NULL;
	
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

