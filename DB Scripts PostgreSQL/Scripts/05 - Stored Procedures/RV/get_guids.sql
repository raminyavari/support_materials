DROP FUNCTION IF EXISTS rv_get_guids;

CREATE OR REPLACE FUNCTION rv_get_guids
(
	vr_application_id		UUID,
	vr_ids					string_table_type[],
	vr_type					VARCHAR(100),
	vr_exist				BOOLEAN,
	vr_create_if_not_exist 	BOOLEAN
)
RETURNS TABLE (
	"id" 	VARCHAR(100), 
	guid 	UUID
)
AS
$$
BEGIN
	DROP TABLE IF EXISTS tbl_84205;
	
	CREATE TEMP TABLE tbl_84205 (
		"id" 		VARCHAR(100), 
		"exists"	BOOLEAN, 
		guid 		UUID
	);
	
	INSERT INTO tbl_84205 (
		"id", 
		"exists", 
		guid
	)
	SELECT 	i.value, 
			CASE WHEN "g".id IS NULL THEN FALSE ELSE TRUE END, 
			COALESCE("g".guid, gen_random_uuid())
	FROM UNNEST(vr_ids) AS i
		LEFT JOIN rv_id2guid AS "g"
		ON "g".application_id = vr_application_id AND "g".id = i.value AND "g".type = vr_type;
		
	IF vr_create_if_not_exist = TRUE THEN
		INSERT INTO rv_id2_guid (
			application_id, 
			"id", 
			"type", 
			guid
		)
		SELECT 	vr_application_id, 
				i.id, 
				vr_type, 
				i.guid 
		FROM tbl_84205 AS i
		WHERE i.exists = FALSE;
	END IF;
	
	RETURN QUERY
	SELECT 	i.id, 
			i.guid
	FROM tbl_84205 AS i
	WHERE vr_exist IS NULL OR i.exists = vr_exist;
END;
$$ LANGUAGE plpgsql;

