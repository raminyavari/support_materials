DROP FUNCTION IF EXISTS usr_get_honor_or_award;

CREATE OR REPLACE FUNCTION usr_get_honor_or_award
(
	vr_application_id 	UUID,
    vr_id				UUID
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
	WHERE hnr.application_id = vr_application_id AND hnr.id = vr_id;
END;
$$ LANGUAGE plpgsql;

