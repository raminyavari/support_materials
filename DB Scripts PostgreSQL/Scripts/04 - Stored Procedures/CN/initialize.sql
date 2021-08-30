DROP PROCEDURE IF EXISTS _cn_initialize;

CREATE OR REPLACE PROCEDURE _cn_initialize
(
	vr_application_id	UUID,
	vr_now				TIMESTAMP,
	INOUT vr_result		INTEGER
)
AS
$$
BEGIN
	vr_result := cn_p_initialize_node_types(vr_application_id, vr_now);
	vr_result := cn_p_initialize_relation_types(vr_application_id);
	
	vr_result := 1::INTEGER;
	
	COMMIT;
END;
$$ LANGUAGE plpgsql;



DROP FUNCTION IF EXISTS cn_initialize;

CREATE OR REPLACE FUNCTION cn_initialize
(
	vr_application_id	UUID,
	vr_now				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result INTEGER = 0;
BEGIN
	CALL _cn_initialize(vr_application_id, vr_now, vr_result);
	
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

