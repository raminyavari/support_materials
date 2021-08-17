DROP VIEW IF EXISTS prvc_view_confidentialities;

CREATE VIEW prvc_view_confidentialities
AS
SELECT  s.application_id,
		s.object_id,
		cl.id AS confidentiality_id,
		cl.level_id,
		cl.title AS level
FROM    prvc_confidentiality_levels AS cl
		INNER JOIN prvc_settings AS s
		ON s.application_id = cl.application_id AND s.confidentiality_id = cl.id
WHERE cl.deleted = FALSE AND s.confidentiality_id IS NOT NULL;