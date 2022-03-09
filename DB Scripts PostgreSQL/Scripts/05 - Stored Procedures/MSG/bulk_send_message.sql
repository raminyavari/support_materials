DROP FUNCTION IF EXISTS msg_bulk_send_message;

CREATE OR REPLACE FUNCTION msg_bulk_send_message
(
	vr_application_id	UUID,
	vr_messages			message_table_type[],
    vr_receivers		guid_pair_table_type,
    vr_now		 		TIMESTAMP
)
RETURNS BIGINT
AS
$$
DECLARE
	vr_result 	INTEGER;
	vr_new_id	BIGINT;
BEGIN
	INSERT INTO msg_messages (
		application_id,
		message_id,
		title,
		"message_text",
		sender_user_id,
		send_date,
		has_attachment
	)
	SELECT	vr_application_id,
			"m".message_id,
			"m".title,
			"m".message_text,
			"m".sender_user_id,
			vr_now,
			FALSE
	FROM UNNEST(vr_messages) AS "m"
	WHERE "m".message_id IN (SELECT DISTINCT r.first_value FROM UNNEST(vr_receivers) AS r);
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	IF vr_result <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN -1::BIGINT;
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
	SELECT *
	FROM (
			SELECT	vr_application_id AS application_id,
					"m".sender_user_id,
					r.second_value,
					"m".message_id,
					TRUE AS seen,
					TRUE AS is_sender,
					FALSE AS is_group,
					FALSE AS deleted
			FROM UNNEST(vr_messages) AS "m"
				INNER JOIN UNNEST(vr_receivers) AS r
				ON r.first_value = "m".message_id
			
			UNION ALL
			
			SELECT	vr_application_id,
					r.second_value,
					"m".sender_user_id,
					"m".message_id,
					FALSE,
					FALSE,
					FALSE,
					FALSE
			FROM UNNEST(vr_messages) AS "m"
				INNER JOIN UNNEST(vr_receivers) AS r
				ON r.first_value = "m".message_id
		) AS rf
	ORDER BY rf.is_sender DESC;
	
	vr_new_id := LASTID();
	
	IF COALESCE(vr_new_id, 0) <= 0 THEN
		EXECUTE gfn_raise_exception(-1::INTEGER);
		RETURN -1::BIGINT;
	END IF;
	
	RETURN vr_new_id;
END;
$$ LANGUAGE plpgsql;




