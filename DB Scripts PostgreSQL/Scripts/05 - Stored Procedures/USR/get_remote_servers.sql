DROP FUNCTION IF EXISTS usr_get_remote_servers;

CREATE OR REPLACE FUNCTION usr_get_remote_servers
(
	vr_application_id	UUID,
	vr_server_id		UUID
)
RETURNS TABLE (
	server_id	UUID, 
	user_id		UUID, 
	"name"		VARCHAR, 
	url			VARCHAR, 
	username	VARCHAR, 
	"password"	BYTEA
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT	s.server_id, 
			s.user_id, 
			s.name, 
			s.url, 
			s.username, 
			s.password
	FROM usr_remote_servers AS s
	WHERE s.application_id = vr_application_id AND 
		(vr_server_id IS NULL OR s.server_id = vr_server_id)
	ORDER BY s.creation_date DESC;
END;
$$ LANGUAGE plpgsql;

