DROP FUNCTION IF EXISTS cn_add_tags;

CREATE OR REPLACE FUNCTION cn_add_tags
(
	vr_application_id	UUID,
	vr_tags				string_table_type[],
	vr_current_user_id	UUID,
	vr_now				TIMESTAMP
)
RETURNS UUID
AS
$$
DECLARE
	vr_items	VARCHAR(400)[];
BEGIN
	vr_items := ARRAY(
		SELECT "t".value
		FROM UNNEST(vr_tags) AS "t"
	);
	
	RETURN cn_p_add_tags(vr_application_id, vr_items, vr_current_user_id, vr_now);
END;
$$ LANGUAGE plpgsql;
