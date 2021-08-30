DROP PROCEDURE IF EXISTS _cn_set_node_expiration_date;

CREATE OR REPLACE PROCEDURE _cn_set_node_expiration_date
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_expiration_date 	TIMESTAMP,
	INOUT vr_result		INTEGER
)
AS
$$
BEGIN
	UPDATE cn_nodes
	SET expiration_date = vr_expiration_date
	WHERE application_id = vr_application_id AND node_id = vr_node_id;
	
	-- remove dashboards
	IF vr_expiration_date IS NULL THEN
		vr_result := ntfn_p_arithmetic_delete_dashboards(vr_application_id, 
			NULL, vr_node_id, NULL, 'Knowledge', 'ExpirationDate');
			
		IF vr_result <= 0 THEN
			vr_result := -1;
			ROLLBACK;
			RETURN;
		END IF;
	END IF;
	-- end of remove dashboards
	
	vr_result := 1;
	
	COMMIT;
END;
$$ LANGUAGE plpgsql;



DROP FUNCTION IF EXISTS cn_set_node_expiration_date;

CREATE OR REPLACE FUNCTION cn_set_node_expiration_date
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_expiration_date 	TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	CALL _cn_set_node_expiration_date(vr_application_id, vr_node_id, vr_expiration_date, vr_result);
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

