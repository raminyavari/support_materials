DROP FUNCTION IF EXISTS ntfn_get_owner_message_templates;

CREATE OR REPLACE FUNCTION ntfn_get_owner_message_templates
(
	vr_application_id	UUID,
	vr_owner_ids		guid_table_type[]
)
RETURNS SETOF ntfn_message_template_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT *
	FROM ntfn_p_get_owner_message_templates(vr_application_id, ARRAY(
		SELECT x.value
		FROM UNNEST(vr_owner_ids) AS x
	));
END;
$$ LANGUAGE plpgsql;

