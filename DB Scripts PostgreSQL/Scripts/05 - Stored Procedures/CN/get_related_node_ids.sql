DROP FUNCTION IF EXISTS cn_get_related_node_ids;

CREATE OR REPLACE FUNCTION cn_get_related_node_ids
(
	vr_application_id		UUID,
	vr_node_id_or_user_id	UUID,
	vr_related_node_type_id	UUID,
	vr_search_text		 	VARCHAR(1000),
	vr_in				 	BOOLEAN,
	vr_out			 		BOOLEAN,
	vr_in_tags			 	BOOLEAN,
	vr_out_tags		 		BOOLEAN,
	vr_count			 	INTEGER,
	vr_lower_boundary	 	INTEGER
)
RETURNS SETOF UUID
AS
$$
BEGIN
	RETURN QUERY
	SELECT *
	FROM cn_p_get_related_node_ids(vr_application_id, vr_node_id_or_user_id, vr_related_node_type_id,
								  vr_search_text, vr_in, vr_out, vr_in_tags, vr_out_tags, vr_count, vr_lower_boundary);
END;
$$ LANGUAGE plpgsql;

