DROP FUNCTION IF EXISTS wk_p_get_changes_by_ids;

CREATE OR REPLACE FUNCTION wk_p_get_changes_by_ids
(
	vr_application_id	UUID,
    vr_change_ids		UUID[],
	vr_total_count		INTEGER DEFAULT 0
)
RETURNS SETOF wk_change_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT "c".change_id,
		   "c".paragraph_id,
		   "c".title,
		   "c".body_text,
		   "c".status,
		   "c".applied,
		   "c".send_date,
		   "c".user_id AS sender_user_id,
		   un.username AS sender_username,
		   un.first_name AS sender_first_name,
		   un.last_name AS sender_last_name,
		   vr_total_count
	FROM UNNEST(vr_change_ids) AS x
		INNER JOIN wk_changes AS "c"
		ON "c".application_id = vr_application_id AND "c".change_id = x
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = "c".user_id;
END;
$$ LANGUAGE plpgsql;

