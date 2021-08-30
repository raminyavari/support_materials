DROP FUNCTION IF EXISTS cn_p_get_node_types_by_ids;

CREATE OR REPLACE FUNCTION cn_p_get_node_types_by_ids
(
	vr_application_id	UUID,
	vr_node_type_ids	UUID[],
	vr_total_count		INTEGER DEFAULT 0
)
RETURNS SETOF cn_node_type_ret_composite
AS
$$
BEGIN
	IF COALESCE(vr_total_count, 0) <= 0 THEN
		vr_total_count = COALESCE(ARRAY_LENGTH(vr_node_type_ids, 1), 0)::INTEGER;
	END IF;

	RETURN QUERY
	SELECT nt.node_type_id,
		   nt.parent_id,
		   nt.name,
		   nt.additional_id,
		   nt.additional_id_pattern,
		   nt.deleted AS archive,
		   (CASE WHEN COALESCE(s.service_title, N'') = N'' THEN FALSE ELSE TRUE END)::BOOLEAN AS is_service,
		   vr_total_count
	FROM UNNEST(vr_node_type_ids) WITH ORDINALITY AS ex("id", "order")
		INNER JOIN cn_node_types AS nt
		ON nt.application_id = vr_application_id AND nt.node_type_id = ex.id
		LEFT JOIN cn_services AS s
		ON s.application_id = vr_application_id AND s.node_type_id = nt.node_type_id AND s.deleted = FALSE
	ORDER BY (CASE 
			  	WHEN nt.deleted = TRUE THEN nt.last_modification_date::VARCHAR(100) 
			  	ELSE (ex.order + 1000000)::VARCHAR(100) 
			  END) ASC;
END;
$$ LANGUAGE plpgsql;

