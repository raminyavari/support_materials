DROP FUNCTION IF EXISTS cn_get_complex_type_id;

CREATE OR REPLACE FUNCTION cn_get_complex_type_id
(
	vr_application_id	UUID,
	vr_list_id			UUID
)
RETURNS UUID
AS
$$
BEGIN
	RETURN (
		SELECT l.node_type_id AS "id"
		FROM cn_lists AS l
		WHERE l.application_id = vr_application_id AND l.list_id = vr_list_id
		LIMIT 1
	);
END;
$$ LANGUAGE plpgsql;

