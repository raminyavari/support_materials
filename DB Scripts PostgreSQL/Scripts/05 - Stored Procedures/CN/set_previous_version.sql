DROP FUNCTION IF EXISTS cn_set_previous_version;

CREATE OR REPLACE FUNCTION cn_set_previous_version
(
	vr_application_id		UUID,
    vr_node_id				UUID,
    vr_previous_version_id	UUID,
    vr_current_user_id		UUID,
    vr_now					TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER = 0;
BEGIN	
	UPDATE cn_nodes AS x
	SET previous_version_id = vr_previous_version_id,
		last_modifier_user_id = vr_current_user_id,
		last_modification_date = vr_now
	WHERE x.application_id = vr_application_id AND x.node_id = vr_node_id;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

