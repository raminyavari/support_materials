DROP FUNCTION IF EXISTS rv_foreign_keys;

CREATE OR REPLACE FUNCTION rv_foreign_keys()
RETURNS TABLE (
	"name"		VARCHAR,
	"table"		VARCHAR, 
	"column"	VARCHAR, 
	ref_table	VARCHAR,
	ref_column	VARCHAR
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT	tc.constraint_name AS "name",
			tc.table_name AS "table", 
			kcu.column_name AS "column", 
			ccu.table_name AS ref_table,
			ccu.column_name AS ref_column
	FROM information_schema.table_constraints AS tc 
		JOIN information_schema.key_column_usage AS kcu
		ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
		JOIN information_schema.constraint_column_usage AS ccu
		ON ccu.constraint_name = tc.constraint_name AND ccu.table_schema = tc.table_schema
	WHERE tc.constraint_type = 'FOREIGN KEY';
END;
$$ LANGUAGE plpgsql;

