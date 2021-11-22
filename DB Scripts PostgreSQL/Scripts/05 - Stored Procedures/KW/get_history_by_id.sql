DROP FUNCTION IF EXISTS kw_get_history_by_id;

CREATE OR REPLACE FUNCTION kw_get_history_by_id
(
	vr_application_id	UUID,
    vr_id				BIGINT
)
RETURNS SETOF kw_history_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT *
	FROM kw_p_get_history_by_ids(vr_application_id, ARRAY(SELECT vr_id));
END;
$$ LANGUAGE plpgsql;

