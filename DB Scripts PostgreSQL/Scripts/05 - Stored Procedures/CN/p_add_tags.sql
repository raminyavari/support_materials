DROP FUNCTION IF EXISTS cn_p_add_tags;

CREATE OR REPLACE FUNCTION cn_p_add_tags
(
	vr_application_id	UUID,
	vr_tags				VARCHAR(400)[],
	vr_current_user_id	UUID,
	vr_now				TIMESTAMP
)
RETURNS UUID
AS
$$
DECLARE
	vr_verified_tags	guid_string_table_type[];
	vr_existing_tags	guid_pair_table_type[];
	vr_not_existing		guid_string_table_type[];
	vr_ret_id			UUID = NULL;
BEGIN
	vr_verified_tags := ARRAY(
		SELECT ROW(gen_random_uuid(), rf.val)
		FROM (
				SELECT DISTINCT gfn_verify_string(tg) AS val
				FROM UNNEST(vr_tags) AS tg
			) AS rf
	);
	
	vr_existing_tags := ARRAY(
		SELECT ROW(tg.tag_id, rf.first_value)
		FROM UNNEST(vr_verified_tags) AS rf
			INNER JOIN cn_tags AS tg
			ON tg.application_id = vr_application_id AND tg.tag = rf.second_value
	);
		
	vr_not_existing := ARRAY(
		SELECT rf.first_value, rf.second_value
		FROM vr_verified_tags AS rf
		WHERE rf.first_value NOT IN (SELECT et.second_value FROM UNNEST(vr_existing_tags) AS et)
	);
	
	IF EXISTS(SELECT UNNEST(vr_existing_tags)) THEN
		vr_ret_id := (SELECT rt.first_value FROM UNNEST(vr_existing_tags) AS rf LIMIT 1);
		
		UPDATE cn_tags
		SET calls_count = COALESCE(calls_count, 0) + 1
		FROM UNNEST(vr_existing_tags) AS et
			INNER JOIN cn_tags AS tg
			ON tg.application_id = vr_application_id AND tg.tag_id = et.first_value;
	ELSE
		vr_ret_id := (SELECT rt.first_value FROM UNNEST(vr_not_existing) AS rf LIMIT 1);
		
		INSERT INTO cn_tags (
			application_id,
			tag_id,
			tag,
			is_approved,
			calls_count,
			creator_user_id,
			creation_date,
			deleted
		)
		SELECT vr_application_id, rf.first_value, rf.second_value, FALSE, 0, 
			vr_current_user_id, vr_now, FALSE
		FROM UNNEST(vr_not_existing) AS rf;
	END IF;
	
	RETURN vr_ret_id;
END;
$$ LANGUAGE plpgsql;
