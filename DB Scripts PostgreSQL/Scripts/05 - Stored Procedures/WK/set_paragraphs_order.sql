DROP FUNCTION IF EXISTS wk_set_paragraphs_order;

CREATE OR REPLACE FUNCTION wk_set_paragraphs_order
(
	vr_application_id	UUID,
	vr_paragraph_ids		guid_table_type[]
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_title_id UUID;
	vr_result	INTEGER;
BEGIN
	SELECT vr_title_id = "p".title_id
	FROM wk_paragraphs AS "p"
	WHERE "p".application_id = vr_application_id AND 
		"p".paragraph_id = (SELECT rf.value FROM UNNEST(vr_paragraph_ids) AS rf LIMIT 1);
	
	IF vr_title_id IS NULL THEN
		RETURN -1::INTEGER;
	END IF;
	
	vr_paragraph_ids := ARRAY(
		SELECT x
		FROM UNNEST(vr_paragraph_ids) AS x
		
		UNION ALL
		
		SELECT "p".paragraph_id
		FROM UNNEST(vr_paragraph_ids) WITH ORDINALITY AS rf("value", seq)
			RIGHT JOIN wk_paragraphs AS "p"
			ON "p".paragraph_id = rf.value
		WHERE "p".application_id = vr_application_id AND "p".title_id = vr_title_id AND rf.value IS NULL
		ORDER BY "p".sequence_no
	);
	
	UPDATE wk_paragraphs
	SET sequence_no = rf.seq
	FROM UNNEST(vr_paragraph_ids) WITH ORDINALITY AS rf("value", seq)
		INNER JOIN wk_paragraphs AS "p"
		ON "p".paragraph_id = rf.value
	WHERE "p".application_id = vr_application_id AND "p".title_id = vr_title_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

