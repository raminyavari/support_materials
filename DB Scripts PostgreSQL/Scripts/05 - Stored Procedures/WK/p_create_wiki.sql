DROP FUNCTION IF EXISTS wk_p_create_wiki;

CREATE OR REPLACE FUNCTION wk_p_create_wiki
(
	vr_application_id	UUID,
	vr_owner_id			UUID,
	vr_wiki				string_pair_table_type[],
	vr_has_admin		BOOLEAN,
	vr_current_user_id	UUID,
	vr_now				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_count		INTEGER;
	vr_index		INTEGER DEFAULT 1;
	vr_sequence_no	INTEGER; 
	vr_title_id 	UUID;
	vr_title 		VARCHAR(500);
	vr_p_title_id 	UUID; 
	vr_paragraph_id UUID; 
	vr_paragraph 	VARCHAR;
	vr_result		INTEGER;
BEGIN
	DROP TABLE IF EXISTS vr_wiki_34528;
	
	CREATE TEMP TABLE vr_wiki_34528 (
		sequence_no 	SERIAL,
		title_id 		UUID, 
		title 			VARCHAR(500), 
		paragraph_id 	UUID, 
		paragraph 		VARCHAR
	);
	
	INSERT INTO vr_wiki_34528 (
		title_id,
		title,
		paragraph_id,
		paragraph
	)
	SELECT 	gen_random_uuid(), 
			rf.first_value, 
			gen_random_uuid(), 
			rf.second_value
	FROM UNNEST(vr_wiki) AS rf;
	
	WHILE vr_index <= vr_count LOOP
		SELECT 	vr_sequence_no = rf.sequence_no, 
				vr_title_id = rf.title_id, 
				vr_title = rf.Title
		FROM vr_wiki_34528 AS rf
		WHERE rf.sequence_no = vr_index;
			
		vr_result := wk_p_add_title(vr_application_id, vr_title_id, vr_owner_id, vr_title, 
									vr_sequence_no, vr_current_user_id, vr_now, 'Node', TRUE);
			
		IF vr_result <= 0 THEN
			EXECUTE gfn_raise_exception(-1::INTEGER);
			RETURN -1::INTEGER;
		END IF;
		
		vr_index := vr_index + 1;
	END LOOP;
	
	vr_index := 1;
	
	WHILE vr_index <= vr_count LOOP
		SELECT 	vr_sequence_no = rf.sequence_no, 
				vr_p_title_id = rf.title_id,
			   	vr_paragraph_id = rf.paragraph_id, 
			   	vr_paragraph = rf.paragraph
		FROM vr_wiki_34528 AS rf
		WHERE rf.sequence_no = vr_index;
		
		IF COALESCE(vr_paragraph, '') <> '' THEN
			vr_result := wk_p_add_paragraph(vr_application_id, vr_paragraph_id, vr_p_title_id, NULL, vr_paragraph, 
											1, vr_current_user_id, vr_now, FALSE, FALSE, vr_has_admin);
				
			IF vr_result <= 0 THEN
				EXECUTE gfn_raise_exception(-1::INTEGER);
				RETURN -1::INTEGER;
			END IF;
		END IF;
		
		vr_index := vr_index + 1;
	END LOOP;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

