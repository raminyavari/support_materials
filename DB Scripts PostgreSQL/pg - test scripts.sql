
DROP FUNCTION IF EXISTS func_test;
DROP FUNCTION IF EXISTS func_test_2;
DROP FUNCTION IF EXISTS func_test_3;

CREATE OR REPLACE FUNCTION func_test()
RETURNS SETOF REFCURSOR
AS
$$
	DECLARE
		rf	REFCURSOR;
		rf2	REFCURSOR;
	BEGIN
		OPEN rf FOR 
		SELECT 	1::int as "int",
				1::bigint as "bigint",
				1.1::float AS "float",
				TRUE::boolean as "bool",
				'1'::char as "char",
				NOW()::timestamp as "time",
				'ramin'::varchar as "varchar",
				'ramin'::text as "string",
				gen_random_uuid() as "guid",
				null as "null",
				'ramin'::bytea as "bytea",
				null::int as "nullint";
      	RETURN NEXT rf;
		
		OPEN rf2 FOR SELECT * FROM cn_node_types LIMIT 10;
      	RETURN NEXT rf2;
		
		RETURN;
	END;
$$ LANGUAGE PLPGSQL;


CREATE OR REPLACE FUNCTION func_test_2(
	a int, 
	b bigint, 
	c float, 
	d boolean,
	e char,
	f timestamp,
	g varchar,
	h text,
	i uuid,
	j bytea
)
RETURNS SETOF REFCURSOR
AS
$$
	DECLARE
		rf	REFCURSOR;
		rf2	REFCURSOR;
	BEGIN
		OPEN rf FOR 
		SELECT 	1::int as "int",
				1::bigint as "bigint",
				1.1::float AS "float",
				TRUE::boolean as "bool",
				'1'::char as "char",
				NOW()::timestamp as "time",
				'ramin' as "varchar",
				'ramin' as "string",
				gen_random_uuid() as "guid",
				null as "null",
				'ramin'::bytea as "bytea",
				null::int as "nullint";
      	RETURN NEXT rf;
		
		OPEN rf2 FOR SELECT * FROM cn_node_types LIMIT 10;
      	RETURN NEXT rf2;
		
		RETURN;
	END;
$$ LANGUAGE PLPGSQL;


CREATE OR REPLACE FUNCTION func_test_3(
	a int, 
	b guid_table_type[]
)
RETURNS SETOF REFCURSOR
AS
$$
	DECLARE
		arr ALIAS FOR b;
		rf	REFCURSOR;
	BEGIN
		OPEN rf FOR 
		SELECT a, UNNEST(b);
      	RETURN NEXT rf;
		
		RETURN;
	END;
$$ LANGUAGE PLPGSQL;




DROP FUNCTION IF EXISTS func_test_4;

CREATE OR REPLACE FUNCTION func_test_4()
RETURNS INTEGER
AS
$$
BEGIN
	RETURN 10;
END;
$$ LANGUAGE PLPGSQL;


DROP FUNCTION IF EXISTS func_test_5;

CREATE OR REPLACE FUNCTION func_test_5()
RETURNS TABLE (
	first_name	varchar,
	last_name	varchar
)
AS
$$
BEGIN
	RETURN QUERY (
		SELECT 'ramin'::varchar, 'yavari'::varchar
		UNION
		SELECT 'gesi', 'chaghochi'
	);
END;
$$ LANGUAGE PLPGSQL;


DROP FUNCTION IF EXISTS func_test_7;

CREATE OR REPLACE FUNCTION func_test_7()
RETURNS TABLE (
	int_value int,
	uuid_value uuid,
	uuid_value2 uuid
)
AS
$$
DECLARE
	arr UUID[];
	arr2 guid_table_type[];
BEGIN
	arr := ARRAY(
		SELECT gen_random_uuid()
		UNION ALL
		SELECT gen_random_uuid()
	);
	
	arr := array_cat(arr, ARRAY(
		SELECT gen_random_uuid()
		UNION ALL
		SELECT gen_random_uuid()
	));
	
	arr2 := ARRAY(
		SELECT ROW(gen_random_uuid())
	);
	

	RETURN QUERY
	SELECT 22::integer, y, (arr2[1]).value
	FROM UNNEST(arr) AS x
		INNER JOIN UNNEST(arr) AS y
		ON x = y;
END;
$$ LANGUAGE PLPGSQL;
