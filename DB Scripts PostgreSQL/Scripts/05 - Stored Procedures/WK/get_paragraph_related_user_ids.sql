DROP FUNCTION IF EXISTS wk_get_paragraph_related_user_ids;

CREATE OR REPLACE FUNCTION wk_get_paragraph_related_user_ids
(
	vr_application_id	UUID,
    vr_paragraph_id		UUID
)
RETURNS SETOF UUID
AS
$$
DECLARE
	vr_creator_id 	UUID; 
	vr_modifier_id	UUID;
BEGIN
	SELECT 	vr_creator_id = ph.creator_user_id, 
			vr_modifier_id = ph.last_modifier_user_id
	FROM wk_paragraphs AS ph
	WHERE ph.application_id = vr_application_id AND ph.paragraph_id = vr_paragraph_id;
	
	RETURN QUERY
	WITH "data" AS 
	(
		SELECT vr_creator_id AS "id"
		WHERE vr_creator_id IS NOT NULL
		
		UNION ALL
		
		SELECT vr_modifier_id AS "id"
		WHERE vr_modifier_id IS NOT NULL
		
		UNION ALL
		
		SELECT DISTINCT ch.user_id AS "id"
		FROM wk_changes AS ch
		WHERE ch.application_id = vr_application_id AND ch.paragraph_id = vr_paragraph_id AND 
			(ch.applied = TRUE OR ch.status = 'Accepted')
	)
	SELECT DISTINCT d.id
	FROM "data" AS d
		INNER JOIN users_normal AS usr
		ON usr.user_id = d.id
	WHERE usr.application_id = vr_application_id AND usr.is_approved = TRUE;
END;
$$ LANGUAGE plpgsql;

