DROP FUNCTION IF EXISTS usr_add_or_modify_remote_server;

CREATE OR REPLACE FUNCTION usr_add_or_modify_remote_server
(
	vr_application_id	UUID,
	vr_server_id		UUID,
	vr_user_id			UUID,
	vr_name		 		VARCHAR(255),
	vr_url		 		VARCHAR(100),
	vr_username	 		VARCHAR(100),
	vr_password			BYTEA,
	vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF EXISTS(
		SELECT s.server_id
		FROM usr_remote_servers AS s
		WHERE s.application_id = vr_application_id AND 
			s.server_id = vr_server_id AND s.user_id = vr_user_id
		LIMIT 1
	) THEN
		UPDATE usr_remote_servers AS s
		Set "name" = vr_name,
			url = vr_url,
			username = vr_username,
			"password" = vr_password,
			last_modification_date = vr_now
		WHERE s.application_id = vr_application_id AND 
			s.server_id = vr_server_id AND s.user_id = vr_user_id;
	ELSE
		INSERT INTO usr_remote_servers (
			application_id, 
			server_id, 
			user_id, 
			"name", 
			url, 
			username, 
			"password",
			creation_date
		)
		VALUES (
			vr_application_id, 
			vr_server_id, 
			vr_user_id, 
			vr_name, 
			vr_url, 
			vr_username, 
			vr_password, 
			vr_now
		);
	END IF;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

