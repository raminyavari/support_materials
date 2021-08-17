DROP VIEW IF EXISTS content_file_extensions;

DROP VIEW IF EXISTS kw_view_content_file_extensions;


CREATE VIEW kw_view_content_file_extensions
AS
SELECT	kw.tree_node_id, 
		kw.application_id,
		kw.knowledge_id, 
		kw.title AS knowledge_title, 
		af.extension,
		kw.deleted
FROM dct_files AS af
	INNER JOIN kw_view_knowledges AS kw
	ON kw.application_id = af.application_id AND kw.knowledge_id = af.owner_id;