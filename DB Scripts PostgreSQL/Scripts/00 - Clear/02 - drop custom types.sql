DO
$$
DECLARE
	vr_query		VARCHAR;
	vr_err_msg		VARCHAR;
	vr_err_detail	VARCHAR;
	vr_err_hint		VARCHAR;
BEGIN
	SELECT INTO vr_query
		string_agg(format('DROP TYPE IF EXISTS %s;', "t".typname), E'\n')
	FROM pg_type AS "t"
		LEFT JOIN pg_catalog.pg_namespace AS n 
		ON n.oid = "t".typnamespace 
	WHERE ("t".typrelid = 0 OR (
			SELECT "c".relkind = 'c' 
			FROM pg_catalog.pg_class AS "c" 
			WHERE "c".oid = "t".typrelid
		)) AND NOT EXISTS (
			SELECT 1 
			FROM pg_catalog.pg_type AS el 
			WHERE el.oid = "t".typelem AND el.typarray = "t".oid
		) AND n.nspname NOT IN ('pg_catalog', 'information_schema')
		AND n.nspname = 'public' AND "t".typname NOT ILIKE '%pgroonga%';
	
	IF COALESCE(vr_query, '') != '' THEN
		EXECUTE vr_query;
	END IF;
EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS vr_err_msg := MESSAGE_TEXT,
							vr_err_detail := PG_EXCEPTION_DETAIL,
							vr_err_hint := PG_EXCEPTION_HINT;

	RAISE NOTICE 'Message: %, Detail: %, Hint: %', vr_err_msg, vr_err_detail, vr_err_hint;
END;
$$ LANGUAGE plpgsql;