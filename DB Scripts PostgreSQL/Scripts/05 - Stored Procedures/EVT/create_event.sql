DROP FUNCTION IF EXISTS evt_create_event;

CREATE OR REPLACE FUNCTION evt_create_event
(
	vr_application_id	UUID,
    vr_event_id 		UUID,
    vr_event_type	 	VARCHAR(256),
    vr_owner_id			UUID,
    vr_title		 	VARCHAR(500),
    vr_description 		VARCHAR(2000),
    vr_begin_date	 	TIMESTAMP,
    vr_finish_date	 	TIMESTAMP,
    vr_current_user_id	UUID,
    vr_now 				TIMESTAMP,
    vr_node_ids			guid_table_type[],
    vr_user_ids			guid_table_type[]
)
RETURNS INTEGER
AS
$$
BEGIN
	vr_title := gfn_verify_string(vr_title);
	vr_description := gfn_verify_string(vr_description);
	
	INSERT INTO evt_events (
		application_id,
		event_id,
		event_type,
		owner_id,
		title,
		description,
		begin_date,
		finish_date,
		creator_user_id,
		creation_date,
		deleted
	)
	VALUES (
		vr_application_id,
		vr_event_id,
		vr_event_type,
		vr_owner_id,
		vr_title,
		vr_description,
		vr_beginDate,
		vr_finish_date,
		vr_current_user_id,
		vr_now,
		FALSE
	);
	
	IF vr_current_user_id IS NOT NULL THEN
		INSERT INTO evt_related_users (
			application_id,
			event_id,
			user_id,
			status,
			done,
			deleted
		)
		VALUES (
			vr_application_id,
			vr_event_id,
			vr_current_user_id,
			'Accept',
			FALSE,
			FALSE
		);
	END IF;
	
	INSERT INTO evt_related_users (
		application_id,
		event_id,
		user_id,
		status,
		done,
		deleted
	)
	SELECT 	vr_application_id, 
			vr_event_id, 
			x.value, 
			'Pending', 
			FALSE, 
			FALSE
	FROM UNNEST(vr_user_ids) AS x
	WHERE x.value <> vr_current_user_id;
	
	INSERT INTO evt_related_nodes (
		application_id,
		event_id,
		node_id,
		deleted
	)
	SELECT 	vr_application_id,
			vr_event_id, 
			x.value, 
			FALSE
	FROM UNNEST(vr_node_ids) AS x;
	
	RETURN (
		1::INTEGER + 
		COALESCE(ARRAY_LENGTH(vr_node_ids, 1), 0)::INTEGER + 
		COALESCE(ARRAY_LENGTH(vr_user_ids, 1), 0)::INTEGER
	);
END;
$$ LANGUAGE plpgsql;

