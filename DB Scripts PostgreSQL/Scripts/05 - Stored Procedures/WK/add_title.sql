DROP FUNCTION IF EXISTS wk_add_title;

CREATE OR REPLACE FUNCTION wk_add_title
(
	vr_application_id	UUID,
    vr_title_id	 		UUID,
    vr_owner_id			UUID,
    vr_title			VARCHAR(500),
    vr_sequence_no		INTEGER,
    vr_current_user_id	UUID,
    vr_now				TIMESTAMP,
    vr_owner_type		VARCHAR(20),
    vr_accept			BOOLEAN
)
RETURNS INTEGER
AS
$$
BEGIN
	RETURN wk_p_add_title(vr_application_id, vr_title_id, vr_owner_id, vr_title, 
						  vr_sequence_no, vr_current_user_id, vr_now, vr_owner_type, vr_accept);
END;
$$ LANGUAGE plpgsql;

