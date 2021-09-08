DROP FUNCTION IF EXISTS fg_fn_filter_instance_owners;

CREATE OR REPLACE FUNCTION fg_fn_filter_instance_owners
(
	vr_application_id	UUID,
	vr_owner_element_id	UUID, -- owner_element is a form_element of type 'form'
	vr_owner_ids		UUID[],
	vr_form_filters		form_filter_table_type[],
	vr_match_all	 	BOOLEAN
)
RETURNS TABLE (
	owner_id	UUID,
	"rank"		FLOAT
)
AS
$$
DECLARE
	vr_form_instance_owners	guid_pair_table_type[]; -- first_value: instance_id, second_value: owner_id
	vr_instance_ids			UUID[];
BEGIN
	vr_form_instance_owners := ARRAY(
		SELECT ROW(COALESCE(x.instance_id, gfn_new_guid()), "ref")
		FROM UNNEST(vr_owner_ids) AS "ref"
			LEFT JOIN fg_fn_get_owner_form_instance_ids(vr_application_id, vr_owner_ids, NULL, NULL, NULL) AS x
			ON x.owner_id = "ref"
	);
	
	vr_instance_ids := ARRAY(
		SELECT DISTINCT "ref".first_value
		FROM UNNEST(vr_form_instance_owners) AS "ref"
	);
	
	RETURN QUERY
	SELECT o.second_value, SUM("ref".rank)
	FROM UNNEST(vr_form_instance_owners) AS o
		INNER JOIN fg_fn_filter_instances(
			vr_application_id, vr_owner_element_id, vr_instance_ids, vr_form_filters, ',', vr_match_all
		) AS "ref"
		ON "ref".instance_id = o.first_value
	GROUP BY o.second_value;
END;
$$ LANGUAGE PLPGSQL;