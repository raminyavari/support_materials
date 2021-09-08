DROP PROCEDURE IF EXISTS _cn_add_node;

CREATE OR REPLACE PROCEDURE _cn_add_node
(
	vr_application_id			UUID,
    vr_node_id					UUID,
    vr_additional_id_main		VARCHAR(300),
    vr_additional_id			VARCHAR(50),
    vr_node_type_id				UUID,
    vr_node_type_additional_id 	VARCHAR(20),
    vr_document_tree_node_id	UUID,
    vr_name				 		VARCHAR(255),
    vr_description		 		VARCHAR,
    vr_tags				 		VARCHAR(2000),
    vr_searchable			 	BOOLEAN,
    vr_creator_user_id			UUID,
    vr_creation_date		 	TIMESTAMP,
    vr_parent_node_id			UUID,
    vr_add_member			 	BOOLEAN,
	INOUT vr_result	 			INTEGER,
	INOUT vr_error_message		VARCHAR(1000)
)
AS
$$
DECLARE
BEGIN
	vr_result := -1;
	vr_error_message := NULL;

	vr_searchable := COALESCE(vr_searchable, TRUE)::BOOLEAN;
	
	SELECT	vr_result = x.result,
			vr_error_message = x.error_message
	FROM cn_p_add_node(vr_application_id, vr_node_id, vr_additional_id, vr_node_type_id, 
		vr_node_type_additional_id, vr_document_tree_node_id, NULL, vr_name, vr_description, vr_tags, 
		vr_searchable, vr_creator_user_id, vr_creation_date, vr_parent_node_id, null, vr_add_member) AS x
	LIMIT 1;
		
	UPDATE cn_nodes AS x
	SET additional_id_main = vr_additional_id_main
	WHERE x.application_id = vr_application_id AND x.node_id = vr_node_id;
	
	IF vr_result <= 0 THEN
		CALL gfn_raise_exception(vr_result, NULL);
	END IF;
END;
$$ LANGUAGE plpgsql;



DROP FUNCTION IF EXISTS cn_add_node;

CREATE OR REPLACE FUNCTION cn_add_node
(
	vr_application_id			UUID,
    vr_node_id					UUID,
    vr_additional_id_main		VARCHAR(300),
    vr_additional_id			VARCHAR(50),
    vr_node_type_id				UUID,
    vr_node_type_additional_id 	VARCHAR(20),
    vr_document_tree_node_id	UUID,
    vr_name				 		VARCHAR(255),
    vr_description		 		VARCHAR,
    vr_tags				 		VARCHAR(2000),
    vr_searchable			 	BOOLEAN,
    vr_creator_user_id			UUID,
    vr_creation_date		 	TIMESTAMP,
    vr_parent_node_id			UUID,
    vr_add_member			 	BOOLEAN
)
RETURNS TABLE (
	"result"		INTEGER,
	error_message	VARCHAR(1000)
)
AS
$$
DECLARE
	vr_result 			INTEGER = 0;
	vr_error_message	VARCHAR(1000);
BEGIN
	CALL _cn_add_node(vr_application_id, vr_node_id, vr_additional_id_main, vr_additional_id, 
					  vr_node_type_id, vr_node_type_additional_id, vr_document_tree_node_id,
					  vr_name, vr_description, vr_tags, vr_searchable, vr_creator_user_id, 
					  vr_creation_date, vr_parent_node_id, vr_add_member, vr_result, vr_error_message);
	
	RETURN QUERY 
	SELECT vr_result, vr_error_message;
END;
$$ LANGUAGE plpgsql;

