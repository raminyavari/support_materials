DROP FUNCTION IF EXISTS usr_get_items_visits_count;

CREATE OR REPLACE FUNCTION usr_get_items_visits_count
(
	vr_application_id	UUID,
	vr_item_ids			guid_table_type[],
    vr_lower_date_limit TIMESTAMP,
    vr_upper_date_limit TIMESTAMP
)
RETURNS TABLE (
	item_id			UUID,
	visits_count	INTEGER
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT 	v.item_id,
			COUNT(v.item_id)::INTEGER AS visits_count 
	FROM UNNEST(vr_item_ids) AS ids
		INNER JOIN usr_item_visits AS v
		ON v.application_id = vr_application_id AND v.item_id = ids.value AND
			(vr_lower_date_limit IS NULL OR v.visit_date >= vr_lower_date_limit) AND
			(vr_upper_date_limit IS NULL OR v.visit_date < vr_upper_date_limit)
	GROUP BY v.item_id;
END;
$$ LANGUAGE plpgsql;

