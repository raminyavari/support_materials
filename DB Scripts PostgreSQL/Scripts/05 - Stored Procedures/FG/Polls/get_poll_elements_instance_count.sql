DROP FUNCTION IF EXISTS fg_get_poll_elements_instance_count;

CREATE OR REPLACE FUNCTION fg_get_poll_elements_instance_count
(
	vr_application_id		UUID,
	vr_poll_id				UUID
)
RETURNS TABLE (
	"id"	UUID, 
	"count"	INTEGER
)
AS
$$
DECLARE
	vr_is_copy_of_poll_id	UUID;
BEGIN
	vr_is_copy_of_poll_id := (
		SELECT "p".is_copy_of_poll_id
		FROM fg_polls AS "p"
		WHERE "p".poll_id = vr_poll_id
		LIMIT 1
	);

	IF vr_is_copy_of_poll_id IS NULL THEN 
		RETURN;
	END IF;

	RETURN QUERY 
	SELECT 	ie.ref_element_id AS "id", 
			COUNT(DISTINCT fi.director_id)::INTEGER AS "count"
	FROM fg_form_instances AS fi
		INNER JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND 
			ie.instance_id = fi.instance_id AND ie.deleted = FALSE AND
			COALESCE(fg_fn_to_string(vr_application_id, ie.element_id, ie.type, 
				ie.text_value, ie.float_value, ie.bit_value, ie.date_value), '') <> ''
		INNER JOIN (
			SELECT rf.element_id
			FROM fg_fn_get_limited_elements(vr_application_id, vr_is_copy_of_poll_id) AS rf
		) AS e
		ON e.element_id = ie.ref_element_id
	WHERE fi.application_id = vr_application_id AND 
		fi.owner_id = vr_poll_id AND fi.deleted = FALSE
	GROUP BY ie.ref_element_id;
END;
$$ LANGUAGE plpgsql;

