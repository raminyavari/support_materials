DROP FUNCTION IF EXISTS cn_like_nodes;

CREATE OR REPLACE FUNCTION cn_like_nodes
(
	vr_application_id	UUID,
	vr_node_ids			guid_table_type[],
    vr_user_id			UUID,
    vr_like_date	 	TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_upd_result	INTEGER;
	vr_ins_result	INTEGER;
BEGIN
	UPDATE cn_node_likes
	SET	like_date = vr_like_date,
		deleted = FALSE
	FROM UNNEST(vr_node_ids) AS rf
		INNER JOIN cn_node_likes AS nl
		ON nl.application_id = vr_application_id AND 
			nl.node_id = rf.value AND nl.user_id = vr_user_id;
			
	GET DIAGNOSTICS vr_upd_result := ROW_COUNT;
	
	INSERT INTO cn_node_likes (
		application_id,
		node_id,
		user_id,
		like_date,
		deleted,
		unique_id
	)
	SELECT vr_application_id, rf.value, vr_user_id, vr_like_date, FALSE, gen_random_uuid()
	FROM UNNEST(vr_node_ids) AS rf
		LEFT JOIN cn_node_likes AS nl
		ON nl.application_id = vr_application_id AND 
			nl.node_id = rf.value AND nl.user_id = vr_user_id
	WHERE nl.node_id IS NULL;

	GET DIAGNOSTICS vr_ins_result := ROW_COUNT;
	
	RETURN vr_upd_result + vr_ins_result;
END;
$$ LANGUAGE plpgsql;
