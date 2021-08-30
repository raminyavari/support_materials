DROP FUNCTION IF EXISTS cn_p_initialize_relation_types;

CREATE OR REPLACE FUNCTION cn_p_initialize_relation_types
(
	vr_application_id	UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	vr_result := 0;
	
	CREATE TEMP TABLE vr_tbl ("additional_id" INTEGER, "name" VARCHAR(100));
	
	INSERT INTO vr_tbl (additional_id, "name")
	VALUES	(1,	N'شمول پدری'), (2,	N'شمول فرزندی'), (3,	N'ربط');
	
	INSERT INTO cn_properties (application_id, property_id, additional_id, "name", deleted)
	SELECT vr_application_id, gen_random_uuid(), "t".additional_id, "t".name, FALSE
	FROM vr_tbl AS "t"
		LEFT JOIN cn_properties AS "p"
		ON "p".application_id = vr_application_id AND "p".additional_id = t.additional_id
	WHERE "p".property_id IS NULL;
	
	vr_result := 1;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
