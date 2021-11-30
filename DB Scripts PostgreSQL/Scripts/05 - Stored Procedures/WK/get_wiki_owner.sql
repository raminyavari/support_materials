DROP FUNCTION IF EXISTS wk_get_wiki_owner;

CREATE OR REPLACE FUNCTION wk_get_wiki_owner
(
	vr_application_id	UUID,
    vr_id				UUID
)
RETURNS TABLE (
	owner_id	UUID, 
	owner_type	VARCHAR
)
AS
$$
DECLARE 
	vr_owner_id 	UUID;
	vr_owner_type 	VARCHAR(20);
BEGIN	
	SELECT 	vr_owner_id = tt.owner_id, 
			vr_owner_type = tt.owner_type
	FROM wk_titles AS tt
	WHERE tt.application_id = vr_application_id AND tt.title_id = vr_id
	LIMIT 1;
	
	IF vr_owner_id IS NULL THEN
		SELECT 	vr_owner_id = tt.owner_id, 
				vr_owner_type = tt.owner_type
		FROM wk_titles AS tt
			INNER JOIN wk_paragraphs AS "p"
			ON "p".application_id = vr_application_id AND "p".title_id = tt.title_id
		WHERE tt.application_id = vr_application_id AND "p".paragraph_id = vr_id
		LIMIT 1;
	END IF;
	
	IF vr_owner_id IS NULL THEN
		SELECT 	vr_owner_id = tt.owner_id, 
				vr_owner_type = tt.owner_type
		FROM wk_titles AS tt
			INNER JOIN wk_paragraphs AS "p"
			ON "p".application_id = vr_application_id AND "p".title_id = tt.title_id
			INNER JOIN wk_changes AS ch
			ON ch.application_id = vr_application_id AND ch.paragraph_id = "p".paragraph_id
		WHERE tt.application_id = vr_application_id AND ch.change_id = vr_id
		LIMIT 1;
	END IF;
	
	RETURN QUERY
	SELECT 	vr_owner_id AS owner_id, 
			vr_owner_type AS owner_type;
END;
$$ LANGUAGE plpgsql;

