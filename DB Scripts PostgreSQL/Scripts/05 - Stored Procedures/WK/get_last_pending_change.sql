DROP FUNCTION IF EXISTS wk_get_last_pending_change;

CREATE OR REPLACE FUNCTION wk_get_last_pending_change
(
	vr_application_id	UUID,
    vr_paragraph_id		UUID,
	vr_user_id			UUID
)
RETURNS SETOF wk_change_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT ch.change_id 
		FROM wk_changes AS ch
		WHERE ch.application_id = vr_application_id AND ch.paragraph_id = vr_paragraph_id AND 
			ch.user_id = vr_user_id AND ch.deleted = FALSE AND ch.status = 'Pending'
	);

	RETURN QUERY
	SELECT *
	FROM wk_p_get_changes_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;

