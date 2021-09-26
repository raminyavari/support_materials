DROP FUNCTION IF EXISTS cn_get_users_expertise_domain_ids;

CREATE OR REPLACE FUNCTION cn_get_users_expertise_domain_ids
(
	vr_application_id	UUID,
    vr_user_ids			guid_table_type[],
    vr_approved	 		BOOLEAN,
    vr_social_approved 	BOOLEAN
)
RETURNS SETOF UUID
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT x.value
		FROM UNNEST(vr_user_ids) AS x
	);

	RETURN QUERY
	SELECT *
	FROM cn_p_get_users_expertise_domain_ids(vr_application_id, vr_ids, vr_approved, vr_social_approved);
END;
$$ LANGUAGE plpgsql;
