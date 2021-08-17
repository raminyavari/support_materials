DROP FUNCTION IF EXISTS gfn_verify_string;

CREATE OR REPLACE FUNCTION gfn_verify_string
(
	vr_input_string VARCHAR
)
RETURNS VARCHAR
AS
$$
BEGIN
	IF vr_input_string IS NULL THEN 
		RETURN NULL;
	ELSE 
		RETURN REPLACE(REPLACE(vr_input_string, N'ي', N'ی'), N'ك', N'ک');
	END IF;
END;
$$ LANGUAGE PLPGSQL;