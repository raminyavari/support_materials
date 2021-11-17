DROP FUNCTION IF EXISTS usr_get_honors_and_awards;

CREATE OR REPLACE FUNCTION usr_get_honors_and_awards
(
	vr_application_id 	UUID,
    vr_user_id			UUID
)
RETURNS TABLE (
	"id"		UUID,
	user_id		UUID,
	title		VARCHAR,
	issuer		VARChAR,
	occupation	VARCHAR,
	issue_date	TIMESTAMP,
	description	VARCHAR
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT 	hnr.id,
			hnr.user_id,
			hnr.title,
			hnr.issuer,
			hnr.occupation,
			hnr.issue_date,
			hnr.description
	FROM usr_honors_and_awards AS hnr
	WHERE hnr.application_id = vr_application_id AND hnr.user_id = vr_user_id AND deleted = FALSE
	ORDER BY hnr.issue_date DESC;
END;
$$ LANGUAGE plpgsql;

