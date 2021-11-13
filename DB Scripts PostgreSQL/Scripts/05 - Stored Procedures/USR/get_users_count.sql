DROP FUNCTION IF EXISTS usr_get_users_count;

CREATE OR REPLACE FUNCTION usr_get_users_count
(
	vr_application_id		UUID,
	vr_creation_date_from 	TIMESTAMP,
	vr_creation_date_to 	TIMESTAMP
)
RETURNS INTEGER
AS
$$
BEGIN	
	RETURN COALESCE((
		SELECT COUNT(rf.user_id)
		FROM users_normal AS rf
		WHERE rf.application_id = vr_application_id AND rf.is_approved = TRUE AND
			(vr_creation_date_from IS NULL OR rf.creation_date >= vr_creation_date_from) AND
			(vr_creation_date_to IS NULL OR rf.creation_date < vr_creation_date_to)
	), 0)::INTEGER;
END;
$$ LANGUAGE plpgsql;

