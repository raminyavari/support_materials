DROP FUNCTION IF EXISTS wk_get_titles_count;

CREATE OR REPLACE FUNCTION wk_get_titles_count
(
	vr_application_id	UUID,
    vr_owner_id			UUID,
	vr_is_admin	 		BOOLEAN,
	vr_current_user_id	UUID,
	vr_removed	 		BOOLEAN
)
RETURNS INTEGER
AS
$$
BEGIN	
	RETURN COALESCE((
		SELECT COUNT(tt.title_id)
		FROM wk_titles AS tt
		WHERE tt.application_id = vr_application_id AND 
			tt.owner_id = vr_owner_id AND (vr_is_admin = TRUE OR tt.status = 'Accepted' OR (
				tt.status = 'CitationNeeded' AND vr_current_user_id IS NOT NULL AND 
				tt.creator_user_id = vr_current_user_id
			)) AND (vr_removed IS NULL OR t.deleted = vr_removed)
	), 0)::INTEGER;
END;
$$ LANGUAGE plpgsql;

