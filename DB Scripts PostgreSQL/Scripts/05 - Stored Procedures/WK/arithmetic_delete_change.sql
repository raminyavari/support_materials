DROP FUNCTION IF EXISTS wk_arithmetic_delete_change;

CREATE OR REPLACE FUNCTION wk_arithmetic_delete_change
(
	vr_application_id		UUID,
    vr_change_id			UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE wk_changes AS ch
	SET deleted = TRUE
	WHERE ch.application_id = vr_application_id AND ch.change_id = vr_change_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

