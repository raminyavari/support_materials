DROP FUNCTION IF EXISTS wf_get_owner_auto_messages;

CREATE OR REPLACE FUNCTION wf_get_owner_auto_messages
(
	vr_application_id	UUID,
	vr_owner_ids		guid_table_type[]
)
RETURNS SETOF wf_auto_message_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT *
	FROM wf_p_get_owner_auto_messages(
		vr_application_id, 
		ARRAY(
			SELECT x.value
			FROM UNNEST(vr_owner_ids) AS x
		)
	);
END;
$$ LANGUAGE plpgsql;

