DROP FUNCTION IF EXISTS fg_p_add_poll;

CREATE OR REPLACE FUNCTION fg_p_add_poll
(
	vr_application_id		UUID,
	vr_poll_id				UUID,
	vr_copy_from_poll_id	UUID,
	vr_owner_id				UUID,
	vr_name		 			VARCHAR(255),
	vr_current_user_id		UUID,
	vr_now		 			TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF vr_poll_id = vr_copy_from_poll_id THEN
		RETURN -1::INTEGER;
	END IF;
	
	INSERT INTO fg_polls (
		application_id,
		poll_id,
		is_copy_of_poll_id,
		owner_id,
		"name",
		show_summary,
		hide_contributors,
		creator_user_id,
		creation_date,
		deleted
	)
	SELECT	vr_application_id, 
			vr_poll_id, 
			vr_copy_from_poll_id, 
			vr_owner_id,
			gfn_verify_string(vr_name), 
			COALESCE("p".show_summary, 1),
			COALESCE(p.hide_contributors, 0),
			vr_current_user_id, 
			vr_now,
			FALSE
	FROM (
			SELECT vr_copy_from_poll_id AS "id"
		) AS rf
		LEFT JOIN fg_polls AS "p"
		ON "p".application_id = vr_application_id AND "p".poll_id = rf.id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

