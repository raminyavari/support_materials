DROP FUNCTION IF EXISTS rv_save_tagged_items;

CREATE OR REPLACE FUNCTION rv_save_tagged_items
(
	vr_application_id	UUID,
	vr_tagged_items		tagged_item_table_type[],
	vr_remove_old_tags	BOOLEAN,
	vr_current_user_id	UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF vr_remove_old_tags = TRUE THEN
		DELETE FROM rv_tagged_items AS x
		USING (
			SELECT ti.context_id, ti.tagged_id, ti.creator_user_id
			FROM (
					SELECT DISTINCT i.context_id
					FROM vr_tagged_items AS i
				) AS con
				INNER JOIN rv_tagged_items AS ti
				ON ti.application_id = vr_application_id AND ti.context_id = con.context_id
				LEFT JOIN UNNEST(vr_tagged_items) AS "t"
				ON "t".context_id = ti.context_id AND "t".tagged_id = ti.tagged_id
			WHERE "t".context_id IS NULL
		) AS y
		WHERE x.context_id = y.context_id AND x.tagged_id = y.tagged_id AND
			x.creator_user_id = y.creator_user_id;
	END IF;
	
	INSERT INTO rv_tagged_items (
		application_id,
		context_id,
		tagged_id,
		creator_user_id,
		context_type,
		tagged_type,
		unique_id
	)
	SELECT 	vr_application_id, 
			ti.context_id, 
			ti.tagged_id, 
			vr_current_user_id, 
			ti.context_type, 
			ti.tagged_type, 
			gen_random_uuid()
	FROM (
			SELECT DISTINCT * 
			FROM UNNEST(vr_tagged_items)
		) AS ti
		LEFT JOIN rv_tagged_items AS "t"
		ON "t".application_id = vr_application_id AND "t".context_id = ti.context_id AND 
			"t".tagged_id = ti.tagged_id AND "t".creator_user_id = vr_current_user_id
	WHERE ti.tagged_id IS NOT NULL AND "t".context_id IS NULL;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

