DROP FUNCTION IF EXISTS wk_modify_title;

CREATE OR REPLACE FUNCTION wk_modify_title
(
	vr_application_id	UUID,
    vr_title_id 		UUID,
    vr_title			VARCHAR(500),
    vr_current_user_id	UUID,
    vr_now 				TIMESTAMP,
    vr_accept			BOOLEAN
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_status	VARCHAR(20);
	vr_result	INTEGER;
BEGIN
	vr_title := gfn_verify_string(LTRIM(RTRIM(vr_title)));
	
	IF COALESCE(vr_title, '') = '' THEN
		RETURN -1::INTEGER;
	END IF;
	
	IF vr_accept = TRUE THEN
		vr_status := 'Accepted';
	ELSE
		vr_status := 'CitationNeeded';
	END IF;
	
	UPDATE wk_titles AS tt
	SET title = vr_title,
		status = vr_status,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE tt.application_id = vr_application_id AND tt.title_id = vr_title_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

