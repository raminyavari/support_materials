DROP FUNCTION IF EXISTS fg_p_get_polls_by_ids;

CREATE OR REPLACE FUNCTION fg_p_get_polls_by_ids
(
	vr_application_id	UUID,
	vr_poll_ids			UUID[],
	vr_total_count		INTEGER DEFAULT 0
)
RETURNS SETOF fg_poll_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT	"p".poll_id, 
			"p".is_copy_of_poll_id,
			"p".owner_id,
			"p".name, 
			p2.name AS ref_name,
			"p".description, 
			p2.description AS ref_description, 
			"p".begin_date, 
			"p".finish_date,
			CASE
				WHEN "p".owner_id IS NULL THEN "p".show_summary
				ELSE COALESCE(p2.show_summary, "p".show_summary)::BOOLEAN
			END AS show_summary,
			CASE
				WHEN "p".owner_id IS NULL THEN "p".hide_contributors
				ELSE COALESCE(p2.hide_contributors, "p".hide_contributors)::BOOLEAN
			END AS hide_contributors,
			vr_total_count
	FROM UNNEST(vr_poll_ids) WITH ORDINALITY AS x("id", seq)
		INNER JOIN fg_polls AS "p"
		ON "p".application_id = vr_application_id AND "p".poll_id = x.id
		LEFT JOIN fg_polls AS p2
		ON p2.application_id = vr_application_id AND p2.poll_id = "p".is_copy_of_poll_id
	ORDER BY x.seq ASC;
END;
$$ LANGUAGE plpgsql;

