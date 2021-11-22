DROP FUNCTION IF EXISTS kw_activate_necessary_item;

CREATE OR REPLACE FUNCTION kw_activate_necessary_item
(
	vr_application_id	UUID,
    vr_node_type_id		UUID,
	vr_item_name		VARCHAR(50),
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF EXISTS (
		SELECT 1
		FROM kw_necessary_items AS ni
		WHERE ni.application_id = vr_application_id AND 
			ni.node_type_id = vr_node_type_id AND nt.item_name = vr_item_name
		LIMIT 1
	) THEN
		UPDATE kw_necessary_items AS ni
		SET last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now,
			deleted = FALSE
		WHERE ni.application_id = vr_application_id AND 
			ni.node_type_id = vr_node_type_id AND ni.item_name = vr_item_name;
	ELSE
		INSERT INTO kw_necessary_items (
			application_id,
			node_type_id,
			item_name,
			creator_user_id,
			creation_date,
			deleted
		)
		VALUES (
			vr_application_id,
			vr_node_type_id,
			vr_item_name,
			vr_current_user_id,
			vr_now,
			FALSE
		);
	END IF;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

