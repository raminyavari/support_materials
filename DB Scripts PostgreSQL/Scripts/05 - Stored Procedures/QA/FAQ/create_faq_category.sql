DROP FUNCTION IF EXISTS qa_create_faq_category;

CREATE OR REPLACE FUNCTION qa_create_faq_category
(
	vr_application_id	UUID,
    vr_category_id		UUID,
	vr_parent_id		UUID,
	vr_name		 		VARCHAR(200),
    vr_current_user_id	UUID,
    vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_seq_no	INTEGER;
	vr_result	INTEGER;
BEGIN
	vr_seq_no := COALESCE((
		SELECT MAX(fc.sequence_number) 
		FROM qa_faq_categories AS fc
		WHERE fc.application_id = vr_application_id AND 
			((fc.parent_id IS NULL AND vr_parent_id IS NULL) OR (fc.parent_id = vr_parent_id))
	), 0)::INTEGER + 1::INTEGER;
	
	INSERT INTO qa_faq_categories (
		application_id,
		category_id,
		parent_id,
		sequence_number,
		"name",
		creator_user_id,
		creation_date,
		deleted
	)
	VALUES (
		vr_application_id,
		vr_category_id,
		vr_parent_id,
		vr_seq_no,
		gfn_verify_string(vr_name),
		vr_current_user_id,
		vr_now,
		FALSE
	);
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

