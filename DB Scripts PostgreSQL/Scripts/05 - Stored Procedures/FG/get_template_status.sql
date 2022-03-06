DROP FUNCTION IF EXISTS fg_get_template_status;

CREATE OR REPLACE FUNCTION fg_get_template_status
(
	vr_application_id		UUID,
	vr_ref_application_id	UUID,
	vr_template_ids			guid_table_type[]
)
RETURNS TABLE (
	template_id						UUID,
	template_name					VARCHAR,
	activated_id					UUID,
	activated_name					VARCHAR,
	activation_date					TIMESTAMP,
	activator_user_id				UUID,
	activator_username				VARCHAR,
	activator_first_name			VARCHAR,
	activator_last_name				VARCHAR,
	template_elements_count			INTEGER,
	elements_count					INTEGER,
	new_template_elements_count		INTEGER,
	removed_template_elements_count	INTEGER,
	new_custom_elements_count		INTEGER
)
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT DISTINCT x.value
		FROM UNNEST(vr_template_ids) AS x
	);
	
	RETURN QUERY
	SELECT	MAX(rnt.node_type_id::VARCHAR(50))::UUID AS template_id,
			MAX(rnt.name) AS template_name,
			MAX(nt.node_type_id::VARCHAR(50))::UUID AS activated_id,
			MAX(nt.name) AS activated_name,
			MAX(nt.creation_date) AS activation_date,
			MAX(usr.user_id::VARCHAR(50))::UUID AS activator_user_id,
			MAX(usr.username) AS activator_username,
			MAX(usr.first_name) AS activator_first_name,
			MAX(usr.last_name) AS activator_last_name,
			COUNT(DISTINCT 
				  CASE 
				  	WHEN elems.ref_deleted = FALSE THEN elems.ref_element_id 
				  	ELSE NULL 
				  END
			)::INTEGER AS template_elements_count,
			COUNT(DISTINCT 
				  CASE 
				  	WHEN elems.deleted = FALSE THEN elems.element_id 
				  	ELSE NULL 
				  END
			)::INTEGER AS elements_count,
			COUNT(DISTINCT
				CASE
					WHEN elems.ref_element_id IS NOT NULL AND elems.ref_deleted = FALSE AND 
				  		elems.element_id IS NULL THEN elems.ref_element_id
					ELSE NULL
				END
			)::INTEGER AS new_template_elements_count,
			COUNT(DISTINCT
				CASE
					WHEN elems.ref_element_id IS NOT NULL AND elems.element_id IS NOT NULL AND 
						elems.ref_deleted = TRUE AND elems.deleted = FALSE THEN elems.ref_element_id
					ELSE NULL
				END
			)::INTEGER AS removed_template_elements_count,
			COUNT(DISTINCT
				CASE
					WHEN elems.ref_element_id IS NULL AND elems.element_id IS NOT NULL AND 
				  		elems.deleted = FALSE THEN elems.element_id
					ELSE NULL
				END
			)::INTEGER AS new_custom_elements_count
	FROM UNNEST(vr_ids) AS "t" 
		INNER JOIN fg_extended_forms AS rf
		ON rf.application_id = vr_ref_application_id AND rf.form_id = "t"
		INNER JOIN fg_extended_forms AS f
		ON f.application_id = vr_application_id AND f.template_form_id = rf.form_id
		INNER JOIN fg_form_owners AS ro
		ON ro.application_id = vr_ref_application_id AND ro.form_id = rf.form_id AND ro.deleted = FALSE
		INNER JOIN cn_node_types AS rnt
		ON rnt.application_id = vr_ref_application_id AND rnt.node_type_id = ro.owner_id AND rnt.deleted = FALSE
		INNER JOIN fg_form_owners AS o
		ON o.application_id = vr_application_id AND o.form_id = f.form_id AND o.deleted = FALSE
		INNER JOIN cn_node_types AS nt
		ON nt.application_id = vr_application_id AND nt.node_type_id = o.owner_id AND nt.deleted = FALSE
		INNER JOIN usr_view_users AS usr
		ON usr.user_id = nt.creator_user_id
		INNER JOIN (
			SELECT	re.application_id AS ref_app_id, 
					re.form_id AS ref_form_id,
					re.element_id AS ref_element_id,
					COALESCE(re.deleted, FALSE)::BOOLEAN AS ref_deleted,
					e.application_id AS app_id,
					e.form_id AS form_id,
					e.element_id AS element_id,
					COALESCE(e.deleted, FALSE)::BOOLEAN AS deleted
			FROM fg_extended_form_elements AS re
				FULL OUTER JOIN fg_extended_form_elements AS e
				ON e.template_element_id = re.element_id
			WHERE (re.application_id IS NULL OR re.application_id = vr_ref_application_id) AND
				(e.application_id IS NULL OR e.application_id = vr_application_id)
		) AS elems
		ON (elems.ref_form_id = rf.form_id AND (elems.form_id IS NULL OR elems.form_id = f.form_id)) OR 
			(elems.form_id = f.form_id AND (elems.ref_form_id IS NULL OR elems.ref_form_id = rf.form_id))
	GROUP BY rf.form_id, f.form_id;
END;
$$ LANGUAGE plpgsql;

