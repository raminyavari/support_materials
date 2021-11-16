DROP FUNCTION IF EXISTS usr_remove_remote_server;

CREATE OR REPLACE FUNCTION usr_remove_remote_server
(
	vr_application_id	UUID,
	vr_server_id		UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	DELETE FROM usr_remote_servers AS s
	WHERE s.application_id = vr_application_id AND s.server_id = vr_server_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

