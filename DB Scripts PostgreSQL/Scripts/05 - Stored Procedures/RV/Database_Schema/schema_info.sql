DROP FUNCTION IF EXISTS rv_schema_info;

CREATE OR REPLACE FUNCTION rv_schema_info()
RETURNS TABLE (
	"table"			VARCHAR,
	"column"		VARCHAR,
	is_primary_key	BOOLEAN,
	is_identity		BOOLEAN,
	is_nullable		BOOLEAN,
	data_type		VARCHAR,
	max_length		INTEGER,
	"order"			INTEGER,
	default_value	VARCHAR
)
AS
$$
BEGIN
	RETURN QUERY
	WITH all_columns AS
	(
		SELECT 	clm.table_name AS "table",
				clm.column_name AS "column",
				CASE WHEN clm.column_default ILIKE '%nextval%' THEN TRUE ELSE FALSE END::BOOLEAN AS is_identity,
				CASE WHEN clm.is_nullable = 'YES' THEN TRUE ELSE FALSE END::BOOLEAN AS is_nullable, 
				UPPER(clm.data_type) AS data_type, 
				clm.character_maximum_length AS max_length,
				clm.ordinal_position AS "order",
				CASE
					WHEN clm.column_default ILIKE '%nextval%' THEN NULL::VARCHAR
					ELSE clm.column_default
				END AS default_value
		FROM information_schema.tables AS tbl
			INNER JOIN information_schema.columns AS clm
			ON clm.table_name = tbl.table_name
		WHERE tbl.table_type = 'BASE TABLE' AND tbl.table_schema = 'public'
	), 
	primary_keys AS
	(
		SELECT 	ccu.table_name, 
				ccu.column_name
		FROM information_schema.table_constraints AS cnt
			INNER JOIN information_schema.constraint_column_usage AS ccu
			ON ccu.constraint_name = cnt.constraint_name
		WHERE cnt.constraint_type = 'PRIMARY KEY'
	)
	SELECT 	ac.table,
			ac.column,
			CASE
				WHEN EXISTS (SELECT 1 FROM primary_keys AS pk WHERE pk.table_name = ac.table AND pk.column_name = ac.column) THEN TRUE
				ELSE FALSE
			END::BOOLEAN AS is_primary_key,
			ac.is_identity,
			ac.is_nullable,
			ac.data_type,
			ac.max_length,
			ac.order,
			ac.default_value
	FROM all_columns AS ac;
END;
$$ LANGUAGE plpgsql;

