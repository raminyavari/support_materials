DROP FUNCTION IF EXISTS wk_get_titles;

CREATE OR REPLACE FUNCTION wk_get_titles
(
	vr_application_id	UUID,
    vr_owner_id			UUID,
	vr_is_admin	 		BOOLEAN,
	vr_viewer_user_id	UUID,
	vr_deleted	 		BOOLEAN
)
RETURNS SETOF wk_title_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_is_admin := COALESCE(vr_is_admin, FALSE)::BOOLEAN;
	vr_deleted := COALESCE(vr_deleted, FALSE)::BOOLEAN;
	
	vr_ids := ARRAY(
		SELECT "t".title_id
		FROM wk_titles AS "t"
			LEFT JOIN wk_paragraphs AS "p"
			ON "p".application_id = vr_application_id AND "p".title_id = "t".title_id AND (
				vr_is_admin = TRUE OR "p".status = 'Accepted' OR "p".status = 'CitationNeeded' OR (
					"p".status = 'Pending' AND vr_viewer_user_id IS NOT NULL AND 
					"p".creator_user_id = vr_viewer_user_id
				)
			) AND "p".deleted = vr_deleted
		WHERE "t".application_id = vr_application_id AND "t".owner_id = vr_owner_id AND (
				vr_is_admin = TRUE OR "t".status = 'Accepted' OR (
					"t".status = 'CitationNeeded' AND vr_viewer_user_id IS NOT NULL AND 
					"t".creator_user_id = vr_viewer_user_id
				) OR "p".paragraph_id IS NOT NULL
			) AND "t".deleted = vr_deleted
		GROUP BY "t".title_id
	);

	RETURN QUERY
	SELECT *
	FROM wk_p_get_titles_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;

