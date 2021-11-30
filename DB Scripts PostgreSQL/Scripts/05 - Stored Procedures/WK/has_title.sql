DROP FUNCTION IF EXISTS wk_has_title;

CREATE OR REPLACE FUNCTION wk_has_title
(
	vr_application_id	UUID,
    vr_owner_id			UUID,
	vr_viewer_user_id	UUID
)
RETURNS BOOLEAN
AS
$$
BEGIN
	RETURN COALESCE((
		SELECT TRUE
		FROM wk_titles AS "t"
		WHERE "t".application_id = vr_application_id AND "t".owner_id = vr_owner_id AND
			(vr_viewer_user_id IS NULL OR "t".status = 'Accepted' OR 
			"t".status = 'CitationNeeded' OR "t".creator_user_id = vr_viewer_user_id) AND "t".deleted = FALSE
		LIMIT 1
	), FALSE)::BOOLEAN;
END;
$$ LANGUAGE plpgsql;

