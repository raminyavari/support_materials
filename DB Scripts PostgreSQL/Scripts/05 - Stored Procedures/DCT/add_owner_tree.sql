DROP FUNCTION IF EXISTS dct_add_owner_tree;

CREATE OR REPLACE FUNCTION dct_add_owner_tree
(
	vr_application_id	UUID,
	vr_owner_id			UUID,
	vr_tree_id			UUID,
	vr_current_user_id	UUID,
	vr_now		 		TIMESTAMP
)
RETURNS BOOLEAN
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF EXISTS(
		SELECT * 
		FROM dct_tree_owners AS o
		WHERE o.application_id = vr_application_id AND
			o.owner_id = vr_owner_id AND o.tree_id = vr_tree_id
		LIMIT 1
	) THEN
		UPDATE dct_tree_owners AS tr
		SET deleted = FALSE,
			last_modifier_user_id = vr_current_user_id,
			last_modification_date = vr_now
		WHERE tr.application_id = vr_application_id AND 
			tr.owner_id = vr_owner_id AND tr.tree_id = vr_tree_id;
	ELSE
		INSERT INTO dct_tree_owners (
			application_id,
			owner_id,
			tree_id,
			unique_id,
			creator_user_id,
			creation_date,
			deleted
		)
		VALUES(
			vr_application_id,
			vr_owner_id,
			vr_tree_id,
			gen_random_uuid(),
			vr_current_user_id,
			vr_now,
			FALSE
		);
	END IF;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;
