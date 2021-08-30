DROP PROCEDURE IF EXISTS _cn_add_relation;

CREATE OR REPLACE PROCEDURE _cn_add_relation
(
	vr_application_id		UUID,
	vr_relations			guid_triple_table_type[],
    vr_creator_user_id		UUID,
    vr_creation_date	 	TIMESTAMP,
	INOUT vr_result 		INTEGER
)
AS
$$
BEGIN
	vr_result := cn_p_add_relation(vr_application_id, vr_relations, vr_creator_user_id, vr_creation_date, TRUE);
	
	IF vr_result <= 0 THEN
		ROLLBACK;
	ELSE
		COMMIT;
	END IF;
END;
$$ LANGUAGE plpgsql;



DROP FUNCTION IF EXISTS cn_add_relation;

CREATE OR REPLACE FUNCTION cn_add_relation
(
	vr_application_id		UUID,
	vr_relations			guid_triple_table_type[],
    vr_creator_user_id		UUID,
    vr_creation_date	 	TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result INTEGER = 0;
BEGIN
	CALL _cn_add_relation(vr_application_id, vr_relations, vr_creator_user_id, vr_creation_date, vr_result);

	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

