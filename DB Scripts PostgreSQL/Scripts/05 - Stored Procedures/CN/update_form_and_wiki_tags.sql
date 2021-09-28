DROP FUNCTION IF EXISTS cn_update_form_and_wiki_tags;

CREATE OR REPLACE FUNCTION cn_update_form_and_wiki_tags
(
	vr_application_id	UUID,
	vr_node_ids			guid_table_type[],
	vr_creator_user_id	UUID,
	vr_count		 	INTEGER,
	vr_form		 		BOOLEAN,
	vr_wiki		 		BOOLEAN
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_ids		UUID[];
BEGIN
	IF COALESCE(ARRAY_LENGTH(vr_node_ids, 1), 0) = 0 THEN
		vr_ids := ARRAY(
			SELECT nd.node_id
			FROM cn_nodes AS nd
			WHERE nd.application_id = vr_application_id AND nd.deleted = FALSE
			ORDER BY nd.index_last_update_date ASC
			LIMIT COALESCE(vr_count, 200)
		);
	ELSE
		vr_ids := ARRAY(
			SELECT x.value
			FROM UNNEST(vr_node_ids) AS x
		);
	END IF;
	
	IF vr_creator_user_id IS NULL THEN
		SELECT vr_creator_user_id = un.user_id
		FROM users_normal AS un
		WHERE un.application_id = vr_application_id AND LOWER(un.username) = 'admin'
		LIMIT 1;
	END IF;
	
	RETURN cn_p_update_form_and_wiki_tags(vr_application_id, vr_ids, vr_creator_user_id, vr_form, vr_wiki);
END;
$$ LANGUAGE plpgsql;
