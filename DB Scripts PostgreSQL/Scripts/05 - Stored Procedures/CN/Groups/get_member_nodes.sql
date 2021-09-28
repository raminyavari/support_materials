DROP FUNCTION IF EXISTS cn_get_member_nodes;

CREATE OR REPLACE FUNCTION cn_get_member_nodes
(
	vr_application_id			UUID,
    vr_user_ids					guid_table_type[],
    vr_node_type_ids			guid_table_type[],
    vr_node_type_additional_id	VARCHAR(20),
    vr_is_admin			 		BOOLEAN
)
RETURNS SETOF cn_member_ret_composite
AS
$$
DECLARE
	vr_add_id	UUID;
	vr_nt_count	INTEGER;
	vr_members	guid_pair_table_type[];
BEGIN
	IF COALESCE(vr_node_type_additional_id, '') <> '' THEN
		vr_add_id := cn_fn_get_node_type_id(vr_application_id, vr_node_type_additional_id);
		
		IF vr_add_id IS NOT NULL THEN
			vr_node_type_ids := ARRAY(
				SELECT DISTINCT ROW(b.value)
				FROM (
						SELECT x.value
						FROM UNNEST(vr_node_type_ids) AS x

						UNION

						SELECT vr_add_id AS "value"
					) AS b
			);
		END IF;
	END IF;

	vr_nt_count := COALESCE(ARRAY_LENGTH(vr_node_type_ids, 1), 0)::INTEGER;

	vr_members := ARRAY(
		SELECT ROW(nm.node_id, nm.user_id)
		FROM UNNEST(vr_user_ids) AS u
			INNER JOIN cn_view_node_members AS nm 
			ON nm.application_id = vr_application_id AND nm.user_id = u.value
		WHERE (vr_nt_count = 0 OR nm.node_type_id IN (SELECT x.value FROM UNNEST(vr_node_type_ids) AS x)) AND
			(vr_is_admin IS NULL OR nm.is_admin = vr_is_admin) AND nm.is_pending = FALSE
	);
		
	RETURN QUERY
	SELECT *
	FROM cn_p_get_member_nodes(vr_application_id, vr_members);
END;
$$ LANGUAGE plpgsql;
