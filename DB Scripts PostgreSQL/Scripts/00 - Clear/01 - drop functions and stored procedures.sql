DO
$$
DECLARE
	vr_query		VARCHAR;
	vr_err_msg		VARCHAR;
	vr_err_detail	VARCHAR;
	vr_err_hint		VARCHAR;
BEGIN
	SELECT INTO vr_query
		string_agg(format('DROP %s IF EXISTS %s;', 
						  CASE prokind
						  	WHEN 'f' THEN 'FUNCTION'
							WHEN 'a' THEN 'AGGREGATE'
							WHEN 'p' THEN 'PROCEDURE'
							WHEN 'w' THEN 'FUNCTION'  -- window function (rarely applicable)
							-- ELSE NULL              -- not possible in pg 11
							END, oid::regprocedure), E'\n')
	FROM   pg_proc
	WHERE  pronamespace = 'public'::regnamespace AND prokind = ANY ('{f,a,p,w}') AND
		oid::regprocedure::VARCHAR NOT ILIKE '%pgroonga%';
	
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