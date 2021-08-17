DROP VIEW IF EXISTS cn_view_tag_relations_wiki_context;

CREATE VIEW cn_view_tag_relations_wiki_context
AS
SELECT DISTINCT	
		ti.application_id,
		context.node_id AS context_id,
		ti.tagged_id,
		ti.tagged_type
FROM rv_tagged_items AS ti
	INNER JOIN wk_paragraphs AS p
	ON p.application_id = ti.application_id AND p.paragraph_id = ti.context_id
	INNER JOIN wk_titles AS t
	ON t.application_id = ti.application_id AND t.title_id = p.title_id
	INNER JOIN cn_nodes AS context
	ON context.application_id = ti.application_id AND context.node_id = t.owner_id
WHERE ti.tagged_type IN (N'Node', N'User') AND  p.deleted = FALSE AND 
	(p.status = N'Accepted' OR p.status = N'CitationNeeded') AND t.deleted = FALSE;