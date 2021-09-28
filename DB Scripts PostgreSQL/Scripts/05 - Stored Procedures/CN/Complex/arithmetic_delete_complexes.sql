DROP FUNCTION IF EXISTS cn_arithmetic_delete_complexes;

CREATE OR REPLACE FUNCTION cn_arithmetic_delete_complexes
(
	vr_application_id	UUID,
    vr_list_ids			guid_table_type[],
    vr_current_user_id	UUID,
    vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE cn_lists
	SET deleted = TRUE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	FROM UNNEST(vr_list_ids) AS external_ids
		INNER JOIN cn_lists AS l
		ON l.application_id = vr_application_id AND l.list_id = external_ids.value AND l.deleted = FALSE;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;

	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
