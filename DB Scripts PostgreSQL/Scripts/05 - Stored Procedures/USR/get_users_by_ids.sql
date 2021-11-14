DROP FUNCTION IF EXISTS usr_get_users_by_ids;

CREATE OR REPLACE FUNCTION usr_get_users_by_ids
(
	vr_application_id	UUID,
    vr_user_ids			guid_table_type[]
)
RETURNS SETOF usr_user_ret_composite
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
	FROM usr_p_get_users_by_ids(vr_application_id, vr_ids);
END;
$$ LANGUAGE plpgsql;

