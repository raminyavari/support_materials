DROP FUNCTION IF EXISTS wf_get_last_selected_state_id;

CREATE OR REPLACE FUNCTION wf_get_last_selected_state_id
(
	vr_application_id	UUID,
	vr_owner_id			UUID,
	vr_in_state_id		UUID
)
RETURNS UUID
AS
$$
DECLARE
	vr_send_date	TIMESTAMP;
BEGIN
	IF vr_in_state_id IS NULL THEN
		RETURN (
			SELECT h.state_id
			FROM wf_history AS h
			WHERE h.application_id = vr_application_id AND 
				h.owner_id = vr_owner_id AND h.deleted = FALSE
			ORDER BY h.id DESC
			LIMIT 1
		);
	ELSE
		SELECT 	h.send_date 
		INTO 	vr_send_date
		FROM wf_history AS h
		WHERE h.application_id = vr_application_id AND h.owner_id = vr_owner_id AND 
			h.state_id = vr_in_state_id AND h.deleted = FALSE
		ORDER BY h.id DESC
		LIMIT 1;
		
		IF vr_send_date IS NOT NULL THEN
			RETURN (
				SELECT h.state_id
				FROM wf_history AS h
				WHERE h.application_id = vr_application_id AND h.owner_id = vr_owner_id AND 
					h.send_date > vr_send_date AND h.deleted = FALSE
				ORDER BY h.id DESC
				LIMIT 1
			);
		END IF;
	END IF;
END;
$$ LANGUAGE plpgsql;

