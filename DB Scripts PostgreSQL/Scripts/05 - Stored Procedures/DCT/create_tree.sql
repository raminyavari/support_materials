DROP FUNCTION IF EXISTS dct_create_tree;

CREATE OR REPLACE FUNCTION dct_create_tree
(
	vr_application_id	UUID,
    vr_tree_id 			UUID,
    vr_is_private		BOOLEAN,
    vr_owner_id			UUID,
    vr_name			 	VARCHAR(256),
    vr_description	 	VARCHAR(1000),
    vr_current_user_id	UUID,
    vr_now	 			TIMESTAMP,
    vr_privacy			VARCHAR(20),
    vr_is_template		BOOLEAN
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	INSERT INTO dct_trees (
		application_id,
		tree_id,
		is_private,
		owner_id,
		"name",
		description,
		creator_user_id,
		creation_date,
		privacy,
		is_template,
		deleted
	)
	VALUES(
		vr_application_id,
		vr_tree_id,
		vr_isPrivate,
		vr_owner_id,
		gfn_verify_string(vr_name),
		gfn_verify_string(vr_description),
		vr_current_user_id,
		vr_now,
		vr_privacy,
		vr_isTemplate,
		FALSE
	);
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
