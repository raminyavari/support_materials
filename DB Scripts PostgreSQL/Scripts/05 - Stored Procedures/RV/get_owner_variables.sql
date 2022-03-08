DROP FUNCTION IF EXISTS rv_get_owner_variables;

CREATE OR REPLACE FUNCTION rv_get_owner_variables
(
	vr_application_id	UUID,
	vr_id				BIGINT,
	vr_owner_id			UUID,
	vr_name				VARCHAR(100),
	vr_creator_user_id	UUID
)
RETURNS TABLE (
	"id"			BIGINT,
	owner_id		UUID,
	"name"			VARCHAR,
	"value"			VARCHAR,
	creator_user_id	UUID,
	creation_date	TIMESTAMP
)
AS
$$
BEGIN
	vr_name := LOWER(vr_name);
	
	RETURN QUERY
	SELECT	v.id,
			v.owner_id,
			v.name,
			v.value,
			v.creator_user_id,
			v.creation_date
	FROM rv_variables_with_owner AS v
	WHERE v.application_id = vr_application_id AND 
		(vr_id IS NULL OR v.id = vr_id) AND 
		(vr_owner_id IS NULL OR v.owner_id = vr_owner_id) AND 
		(vr_name IS NULL OR v.name = vr_name) AND 
		(vr_creator_user_id IS NULL OR v.creator_user_id = vr_creator_user_id) AND 
		v.deleted = FALSE
	ORDER BY ID ASC;
END;
$$ LANGUAGE plpgsql;

