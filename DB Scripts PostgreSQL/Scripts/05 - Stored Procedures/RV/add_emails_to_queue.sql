DROP FUNCTION IF EXISTS rv_add_emails_to_queue;

CREATE OR REPLACE FUNCTION rv_add_emails_to_queue
(
	vr_application_id		UUID,
	vr_email_queue_items	email_queue_item_table_type[]
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result_1	INTEGER;
	vr_result_2	INTEGER;
BEGIN
	UPDATE rv_email_queue
	SET title = e.title,
		email_body = e.email_body
	FROM UNNEST(vr_email_queue_items) AS e
		INNER JOIN rv_email_queue AS q
		ON q.application_id = vr_application_id AND q.sender_user_id = e.sender_user_id AND 
			q.action = e.action AND q.email = LOWER(e.email);
	
	GET DIAGNOSTICS vr_result_1 := ROW_COUNT;
	
	INSERT INTO rv_email_queue (
		application_id,
		sender_user_id,
		"action",
		email,
		title,
		email_body
	)
	SELECT 	vr_application_id, 
			e.sender_user_id, 
			e.action, 
			LOWER(e.email), 
			e.title, 
			e.emailBody
	FROM UNNEST(vr_email_queue_items) AS e
		LEFT JOIN rv_email_queue AS q
		ON q.application_id = vr_application_id AND 
			q.sender_user_id = e.sender_user_id AND q.action = e.action AND q.email = e.email
	WHERE q.id IS NULL;
	
	GET DIAGNOSTICS vr_result_2 := ROW_COUNT;
	
	RETURN vr_result_1 + vr_result_2;
END;
$$ LANGUAGE plpgsql;

