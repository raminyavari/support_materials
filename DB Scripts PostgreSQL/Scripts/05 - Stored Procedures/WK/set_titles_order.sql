DROP FUNCTION IF EXISTS wk_set_titles_order;

CREATE OR REPLACE FUNCTION wk_set_titles_order
(
	vr_application_id	UUID,
	vr_title_ids		guid_table_type[]
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_owner_id UUID;
	vr_result	INTEGER;
BEGIN
	SELECT vr_owner_id = "t".owner_id
	FROM wk_titles AS "t"
	WHERE "t".application_id = vr_application_id AND 
		"t".title_id = (SELECT x.value FROM UNNEST(vr_title_ids) AS x LIMIT 1);
	
	IF vr_owner_id IS NULL THEN
		RETURN -1::INTEGER;
	END IF;
	
	vr_title_ids := ARRAY(
		SELECT x
		FROM UNNEST(vr_title_ids) AS x
		
		UNION ALL
		
		SELECT tt.title_id
		FROM UNNEST(vr_title_ids) WITH ORDINALITY AS rf("value", seq)
			RIGHT JOIN wk_titles AS tt
			ON tt.title_id = rf.value
		WHERE tt.application_id = vr_application_id AND tt.owner_id = vr_owner_id AND rf.value IS NULL
		ORDER BY tt.sequence_no ASC
	);
	
	UPDATE wk_titles
	SET sequence_no = rf.seq
	FROM UNNEST(vr_title_ids) WITH ORDINALITY AS rf("value", seq)
		INNER JOIN wk_titles AS tt
		ON tt.title_id = rf.value
	WHERE tt.application_id = vr_application_id AND tt.owner_id = vr_owner_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

