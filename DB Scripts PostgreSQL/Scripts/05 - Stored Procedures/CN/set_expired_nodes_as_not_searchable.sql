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
	UPDATE cn_nodes AS x
	SET searchable = FALSE
	WHERE x.application_id = vr_application_id AND 
		x.expiration_date < vr_now AND x.deleted = FALSE;
	
	RETURN 1;
END;
$$ LANGUAGE plpgsql;

