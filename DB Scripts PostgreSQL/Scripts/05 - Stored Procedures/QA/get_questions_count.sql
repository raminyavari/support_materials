DROP FUNCTION IF EXISTS qa_get_questions_count;

CREATE OR REPLACE FUNCTION qa_get_questions_count
(
	vr_application_id		UUID,
    vr_published			BOOLEAN,
    vr_creation_date_from	TIMESTAMP,
    vr_creation_date_to 	TIMESTAMP
)
RETURNS INTEGER
AS
$$
BEGIN
	RETURN COALESCE((
		SELECT COUNT(*) 
		FROM qa_questions AS q
		WHERE q.application_id = vr_application_id AND
			(vr_creation_date_from IS NULL OR q.send_date >= vr_creation_date_from) AND
			(vr_creation_date_to IS NULL OR q.send_date < vr_creation_date_to) AND
			(COALESCE(vr_published, FALSE) = FALSE OR (vr_published = TRUE AND q.publication_date IS NOT NULL)) AND 
			q.deleted = FALSE
	), 0)::INTEGER;
END;
$$ LANGUAGE plpgsql;

