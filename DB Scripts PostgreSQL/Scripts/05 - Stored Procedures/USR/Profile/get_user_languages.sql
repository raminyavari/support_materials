DROP FUNCTION IF EXISTS usr_get_user_languages;

CREATE OR REPLACE FUNCTION usr_get_user_languages
(
	vr_application_id 	UUID,
    vr_user_id			UUID
)
RETURNS TABLE (
	"id"			UUID,
	user_id			UUID,
	language_name	VARCHAR,
	"level"			VARCHAR
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT 	ul.id,
			ul.user_id,
			"ln".language_name,
			ul.level
	FROM usr_user_languages AS ul
		INNER JOIN usr_language_names AS "ln"
		ON "ln".application_id = vr_application_id AND "ln".language_id = ul.language_id
	WHERE ul.application_id = vr_application_id AND ul.user_id = vr_user_id AND ul.deleted = FALSE
	ORDER BY "ln".language_name DESC;
END;
$$ LANGUAGE plpgsql;

