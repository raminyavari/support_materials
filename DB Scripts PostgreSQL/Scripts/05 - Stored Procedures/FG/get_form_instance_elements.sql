DROP FUNCTION IF EXISTS fg_get_form_instance_elements;

CREATE OR REPLACE FUNCTION fg_get_form_instance_elements
(
	vr_application_id	UUID,
	vr_instance_ids		guid_table_type[],
	vr_filled		 	BOOLEAN,
	vr_element_ids		guid_table_type[]
)
RETURNS SETOF fg_form_instance_element_ret_composite
AS
$$
DECLARE
	vr_el_count	INTEGER;
BEGIN
	vr_el_count := COALESCE((SELECT COUNT(*) FROM UNNEST(vr_element_ids)), 0)::INTEGER;

	RETURN QUERY
	WITH instances AS
	(
		SELECT DISTINCT x.value AS instance_id
		FROM UNNEST(vr_instance_ids) AS x
	)
	SELECT	ie.element_id,
			ie.instance_id,
			ie.ref_element_id,
			COALESCE(efe.title, ie.title) AS title,
			efe.name,
			efe.help,
			efe.sequence_number,
			efe.type,
			COALESCE(efe.info, ie.info) AS "info",
			efe.weight,
			ie.text_value,
			ie.float_value,
			ie.bit_value,
			ie.date_value,
			TRUE AS filled,
			COALESCE(efe.necessary, FALSE)::BOOLEAN AS necessary,
			efe.unique_value,
			(
				SELECT COUNT("c".id)
				FROM fg_changes AS "c"
				WHERE "c".application_id = vr_application_id AND 
					"c".element_id = ie.element_id AND "c".deleted = FALSE
			)::INTEGER AS editions_count,
			un.user_id AS creator_user_id,
			un.username AS creator_username,
			un.first_name AS creator_first_name,
			un.last_name AS creator_last_name
	FROM instances AS ins
		INNER JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND ie.instance_id = ins.instance_id
		LEFT JOIN fg_extended_form_elements AS efe
		ON efe.application_id = vr_application_id AND efe.element_id = ie.ref_element_id
		LEFT JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = ie.creator_user_id
	WHERE (vr_filled IS NULL OR vr_filled = TRUE) AND ie.deleted = FALSE AND
		(vr_el_count = 0 OR ie.element_id IN (SELECT rf.value FROM UNNEST(vr_element_ids) AS rf))
	
	UNION ALL
	
	SELECT	efe.element_id,
			fi.instance_id,
			NULL AS ref_element_id,
			efe.title,
			efe.name,
			efe.help,
			efe.sequence_number,
			efe.type,
			efe.info,
			efe.weight,
			NULL AS text_value,
			NULL AS float_value,
			NULL AS bit_value,
			NULL AS date_value,
			FALSE AS filled,
			COALESCE(efe.necessary, FALSE)::BOOLEAN AS necessary,
			efe.unique_value,
			0::INTEGER AS editions_count,
			NULL AS creator_user_id,
			NULL AS creator_username,
			NULL AS creator_first_name,
			NULL AS creator_last_name
	FROM instances AS ins
		INNER JOIN fg_form_instances AS fi
		ON fi.application_id = vr_application_id AND fi.instance_id = ins.instance_id
		INNER JOIN fg_extended_form_elements AS efe
		ON efe.application_id = vr_application_id AND efe.form_id = fi.form_id
		LEFT JOIN fg_instance_elements AS ie
		ON ie.application_id = vr_application_id AND ie.instance_id = fi.instance_id AND 
			ie.ref_element_id = efe.element_id AND ie.deleted = FALSE
	WHERE ie.element_id IS NULL AND (vr_filled IS NULL OR vr_filled = FALSE) AND efe.deleted = FALSE AND
		(vr_el_count = 0 OR efe.element_id IN (SELECT rf.value FROM UNNEST(vr_element_ids) AS rf));
END;
$$ LANGUAGE plpgsql;

