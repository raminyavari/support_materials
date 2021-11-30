DROP FUNCTION IF EXISTS wk_get_paragraph_changes;

CREATE OR REPLACE FUNCTION wk_get_paragraph_changes
(
	vr_application_id	UUID,
    vr_paragraph_ids	guid_table_type[],
	vr_creator_user_id	UUID,
	vr_status			VARCHAR(20),
	vr_applied		 	BOOLEAN
)
RETURNS SETOF wk_change_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_paragraph_ids := ARRAY(
		SELECT DISTINCT x
		FROM UNNEST(vr_paragraph_ids) AS x
	);

	vr_ids := ARRAY(
		SELECT DISTINCT ch.change_id
		FROM UNNEST(vr_paragraph_ids) AS ex
			INNER JOIN wk_changes AS ch
			ON ch.paragraph_id = ex.value
		WHERE ch.application_id = vr_application_id AND 
			(vr_creator_user_id IS NULL OR ch.user_id = vr_creator_user_id) AND
			(vr_status IS NULL OR ch.status = vr_status) AND
			(vr_applied IS NULL OR ch.applied = vr_applied) AND ch.deleted = FALSE
	);

	RETURN QUERY
	SELECT *
	FROM wk_p_get_changes_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;

