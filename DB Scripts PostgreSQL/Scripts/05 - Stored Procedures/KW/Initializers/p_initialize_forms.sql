DROP FUNCTION IF EXISTS kw_p_initialize_forms;

CREATE OR REPLACE FUNCTION kw_p_initialize_forms
(
	vr_application_id		UUID,
	vr_admin_id				UUID,
	vr_experience_type_id	UUID,
	vr_skill_type_id		UUID,
	vr_document_type_id		UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_form_id	UUID;
BEGIN
	IF vr_experience_type_id IS NOT NULL AND NOT EXISTS (
		SELECT 1
		FROM fg_form_owners AS fo 
		WHERE fo.application_id = vr_application_id AND fo.owner_id = vr_experience_type_id
		LIMIT 1
	) THEN
		vr_form_id := gen_random_uuid();

		INSERT INTO fg_extended_forms (
			application_id, 
			form_id, 
			title, 
			creator_user_id, 
			creation_date, 
			deleted
		) 
		VALUES (
			vr_application_id, 
			vr_form_id, 
			'فرم ثبت تجربه', 
			vr_admin_id, 
			'2013-04-23 12:10:21.000'::TIMESTAMP, 
			FALSE
		);
		
		INSERT INTO fg_extended_form_elements (
			application_id, 
			element_id, 
			form_id, 
			title, 
			sequence_number, 
			"type", 
			"info", 
			creator_user_id, 
			creation_date, 
			deleted, 
			necessary
		) 
		VALUES (
			vr_application_id, 
			gen_random_uuid(), 
			vr_form_id, 
			'شرح تجربه',
			7, 
			'Text', 
			'{}', 
			vr_admin_id, 
			'2013-04-23 12:10:21.000'::TIMESTAMP, 
			FALSE, 
			TRUE
		);
		
		INSERT INTO fg_extended_form_elements (
			application_id, 
			element_id, 
			form_id, 
			title, 
			sequence_number, 
			"type", 
			"info", 
			creator_user_id, 
			creation_date, 
			deleted, 
			necessary
		) 
		VALUES (
			vr_application_id, 
			gen_random_uuid(), 
			vr_form_id, 
			'کاربرد تجربه',
			9, 
			'Text', 
			'{}', 
			vr_admin_id, 
			'2013-04-23 12:10:21.000'::TIMESTAMP, 
			FALSE, 
			TRUE
		);

		INSERT INTO fg_form_owners (
			application_id, 
			owner_id, 
			form_id, 
			creator_user_id, 
			creation_date, 
			deleted
		)
		VALUES (
			vr_application_id, 
			vr_experience_type_id, 
			vr_form_id, 
			vr_admin_id, 
			NOW(), 
			FALSE
		);
	END IF;


	IF vr_skill_type_id IS NOT NULL AND NOT EXISTS (
		SELECT 1
		FROM fg_form_owners AS fo 
		WHERE fo.application_id = vr_application_id AND fo.owner_id = vr_skill_type_id
		LIMIT 1
	) THEN
		vr_form_id := gen_random_uuid();

		INSERT INTO fg_extended_forms (
			application_id, 
			form_id, 
			title, 
			creator_user_id, 
			creation_date, 
			deleted
		) 
		VALUES (
			vr_application_id, 
			vr_form_id, 
			'فرم ثبت مهارت', 
			vr_admin_id, 
			'2013-04-23 12:10:21.000'::TIMESTAMP, 
			FALSE
		);
		
		INSERT INTO fg_extended_form_elements (
			application_id, 
			element_id, 
			form_id, 
			title, 
			sequence_number, 
			"type", 
			"info", 
			creator_user_id, 
			creation_date, 
			deleted, 
			necessary
		) 
		VALUES (
			vr_application_id, 
			gen_random_uuid(), 
			vr_form_id, 
			'شرح مهارت',
			7, 
			'Text', 
			'{}', 
			vr_admin_id, 
			'2013-04-23 12:10:21.000'::TIMESTAMP, 
			FALSE, 
			TRUE
		);
		
		INSERT INTO fg_extended_form_elements (
			application_id, 
			element_id, 
			form_id, 
			title, 
			sequence_number, 
			"type", 
			"info", 
			creator_user_id, 
			creation_date, 
			deleted, 
			necessary
		) 
		VALUES (
			vr_application_id, 
			gen_random_uuid(), 
			vr_form_id, 
			'کاربرد مهارت',
			9, 
			'Text', 
			'{}', 
			vr_admin_id, 
			'2013-04-23 12:10:21.000'::TIMESTAMP, 
			FALSE, 
			TRUE
		);

		INSERT INTO fg_form_owners (
			application_id, 
			owner_id, 
			form_id, 
			creator_user_id, 
			creation_date, 
			deleted
		)
		VALUES (
			vr_application_id, 
			vr_skill_type_id, 
			vr_form_id, 
			vr_admin_id, 
			NOW(), 
			FALSE
		);
	END IF;


	IF vr_document_type_id IS NOT NULL AND NOT EXISTS (
		SELECT 1
		FROM fg_form_owners AS fo 
		WHERE fo.application_id = vr_application_id AND fo.owner_id = vr_document_type_id
		LIMIT 1
	) THEN
		vr_form_id := gen_random_uuid();

		INSERT INTO fg_extended_forms (
			application_id, 
			form_id, 
			title, 
			creator_user_id, 
			creation_date, 
			deleted
		) 
		VALUES (
			vr_application_id, 
			vr_form_id, 
			'فرم ثبت مستند', 
			vr_admin_id, 
			'2013-04-23 12:10:21.000'::TIMESTAMP, 
			FALSE
		);
		
		INSERT INTO fg_extended_form_elements (
			application_id, 
			element_id, 
			form_id, 
			title, 
			sequence_number, 
			"type", 
			"info", 
			creator_user_id, 
			creation_date, 
			deleted, 
			necessary
		) 
		VALUES (
			vr_application_id, 
			gen_random_uuid(), 
			vr_form_id, 
			'شرح مستند',
			7, 
			'Text', 
			'{}', 
			vr_admin_id, 
			'2013-04-23 12:10:21.000'::TIMESTAMP, 
			FALSE, 
			TRUE
		);
		
		INSERT INTO fg_extended_form_elements (
			application_id, 
			element_id, 
			form_id, 
			title, 
			sequence_number, 
			"type", 
			"info", 
			creator_user_id, 
			creation_date, 
			deleted, 
			necessary
		) 
		VALUES (
			vr_application_id, 
			gen_random_uuid(), 
			vr_form_id, 
			'کاربرد مستند',
			9, 
			'Text', 
			'{}', 
			vr_admin_id, 
			'2013-04-23 12:10:21.000'::TIMESTAMP,
			FALSE, 
			TRUE
		);

		INSERT INTO fg_form_owners (
			application_id, 
			owner_id, 
			form_id, 
			creator_user_id, 
			creation_date, 
			deleted
		)
		VALUES (
			vr_application_id, 
			vr_document_type_id, 
			vr_form_id, 
			vr_admin_id, 
			NOW(), 
			FALSE
		);
	END IF;
	
	RETURN 1;
END;
$$ LANGUAGE plpgsql;

