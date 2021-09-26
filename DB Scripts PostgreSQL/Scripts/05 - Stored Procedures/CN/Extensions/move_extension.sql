DROP FUNCTION IF EXISTS cn_move_extension;

CREATE OR REPLACE FUNCTION cn_move_extension
(
	vr_application_id	UUID,
	vr_owner_id			UUID,
	vr_extension		VARCHAR(50),
	vr_move_down	 	BOOLEAN
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_sequence_no				INTEGER;
	vr_other_extension 			VARCHAR(50);
	vr_other_sequence_number	INTEGER;
	vr_result					INTEGER;
BEGIN
	SELECT vr_sequence_no = ex.sequence_number
	FROM cn_extensions AS ex
	WHERE ex.application_id = vr_application_id AND 
		ex.owner_id = vr_owner_id AND ex.extension = vr_extension;
	
	IF vr_move_down = TRUE THEN
		SELECT 	vr_other_extension = ex.extension, 
				vr_other_sequence_number = ex.sequence_number
		FROM cn_extensions AS ex
		WHERE ex.application_id = vr_application_id AND 
			ex.owner_id = vr_owner_id AND ex.sequence_number > vr_sequence_no
		ORDER BY ex.sequence_number
		LIMIT 1;
	ELSE
		SELECT 	vr_other_extension = ex.extension, 
				vr_other_sequence_number = ex.sequence_number
		FROM cn_extensions AS ex
		WHERE ex.application_id = vr_application_id AND 
			ex.owner_id = vr_owner_id AND ex.sequence_number < vr_sequence_no
		ORDER BY ex.sequence_number DESC
		LIMIT 1;
	END IF;
	
	IF vr_other_extension IS NULL THEN
		CALL gfn_raise_exception();
		RETURN -1;
	END IF;
	
	UPDATE cn_extensions AS ex
	SET sequence_number = vr_other_sequence_number
	WHERE ex.application_id = vr_application_id AND 
		ex.owner_id = vr_owner_id AND ex.extension = vr_extension;
		
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	IF vr_result <= 0 THEN
		CALL gfn_raise_exception();
		RETURN -1;
	END IF;
	
	UPDATE cn_extensions AS Ex
	SET sequence_number = vr_sequence_no
	WHERE ex.application_id = vr_application_id AND 
		ex.owner_id = vr_owner_id AND ex.extension = vr_other_extension;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	IF vr_result <= 0 THEN
		CALL gfn_raise_exception();
		RETURN -1;
	END IF;
	
	RETURN 1;
END;
$$ LANGUAGE plpgsql;
