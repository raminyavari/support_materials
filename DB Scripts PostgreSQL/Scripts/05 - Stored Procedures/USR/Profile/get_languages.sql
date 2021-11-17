DROP FUNCTION IF EXISTS usr_get_languages;

CREATE OR REPLACE FUNCTION usr_get_languages
(
	vr_application_id 	UUID,
    vr_language_ids		guid_table_type[]
)
RETURNS TABLE (
	language_id		UUID,
	language_name	VARCHAR
)
AS
$$
DECLARE
	vr_get_all	BOOLEAN;
BEGIN
	vr_get_all := CASE WHEN COALESCE(ARRAY_LENGTH(vr_language_ids, 1), 0) = 0 THEN TRUE ELSE FALSE END;
	
	RETURN QUERY
	SELECT 	"ln".language_id,
			"ln".language_name
	FROM usr_language_names AS "ln"
		LEFT JOIN UNNEST(vr_language_ids) AS l
		ON l.value = "ln".language_id
	WHERE "ln".application_id = vr_application_id AND (vr_get_all = TRUE OR l.value = "ln".language_id)
	ORDER BY "ln".language_name;
END;
$$ LANGUAGE plpgsql;

