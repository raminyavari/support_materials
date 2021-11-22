DROP FUNCTION IF EXISTS kw_edit_history_description;

CREATE OR REPLACE FUNCTION kw_edit_history_description
(
	vr_application_id	UUID,
    vr_id				BIGINT,
    vr_description 		VARCHAR(2000)
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE kw_history AS h
	SET description = gfn_verify_string(vr_description)
	WHERE h.application_id = vr_application_id AND h.id = vr_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

