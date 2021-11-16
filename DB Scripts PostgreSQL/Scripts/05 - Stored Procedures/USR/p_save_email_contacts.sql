DROP FUNCTION IF EXISTS usr_p_save_email_contacts;

CREATE OR REPLACE FUNCTION usr_p_save_email_contacts
(
	vr_application_id	UUID,
    vr_user_id			UUID,
    vr_emails			VARCHAR[],
    vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
	vr_result2	INTEGER;
BEGIN
	UPDATE usr_email_contacts
	SET deleted = FALSE
	FROM UNNEST(vr_emails) AS e
		INNER JOIN usr_email_contacts AS "c"
		ON "c".email = LOWER(e)
	WHERE "c".user_id = vr_user_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	INSERT INTO usr_email_contacts (
		user_id,
		email, 
		creation_date, 
		deleted, 
		unique_id
	)
	SELECT	rf.user_id, 
			rf.email, 
			rf.now, 
			rf.deleted, 
			gen_random_uuid()
	FROM (
			SELECT DISTINCT 
				vr_user_id AS user_id, 
				LOWER(e) AS email, 
				vr_now AS now, 
				FALSE AS deleted
			FROM UNNEST(vr_emails) AS e
				LEFT JOIN usr_email_contacts AS "c"
				ON "c".user_id = vr_user_id AND "c".email = LOWER(e)
			WHERE "c".user_id IS NULL
		) AS rf;
	
	GET DIAGNOSTICS vr_result2 := ROW_COUNT;
	
	vr_result := vr_result + vr_result2;
	
	IF vr_result <= 0 AND COALESCE(ARRAY_LENGTH(vr_emails, 1), 0) = 0 THEN
		vr_result := 1;
	END IF;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

