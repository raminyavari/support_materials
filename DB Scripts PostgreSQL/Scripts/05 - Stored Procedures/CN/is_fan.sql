DROP FUNCTION IF EXISTS cn_is_fan;

CREATE OR REPLACE FUNCTION cn_is_fan
(
	vr_application_id	UUID,
	vr_node_ids			guid_table_type[],
    vr_user_id			UUID
)
RETURNS SETOF UUID
AS
$$
BEGIN
	SELECT rf.value AS "id"
	FROM UNNEST(vr_node_ids) AS rf
		INNER JOIN cn_node_likes AS nl
		ON nl.application_id = vr_application_id AND nl.node_id = rf.value AND
			nl.user_id = vr_user_id AND nl.deleted = FALSE;
END;
$$ LANGUAGE plpgsql;
