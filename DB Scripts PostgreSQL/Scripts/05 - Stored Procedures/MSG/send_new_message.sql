DROP FUNCTION IF EXISTS msg_send_new_message;

CREATE OR REPLACE FUNCTION msg_send_new_message
(
	vr_application_id	UUID,
	vr_user_id			UUID,
    vr_thread_id		UUID,
    vr_message_id		UUID,
    vr_forwarded_from	UUID,
    vr_title			VARCHAR(500),
    vr_message_text	 	VARCHAR,
    vr_is_group		 	BOOLEAN,
    vr_now			 	TIMESTAMP,
    vr_receivers		guid_table_type[],
    vr_attached_files	doc_file_info_table_type[]
)
RETURNS BIGINT
AS
$$
DECLARE
	vr_receiver_user_ids	UUID[];
	vr_count 				INTEGER;
	vr_attachments_count 	INTEGER;
	vr_result 				INTEGER;
	vr_new_id				BIGINT;
BEGIN
	IF vr_is_group IS NULL THEN 
		vr_is_group := FALSE;
	END IF;
	
	IF vr_thread_id IS NOT NULL THEN
		vr_is_group = COALESCE((
			SELECT md.is_group
			FROM msg_message_details AS md
			WHERE md.application_id = vr_application_id AND md.thread_id = vr_thread_id
			LIMIT 1
		), vr_is_group)::BOOLEAN;
	END IF;
	
	vr_receiver_user_ids := ARRAY(
		SELECT x.value
		FROM UNNEST(vr_receivers) AS x
	);
	
	vr_count := COALESCE(ARRAY_LENGTH(vr_receiver_user_ids, 1), 0)::INTEGER;
	
	IF vr_count = 1 THEN 
		vr_is_group := FALSE;
	END IF;
	
	IF	vr_count > 1 THEN 
		vr_receiver_user_ids := ARRAY(
			SELECT x
			FROM UNNEST(vr_receiver_user_ids) AS x
			WHERE x <> vr_user_id
		);
	END IF;
	
	IF vr_thread_id IS NULL AND vr_is_group = FALSE AND vr_count = 0 THEN
		RETURN -1::BIGINT;
	END IF;
	
	IF vr_thread_id IS NOT NULL AND vr_count = 0 AND EXISTS (
		SELECT 1
		FROM users_normal AS un
		WHERE un.application_id = vr_application_id AND un.user_id = vr_thread_id
		LIMIT 1
	) THEN
		vr_receiver_user_ids := ARRAY(
			SELECT vr_thread_id
			WHERE vr_thread_id IS NOT NULL
		);
		
		vr_count := 1::INTEGER;
	END IF;
	
	IF vr_is_group = TRUE THEN
		IF vr_count = 1 THEN 
			vr_thread_id := (
				SELECT rf
				FROM UNNEST(vr_receiver_user_ids) AS rf
				LIMIT 1
			);
		ELSEIF vr_thread_id IS NULL AND vr_count > 0 THEN 
			vr_thread_id = gen_random_uuid();
		END IF;
	END IF;
	
	IF vr_count = 0 THEN
		vr_receiver_user_ids := ARRAY(
			SELECT x AS "id"
			FROM UNNEST(vr_receiver_user_ids) AS x
			
			UNION ALL
			
			SELECT DISTINCT md.user_id 
			FROM msg_message_details AS md
			WHERE md.application_id = vr_application_id AND md.thread_id = vr_thread_id
			EXCEPT (SELECT vr_user_id)
		);
		
		vr_count := COALESCE(ARRAY_LENGTH(vr_receiver_user_ids, 1), 0)::INTEGER;
	END IF;
	
	vr_attachments_count := COALESCE(ARRAY_LENGTH(vr_attached_files, 1), 0)::INTEGER;
	
	INSERT INTO msg_messages (
		application_id,
		message_id,
		title,
		"message_text",
		sender_user_id,
		send_date,
		forwarded_from,
		has_attachment
	)
	VALUES (
		vr_application_id,
		vr_message_id,
		vr_title,
		vr_message_text,
		vr_user_id,
		vr_now,
		vr_forwarded_from,
		CASE WHEN vr_attachments_count > 0 THEN TRUE ELSE FALSE END::BOOLEAN
	);
	
	IF vr_attachments_count > 0 THEN
		vr_result := dct_p_add_files(vr_application_id, vr_message_id, 'Message', 
									 vr_attached_files, vr_user_id, vr_now);
		
		IF vr_result <= 0 THEN
			EXECUTE gfn_raise_exception(-1::INTEGER);
			RETURN -1::BITINT;
		END IF;
	END IF;
	
	IF vr_forwarded_from IS NOT NULL THEN
		vr_result := dct_p_copy_attachments(vr_application_id, vr_forwarded_from, 
											vr_message_id, 'Message', vr_user_id, vr_now);
		
		IF vr_result > 0 THEN
			UPDATE msg_messages AS msg
			SET has_attachment = TRUE
			WHERE msg.application_id = vr_application_id AND msg.message_id = vr_message_id;
		END IF; 
	END IF;
	
	INSERT INTO msg_message_details (
		application_id,
		user_id,
		thread_id,
		message_id,
		seen,
		is_sender,
		is_group,
		deleted
	)
	(
		(SELECT	vr_application_id,
				vr_user_id,
				CASE WHEN vr_is_group = FALSE THEN r ELSE vr_thread_id END,
				vr_message_id,
				TRUE,
				TRUE,
				vr_is_group,
				FALSE
		FROM UNNEST(vr_receiver_user_ids) AS r
		LIMIT CASE WHEN vr_is_group = TRUE THEN 1 ELSE 1000000000 END)
		
		UNION ALL
		
		SELECT	vr_application_id,
				r,
				CASE WHEN vr_is_group = FALSE THEN vr_user_id ELSE vr_thread_id END,
				vr_message_id,
				FALSE,
				FALSE,
				vr_is_group,
				FALSE
		FROM UNNEST(vr_receiver_user_ids) AS r
	);
	
	vr_new_id := LASTVAL();
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN -1::BIGINT;
	END IF;
	
	RETURN vr_new_id - vr_count::BIGINT;
END;
$$ LANGUAGE plpgsql;




