DROP FUNCTION IF EXISTS cn_search_tags;

CREATE OR REPLACE FUNCTION cn_search_tags
(
	vr_application_id	UUID,
	vr_search_text	 	VARCHAR(1000),
	vr_count		 	INTEGER,
	vr_lower_boundary 	INTEGER
)
RETURNS TABLE (
	tag_id		UUID,
	tag			VARCHAR,
	is_approved	BOOLEAN,
	calls_count	INTEGER
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT *
	FROM cn_p_search_tags(vr_application_id, vr_search_text, vr_count, vr_lower_boundary);
END;
$$ LANGUAGE plpgsql;
