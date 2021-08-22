DROP FUNCTION IF EXISTS gfn_like_match;

CREATE OR REPLACE FUNCTION gfn_like_match
(
	vr_input 		VARCHAR(2000),
	vr_string_items VARCHAR[],
	vr_or 			BOOLEAN,
	vr_exact 		BOOLEAN
)
RETURNS BOOLEAN
AS
$$
DECLARE
	vr_ret_val		BOOLEAN = 0;
	vr_count 		INTEGER;
	vr_str 			VARCHAR(10);
	vr_match_count	INTEGER;
BEGIN
	vr_count := COALESCE(ARRAY_LENGTH(vr_string_items), 0);
	vr_str := CASE WHEN vr_exact = TRUE THEN N'' ELSE N'%' END;
	
	vr_match_count := COALESCE((
		SELECT COUNT(*)
		FROM UNNEST(vr_string_items) AS si
		WHERE vr_input ILIKE (vr_str + COALESCE(si, N'') + vr_str)
	), 1);
	
	IF vr_or = TRUE THEN 
		RETURN CASE WHEN vr_match_count > 0 THEN 1 ELSE 0 END;
	ELSE 
		RETURN CASE WHEN vr_match_count = vr_count THEN 1 ELSE 0 END;
	END IF;
END;
$$ LANGUAGE PLPGSQL;