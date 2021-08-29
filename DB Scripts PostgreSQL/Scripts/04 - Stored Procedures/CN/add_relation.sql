DROP FUNCTION IF EXISTS cn_add_relation;

CREATE OR REPLACE FUNCTION cn_add_relation
(
	vr_application_id		UUID,
	vr_relations			guid_triple_table_type[],
    vr_creator_user_id		UUID,
    vr_creation_date	 	TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result INTEGER = 0;
BEGIN
	RETURN cn_p_add_relation(vr_application_id, vr_relations, vr_creator_user_id, vr_creation_date, TRUE);
END;
$$ LANGUAGE plpgsql;

