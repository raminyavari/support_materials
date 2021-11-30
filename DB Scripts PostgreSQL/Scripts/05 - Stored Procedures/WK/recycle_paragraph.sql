DROP FUNCTION IF EXISTS wk_recycle_paragraph;

CREATE OR REPLACE FUNCTION wk_recycle_paragraph
(
	vr_application_id	UUID,
    vr_paragraph_id 	UUID,
    vr_current_user_id	UUID,
    vr_now				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE wk_paragraphs AS pg
	SET deleted = FALSE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE pg.application_id = vr_application_id AND pg.paragraph_id = vr_paragraph_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

