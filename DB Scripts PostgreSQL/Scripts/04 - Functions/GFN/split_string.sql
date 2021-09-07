DROP FUNCTION IF EXISTS gfn_split_string;

CREATE OR REPLACE FUNCTION gfn_split_string
(
	vr_input_string VARCHAR,
	vr_delimiter	VARCHAR(50)
)
RETURNS VARCHAR[]
AS
$$
BEGIN
	RETURN ARRAY(
		SELECT LTRIM(RTRIM(x))
		FROM UNNEST(STRING_TO_ARRAY(vr_input_string, vr_delimiter)) AS x
		WHERE LTRIM(RTRIM(COALESCE(x, N''))) <> N''
	);
END;
$$ LANGUAGE PLPGSQL;