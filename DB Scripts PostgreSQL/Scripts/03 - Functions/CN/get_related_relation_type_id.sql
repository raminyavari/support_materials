DROP FUNCTION IF EXISTS cn_fn_get_related_relation_type_id;

CREATE OR REPLACE FUNCTION cn_fn_get_related_relation_type_id
(
	vr_application_id	UUID
)
RETURNS UUID
AS
$$
BEGIN
	RETURN (
		SELECT "p".property_id
		FROM cn_properties AS "p"
		WHERE "p".application_id = vr_application_id AND "p".additional_id = '3'
		LIMIT 1
	);
END;
$$ LANGUAGE PLPGSQL;