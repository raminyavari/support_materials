DROP FUNCTION IF EXISTS cn_p_add_node;

CREATE OR REPLACE FUNCTION cn_p_add_node
(
	vr_application_id			UUID,
    vr_node_id					UUID,
    vr_additional_id			VARCHAR(50),
    vr_node_type_id				UUID,
    vr_node_type_additional_id 	VARCHAR(50),
    vr_document_tree_node_id	UUID,
    vr_previous_version_id		UUID,
    vr_name				 		VARCHAR(255),
    vr_description		 		VARCHAR,
    vr_tags				 		VARCHAR(2000),
    vr_searchable			 	BOOLEAN,
    vr_creator_user_id			UUID,
    vr_creation_date		 	TIMESTAMP,
    vr_parent_node_id			UUID,
    vr_owner_id					UUID,
    vr_add_member			 	BOOLEAN
)
RETURNS TABLE (
	"result"		INTEGER,
	error_message	VARCHAR(1000)
)
AS
$$
DECLARE
	vr_result	 		INTEGER;
	vr_error_message	VARCHAR(1000);
BEGIN
	vr_result := -1;
	vr_error_message := NULL;

	vr_name := gfn_verify_string(vr_name);
	vr_description := gfn_verify_string(vr_description);
	vr_tags := gfn_verify_string(vr_tags);
	
	IF vr_node_type_id IS NULL THEN
		vr_node_type_id = cn_fn_get_node_type_id(vr_application_id, vr_node_type_additional_id);
	END IF;
		
	IF vr_node_type_id IS NULL AND vr_parent_node_id IS NOT NULL THEN
		vr_node_type_id := (
			SELECT node_type_id 
			FROM cn_nodes 
			WHERE application_id = vr_application_id AND node_id = vr_parent_node_id
			LIMIT 1
		);
	END IF;
			
	
	IF EXISTS(
		SELECT * 
		FROM cn_nodes
		WHERE application_id = vr_application_id AND node_type_id = vr_node_type_id AND 
			vr_additional_id IS NOT NULL AND vr_additional_id <> '' AND additional_id = vr_additional_id
		LIMIT 1
	) THEN
		vr_result := -50;
		vr_error_message := 'AdditionalIDAlreadyExists';
		
		RETURN QUERY
		SELECT vr_result, vr_error_message;
	END IF;
	
	vr_searchable := COALESCE(vr_searchable, TRUE)::BOOLEAN;
	
	IF vr_previous_version_id = vr_node_id THEN 
		vr_previous_version_id := NULL;
	END IF;
	
	INSERT INTO cn_nodes(
		application_id,
		node_id,
		additional_id,
		node_type_id,
		document_tree_node_id,
		previous_version_id,
		"name",
		description,
		tags,
		creator_user_id,
		creation_date,
		deleted,
		parent_node_id,
		owner_id,
		searchable
	)
	VALUES(
		vr_application_id,
		vr_node_id,
		vr_additional_id,
		vr_node_type_id,
		vr_document_tree_node_id,
		vr_previous_version_id,
		vr_name,
		vr_description,
		vr_tags,
		vr_creator_user_id,
		vr_creation_date,
		FALSE,
		vr_parent_node_id,
		vr_owner_id,
		vr_searchable
	);
	
	vr_result := prvc_p_add_audience(vr_application_id, vr_node_id, vr_node_id, 'View', TRUE, NULL, NULL, NULL);
	
	IF vr_result <= 0 THEN
		vr_result := -3;
		
		RETURN QUERY
		SELECT vr_result, vr_error_message;
	END IF;
	
	IF vr_add_member = TRUE THEN
		vr_result := cn_p_add_member(vr_application_id, vr_node_id, vr_creator_user_id, 
			vr_creation_date, TRUE, FALSE, vr_creation_date, NULL);
		
		IF vr__result <= 0 THEN
			vr_result := -4;
			
			RETURN QUERY
			SELECT vr_result, vr_error_message;
		END IF;
	END IF;
	
	IF vr_searchable = TRUE AND vr_previous_version_id IS NOT NULL THEN
		UPDATE cn_nodes
		SET searchable = FALSE
		WHERE application_id = vr_application_id AND node_id = vr_previous_version_id;
	END IF;

	vr_result := 1;

	RETURN QUERY
	SELECT vr_result, vr_error_message;
END;
$$ LANGUAGE plpgsql;


