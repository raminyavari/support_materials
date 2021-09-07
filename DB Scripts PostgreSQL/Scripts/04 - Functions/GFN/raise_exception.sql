DROP PROCEDURE IF EXISTS gfn_raise_exception;

CREATE OR REPLACE PROCEDURE gfn_raise_exception
(
	vr_value 	INTEGER, 
	vr_message 	VARCHAR
)
AS
$$
BEGIN
	RAISE EXCEPTION '%', COALESCE(vr_message, '')::VARCHAR USING DETAIL = 'RVException', 
		HINT = '{ "Type": "RVException", "Code": ' || COALESCE(vr_value, 0)::VARCHAR || ' }';
END;
$$ LANGUAGE PLPGSQL;