DROP FUNCTION IF EXISTS cn_add_relation_type;

CREATE OR REPLACE FUNCTION cn_add_relation_type
(
	vr_application_id	UUID,
    vr_relation_type_id UUID,
    vr_name		 		VARCHAR(255),
    vr_description 		VARCHAR,
    vr_creator_user_id	UUID,
    vr_creation_date 	TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER = 0;
BEGIN
	vr_name := gfn_verify_string(vr_name);
	vr_description := gfn_verify_string(vr_description);
	
	IF EXISTS(
		SELECT * 
		FROM cn_properties
		WHERE application_id = vr_application_id AND "name" = vr_name AND deleted = TRUE
		LIMIT 1
	) THEN
		UPDATE cn_properties
			SET deleted = FALSE
		WHERE application_id = vr_application_id AND "name" = vr_name AND deleted = TRUE;
	ELSE
		INSERT INTO cn_properties(
			application_id,
			property_id,
			"name",
			description,
			creator_user_id,
			creation_date,
			deleted
		)
		VALUES(
			vr_application_id,
			vr_relation_type_id,
			vr_name,
			vr_description,
			vr_creator_user_id,
			vr_creation_date,
			FALSE
		);
	END IF;

	GET DIAGNOSTICS vr_result := ROW_COUNT;

	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

