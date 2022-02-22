DROP FUNCTION IF EXISTS prvc_get_audience_role_ids;

CREATE OR REPLACE FUNCTION prvc_get_audience_role_ids
(
	vr_application_id	UUID,
	vr_object_id		UUID
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT rf.role_id AS "id"
	FROM prvc_audience AS rf
	WHERE rf.application_id = vr_application_id AND 
		rf.object_id = vr_object_id AND rf.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;

