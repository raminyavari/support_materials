DROP FUNCTION IF EXISTS prvc_check_access;

CREATE OR REPLACE FUNCTION prvc_check_access
(
	vr_application_id	UUID,
	vr_user_id			UUID,
	vr_object_type		varchar(50),
    vr_object_ids		guid_table_type[],
    vr_permissions		string_pair_table_type[],
    vr_now			 	TIMESTAMP
)
RETURNS TABLE (
	"id"	UUID,
	"type"	VARCHAR(50)
)
AS
$$
DECLARE
	vr_ids	UUID[];
BEGIN
	vr_ids := ARRAY(
		SELECT o.value
		FROM UNNEST(vr_object_ids) AS o
	);
	
	RETURN QUERY
	SELECT 	rf.id, 
			rf.type
	FROM prvc_fn_check_access(vr_application_id, vr_user_id, vr_ids, 
							  vr_object_type, vr_now, vr_permissions) AS rf;
END;
$$ LANGUAGE plpgsql;

