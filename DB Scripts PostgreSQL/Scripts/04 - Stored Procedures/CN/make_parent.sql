DROP PROCEDURE IF EXISTS _cn_make_parent;

CREATE OR REPLACE PROCEDURE _cn_make_parent
(
	vr_application_id	UUID,
	vr_pair_node_ids	guid_pair_table_type[],
    vr_creator_user_id	UUID,
    vr_creation_date	TIMESTAMP,
	INOUT vr_result		INTEGER
)
AS
$$
BEGIN
	vr_result := cn_p_make_parent(vr_application_id, vr_pair_node_ids, vr_creator_user_id, vr_creation_date);
	
	IF vr_result <= 0 THEN
		ROLLBACK;
	ELSE
		COMMIT;
	END IF;
END;
$$ LANGUAGE plpgsql;



DROP FUNCTION IF EXISTS cn_make_parent;

CREATE OR REPLACE FUNCTION cn_make_parent
(
	vr_application_id	UUID,
	vr_pair_node_ids	guid_pair_table_type[],
    vr_creator_user_id	UUID,
    vr_creation_date	TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	CALL _cn_make_parent(vr_application_id, vr_pair_node_ids, vr_creator_user_id, vr_creation_date, vr_result);
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

