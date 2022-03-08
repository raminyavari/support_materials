DROP FUNCTION IF EXISTS rv_archive_email_queue_items;

CREATE OR REPLACE FUNCTION rv_archive_email_queue_items
(
	vr_application_id	UUID,
	vr_item_ids			big_int_table_type[],
	vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	INSERT INTO rv_sent_emails	(
		application_id,
		senderUser_id,
		send_date,
		"action",
		email,
		title,
		email_body
	)
	SELECT 	vr_application_id, 
			e.sender_user_id, 
			vr_now, 
			e.action, 
			e.email, 
			e.title, 
			e.emailBody
	FROM UNNEST(vr_item_ids) AS ids
		INNER JOIN rv_email_queue AS e
		ON e.application_id = vr_application_id AND e.id = ids.value;
		
	DELETE FROM rv_email_queue AS e
	USING UNNEST(vr_item_ids) AS ids
	WHERE e.application_id = vr_application_id AND e.id = ids.value;
		
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

