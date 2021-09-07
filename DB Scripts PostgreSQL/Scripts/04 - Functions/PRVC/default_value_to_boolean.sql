DROP FUNCTION IF EXISTS prvc_fn_default_value_to_boolean;

CREATE OR REPLACE FUNCTION prvc_fn_default_value_to_boolean
(
	vr_value	VARCHAR(20)
)
RETURNS BOOLEAN
AS
$$
BEGIN
	RETURN CASE
		WHEN COALESCE(vr_value, N'') = N'Public' THEN TRUE
		WHEN COALESCE(vr_value, N'') <> N'' THEN FALSE
		ELSE NULL
	END;
END;
$$ LANGUAGE PLPGSQL;