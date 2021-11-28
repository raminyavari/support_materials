DROP FUNCTION IF EXISTS qa_add_knowledgable_user;

CREATE OR REPLACE FUNCTION qa_add_knowledgable_user
(
	vr_application_id	UUID,
	vr_question_id	 	UUID,
	vr_user_id			UUID,
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS SETOF dashboard_table_type
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	UPDATE qa_related_users AS r
	SET deleted = FALSE,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE r.application_id = vr_application_id AND 
		r.question_id = vr_question_id AND r.user_id = vr_user_id;
		
	GET DIAGNOSTICS vr_result := ROW_COUNT;
		
	IF vr_result = 0 THEN
		INSERT INTO qa_related_users (
			application_id,
			question_id,
			user_id,
			sender_user_id,
			send_date,
			seen,
			deleted
		)
		VALUES (
			vr_application_id,
			vr_question_id,
			vr_user_id,
			vr_current_user_id,
			vr_now,
			FALSE,
			FALSE
		);
	END IF;
	
    -- Send new dashboards
    IF vr_user_id IS NOT NULL THEN
		vr_result := ntfn_p_arithmetic_delete_dashboards(vr_application_id, vr_user_id, 
														 vr_question_id, NULL, 'Question', 'Knowledgable');
			
		IF vr_result <= 0 THEN
			EXECUTE gfn_raise_exception(-1::INTEGER);
			RETURN;
		END IF;
    
		DROP TABLE IF EXISTS vr_dash_09323;
		
		CREATE TEMP TABLE vr_dash_09323 OF dashboard_table_type;
	
		INSERT INTO vr_dash_09323 (
			user_id, 
			node_id, 
			ref_item_id, 
			"type", 
			sub_type, 
			removable, 
			send_date
		)
		VALUES (
			vr_user_id, 
			vr_question_id, 
			vr_question_id, 
			'Question', 
			'Knowledgable', 
			FALSE, 
			vr_now
		);
		
		vr_result := ntfn_p_send_dashboards(vr_application_id, ARRAY(
			SELECT d
			FROM vr_dash_09323 AS d
		));
		
		IF vr_result <= 0 THEN
			EXECUTE gfn_raise_exception(-1::INTEGER);
		ELSE
			RETURN QUERY
			SELECT d.*
			FROM vr_dash_09323 AS d;
		END IF;
	END IF;
	-- end of send new dashboards
END;
$$ LANGUAGE plpgsql;

