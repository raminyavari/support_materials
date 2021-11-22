DROP FUNCTION IF EXISTS kw_get_feedbacks_by_ids;

CREATE OR REPLACE FUNCTION kw_get_feedbacks_by_ids
(
	vr_application_id	UUID,
    vr_feedback_ids		big_int_table_type[]
)
RETURNS SETOF kw_feedback_ret_composite
AS
$$
DECLARE
	vr_ids	BIGINT[];
BEGIN
	vr_ids := ARRAY(
		SELECT x.value
		FROM UNNEST(vr_feedback_ids) AS x
	);

	RETURN QUERY
	SELECT *
	FROM kw_p_get_feedbacks_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;

