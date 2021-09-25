DROP FUNCTION IF EXISTS cn_add_complex;

CREATE OR REPLACE FUNCTION cn_add_complex
(
	vr_application_id	UUID,
    vr_list_id			UUID,
    vr_node_type_id		UUID,
    vr_name				VARCHAR(255),
    vr_description		VARCHAR(2000),
    vr_creator_user_id	UUID,
    vr_creation_date	TIMESTAMP,
    vr_parent_list_id	UUID,
    vr_owner_id			UUID,
    vr_owner_type		VARCHAR(20)
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	INSERT INTO cn_lists(
		application_id,
		list_id,
		node_type_id,
		"name",
		description,
		creator_user_id,
		creation_date,
		parent_list_id,
		owner_id,
		owner_type,
		deleted
	)
	VALUES(
		vr_application_id,
		vr_list_id,
		vr_nodeTypeID,
		gfn_verify_string(vr_name),
		gfn_verify_string(vr_description),
		vr_creator_user_id,
		vr_creation_date,
		vr_parent_list_id,
		vr_owner_id,
		vr_owner_type,
		FALSE
	);
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;

	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
