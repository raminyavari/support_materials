DROP FUNCTION IF EXISTS usr_update_friend_suggestions;

CREATE OR REPLACE FUNCTION usr_update_friend_suggestions
(
	vr_application_id	UUID,
    vr_user_id			UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_all_ids		UUID[];
	vr_user_ids		UUID[];
	vr_result		INTEGER;
	vr_batch_size	INTEGER DEFAULT 50;
	vr_count		INTEGER;
BEGIN
	IF vr_user_id IS NULL THEN
		vr_all_ids := ARRAY(
			SELECT DISTINCT f.user_id
			FROM usr_view_friends AS f
			WHERE f.application_id = vr_application_id
		);
	ELSE 
		vr_all_ids := ARRAY(
			SELECT vr_user_id
		);
	END IF;
	
	vr_count := COALESCE(ARRAY_LENGTH(vr_all_ids, 1), 0)::INTEGER;
	
	WHILE vr_count > 0 LOOP
		vr_user_ids := ARRAY(
			SELECT x.id
			FROM UNNEST(vr_all_ids) WITH ORDINALITY AS x("id", seq)
			WHERE x.seq <= vr_batch_size
		);
		
		vr_all_ids := ARRAY(
			SELECT x
			FROM UNNEST(vr_all_ids) AS x
				LEFT JOIN UNNEST(vr_user_ids) AS y
				ON y = x
			WHERE y IS NULL
		);
		
		vr_count := COALESCE(ARRAY_LENGTH(vr_all_ids, 1), 0)::INTEGER;
		
		vr_result := usr_p_update_friend_suggestions(vr_application_id, vr_user_ids);
	END LOOP;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

