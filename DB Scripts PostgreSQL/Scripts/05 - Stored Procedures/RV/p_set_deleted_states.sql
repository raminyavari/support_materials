DROP FUNCTION IF EXISTS rv_p_set_deleted_states;

CREATE OR REPLACE FUNCTION rv_p_set_deleted_states
(
	vr_application_id	UUID,
	vr_objects			guid_bit_table_type[],
	vr_object_type		VARCHAR(50),
	vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF vr_now IS NULL THEN 
		vr_now := NOW();
	END IF;
	
	DELETE FROM rv_deleted_states AS d
	USING UNNEST(vr_objects) AS o
	WHERE d.application_id = vr_application_id AND d.object_id = o.first_value;
		
	INSERT INTO rv_deleted_states (
		application_id, 
		object_id, 
		object_type, 
		deleted, 
		date
	)
	SELECT 	vr_application_id, 
			o.first_value, 
			vr_object_type, 
			o.second_value, 
			vr_now
	FROM UNNEST(vr_objects) AS o;
		
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

