DROP FUNCTION IF EXISTS qa_add_question;

CREATE OR REPLACE FUNCTION qa_add_question
(
	vr_application_id	UUID,
    vr_question_id 		UUID,
    vr_title			VARCHAR(500),
    vr_description	 	VARCHAR,
    vr_status			VARCHAR(20),
    vr_publication_date TIMESTAMP,
    vr_node_ids			guid_table_type[],
    vr_workflow_id		UUID,
    vr_admin_id			UUID,
    vr_current_user_id	UUID,
    vr_now   			TIMESTAMP
)
RETURNS SETOF REFCURSOR
AS
$$
DECLARE
	vr_nodes_count	INTEGER;
	vr_result		INTEGER;
	vr_cursor_1		REFCURSOR;
	vr_cursor_2		REFCURSOR;
BEGIN
	vr_nodes_count := COALESCE(ARRAY_LENGTH(vr_node_ids, 1), 0)::INTEGER;

	vr_title := gfn_verify_string(vr_title);
	vr_description := gfn_verify_string(vr_description);

    INSERT INTO qa_questions (
		application_id,
        question_id,
		title,
		description,
		status,
		publication_date,
		workflow_id,
		sender_user_id,
		send_date,
		deleted
    )
    VALUES (
		vr_application_id,
        vr_question_id,
        vr_title,
        vr_description,
        vr_status,
        vr_publication_date,
        vr_workflow_id,
        vr_current_user_id,
        vr_now,
        FALSE
    );
    
    /*     insert related nodes     */
    INSERT INTO qa_related_nodes (
		application_id,
		node_id, 
		question_id, 
		creator_user_id,
		creation_date,
		deleted
	)
    SELECT 	vr_application_id, 
			rf.value, 
			vr_question_id, 
			vr_current_user_id, 
			vr_now, 
			FALSE
    FROM UNNEST(vr_node_ids) AS rf;
    /*     end of insert related nodes     */
    
    -- Send new dashboards
	DROP TABLE IF EXISTS vr_dash_27398;
	
	CREATE TEMP TABLE vr_dash_27398 OF dashboard_table_type;
	
    IF vr_admin_id IS NOT NULL THEN
		INSERT INTO vr_dash_27398 (
			user_id, 
			node_id, 
			ref_item_id, 
			"type", 
			sub_type, 
			removable, 
			send_date
		)
		VALUES (
			vr_admin_id, 
			vr_question_id, 
			vr_question_id, 
			'Question', 'Admin', 
			FALSE, 
			vr_now
		);
		
		vr_result := ntfn_p_send_dashboards(vr_application_id, ARRAY(
			SELECT x
			FROM vr_dash_27398 AS x
		));
		
		IF vr_result <= 0 THEN
			EXECUTE gfn_raise_exception(-1::INTEGER);
			RETURN;
		END IF;
	END IF;
	
	OPEN vr_cursor_1 FOR
	SELECT (1 + vr_nodes_count)::INTEGER AS "value";
	RETURN NEXT vr_cursor_1;
	
	OPEN vr_cursor_2 FOR
	SELECT x.*
	FROM vr_dash_27398 AS x;
	RETURN NEXT vr_cursor_2;
	-- end of send new dashboards;
END;
$$ LANGUAGE plpgsql;

