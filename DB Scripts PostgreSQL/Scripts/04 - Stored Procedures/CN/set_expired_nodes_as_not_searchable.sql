DROP FUNCTION IF EXISTS cn_set_expired_nodes_as_not_searchable;

CREATE OR REPLACE FUNCTION cn_set_expired_nodes_as_not_searchable
(
	vr_application_id	UUID,
    vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
BEGIN
	UPDATE cn_nodes
	SET searchable = FALSE
	WHERE application_id = vr_application_id AND 
		expiration_date < vr_now AND deleted = FALSE;
	
	RETURN 1;
END;
$$ LANGUAGE plpgsql;

