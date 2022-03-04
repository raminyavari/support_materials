DROP FUNCTION IF EXISTS fg_p_create_form_instance;

CREATE OR REPLACE FUNCTION fg_p_create_form_instance
(
	vr_application_id	UUID,
	vr_instances		form_instance_table_type[],
	vr_current_user_id	UUID,
	vr_now 				TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	INSERT INTO fg_form_instances (
		application_id,
		instance_id,
		form_id,
		owner_id,
		director_id,
		"admin",
		filled,
		is_temporary,
		creator_user_id,
		creation_date,
		deleted
	)
	SELECT	vr_application_id, 
			i.instance_id, 
			i.form_id, 
			i.owner_id, 
			i.director_id, 
			COALESCE(i.admin, FALSE), 
			FALSE,
			i.is_temporary,
			vr_current_user_id, 
			vr_now, 
			FALSE
	FROM UNNEST(vr_instances) AS i;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

