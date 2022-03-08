DROP PROCEDURE IF EXISTS rv_indexes;

CREATE PROCEDURE rv_indexes
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT	ind.name AS name, 
			OBJECT_NAME(ind.object_id) AS table,
			COL_NAME(col.object_id, col.column_id) AS column,
			CAST(col.key_ordinal AS integer) AS order,
			col.is_descending_key AS is_descending,
			is_unique AS is_unique,
			is_unique_constraint AS is_unique_constraint,
			col.is_included_column AS is_included_column,
			type_desc AS index_type
	FROM sys.indexes AS ind
		INNER JOIN sys.index_columns AS col
		ON col.object_id = ind.object_id AND col.index_id = ind.index_id
	WHERE OBJECT_SCHEMA_NAME(ind.object_id) = 'dbo' AND ind.is_primary_key = 0 AND 
		ind.type_desc <> 'HEAP' AND OBJECTPROPERTY(ind.object_id, 'IsTable') = 1
	ORDER BY OBJECT_NAME(ind.object_id)
END;


DROP PROCEDURE IF EXISTS rv_user_defined_table_types;

CREATE PROCEDURE rv_user_defined_table_types
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT	tp.name AS name,
			col.name AS column,
			CAST(col.column_id AS integer) AS order,
			st.name AS data_type,
			CAST(col.is_nullable AS boolean) AS is_nullable,
			CAST(col.is_identity AS boolean) AS is_identity,
			CAST(col.max_length AS integer) AS max_length
	FROM sys.table_types AS tp
		INNER JOIN sys.columns AS col
		ON tp.type_table_object_id = col.object_id
		INNER JOIN sys.systypes AS st  
		ON st.xtype = col.system_type_id
	where tp.is_user_defined = 1 AND st.name <> 'sysname'
	ORDER BY tp.name, col.column_id
END;


DROP PROCEDURE IF EXISTS rv_full_text_indexes;

CREATE PROCEDURE rv_full_text_indexes
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT	OBJECT_NAME(ind.object_id) AS table, 
			c.name AS column,
			t.name AS data_type,
			CAST(c.max_length AS integer) AS max_length,
			CAST(c.is_identity AS boolean) AS is_identity
	FROM sys.fulltext_indexes AS ind
		INNER JOIN sys.fulltext_index_columns AS col
		ON col.object_id = ind.object_id
		INNER JOIN sys.columns AS c
		ON c.object_id = col.object_id AND c.column_id = col.column_id
		INNER JOIN sys.types AS t
		ON c.system_type_id = t.system_type_id
END;