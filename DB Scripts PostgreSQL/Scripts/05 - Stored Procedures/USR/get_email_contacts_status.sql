DROP FUNCTION IF EXISTS usr_get_email_contacts_status;

CREATE OR REPLACE FUNCTION usr_get_email_contacts_status
(
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_emails			string_table_type[],
	vr_save_emails	 	BOOLEAN,
    vr_now		 		TIMESTAMP
)
RETURNS TABLE (
	email					VARCHAR,
	user_id					UUID,
	friend_request_received BOOLEAN
)
AS
$$
DECLARE
	vr_arr_emails	VARCHAR[];
	vr_result		INTEGER;
BEGIN
	vr_arr_emails := ARRAY(
		SELECT e.value
		FROM UNNEST(vr_emails) AS e
	);

	IF vr_save_emails = TRUE THEN
		vr_result := usr_p_save_email_contacts(vr_application_id, vr_user_id, vr_arr_emails, vr_now);
	END IF;
	
	RETURN QUERY
	SELECT	emails.email,
			emails.user_id,
			(CASE WHEN fr.is_sender IS NULL THEN FALSE ELSE TRUE END)::BOOLEAN AS friend_request_received
	FROM (
			SELECT DISTINCT
					ea.user_id,
					LOWER(e) AS email
			FROM UNNEST(vr_arr_emails) AS e
				LEFT JOIN usr_email_addresses AS ea
				ON ea.deleted = FALSE AND LOWER(ea.email_address) = LOWER(e)
			WHERE ea.user_id IS NULL OR ea.user_id <> vr_user_id
		) AS emails
		LEFT JOIN usr_view_friends AS fr
		ON fr.application_id = vr_application_id AND 
			fr.user_id = vr_user_id AND fr.friend_id = emails.user_id
	WHERE fr.are_friends IS NULL OR (fr.are_friends = FALSE AND fr.is_sender = FALSE);
END;
$$ LANGUAGE plpgsql;

