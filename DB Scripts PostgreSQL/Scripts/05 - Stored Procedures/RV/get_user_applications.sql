DROP FUNCTION IF EXISTS rv_get_applications;

CREATE OR REPLACE FUNCTION rv_get_applications
(
	vr_user_id		UUID,
	vr_is_creator	BOOLEAN,
	vr_archive 		BOOLEAN
)
RETURNS SETOF rv_application_ret_composite
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT app.application_id
		FROM usr_user_applications AS usr
			INNER JOIN rv_applications AS app
			ON app.application_id = usr.application_id AND 
				(vr_is_creator = FALSE OR app.creator_user_id = vr_user_id) AND
				(vr_archive IS NULL OR COALESCE(app.deleted, FALSE) = vr_archive)
		WHERE usr.user_id = vr_user_id
	);

	RETURN QUERY
	SELECT *
	FROM rv_p_get_applications_by_ids(vr_ids);
END;
$$ LANGUAGE plpgsql;

