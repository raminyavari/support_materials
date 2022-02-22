DROP FUNCTION IF EXISTS prvc_get_confidentiality_levels;

CREATE OR REPLACE FUNCTION prvc_get_confidentiality_levels
(
	vr_application_id	UUID
)
RETURNS TABLE (
	"id"		UUID,
	level_id	INTEGER,
	title		VARCHAR
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT conf.id,
		   conf.level_id,
		   conf.title
	FROM prvc_confidentiality_levels AS conf
	WHERE conf.application_id = vr_application_id AND conf.deleted = FALSE
	ORDER BY conf.level_id ASC;
END;
$$ LANGUAGE plpgsql;

