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
	vr_result := cn_p_initialize_node_types(vr_application_id, vr_now);
	vr_result := cn_p_initialize_relation_types(vr_application_id);
	
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

