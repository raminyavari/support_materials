DROP FUNCTION IF EXISTS fg_get_form_statistics;

CREATE OR REPLACE FUNCTION fg_get_form_statistics
(
	vr_application_id	UUID,
	vr_owner_id 		UUID,
	vr_instance_id 		UUID
)
RETURNS TABLE (
	weight_sum		FLOAT,
	"sum"			FLOAT,
	weighted_sum	FLOAT,
	"avg"			FLOAT,
	weighted_avg	FLOAT,
	"min"			FLOAT,
	"max"			FLOAT,
	var				FLOAT,
	st_dev			FLOAT
)
AS
$$
BEGIN
	RETURN QUERY
	SELECT	SUM(x.weight) AS weight_sum,
			SUM(x.avg) AS "sum",
			SUM(x.weighted_avg) AS weighted_sum,
			AVG(x.avg) AS "avg",
			CASE 
				WHEN SUM(x.weight) = 0 THEN AVG(x.avg) 
				ELSE SUM(x.weighted_avg) / SUM(x.weight) 
			END AS weighted_avg,
			MIN(x.avg) AS "min",
			MAX(x.avg) AS "max",
			VAR(x.avg) AS var,
			STDEV(x.avg) AS st_dev
	FROM (
			SELECT	efe.element_id,
					COALESCE(MAX(efe.weight), 0) AS weight,
					MIN(ie.float_value) AS "min",
					MAX(ie.float_value) AS "max",
					AVG(ie.float_value) AS "avg",
					(AVG(ie.float_value) * COALESCE(MAX(efe.weight), 0)) AS weighted_avg,
					COALESCE(VAR(ie.float_value), 0) AS var,
					COALESCE(STDEV(ie.float_value), 0) AS st_dev
			FROM fg_form_instances AS fi
				INNER JOIN fg_instance_elements AS ie
				ON ie.application_id = vr_application_id AND ie.instance_id = fi.instance_id AND 
					ie.float_value IS NOT NULL AND ie.deleted = FALSE
				INNER JOIN fg_extended_form_elements AS efe
				ON efe.application_id = vr_application_id AND 
					efe.element_id = ie.ref_element_id AND efe.deleted = FALSE
			WHERE fi.application_id = vr_application_id AND fi.deleted = FALSE AND
				(vr_owner_id IS NOT NULL OR vr_instance_id IS NOT NULL) AND
				(vr_owner_id IS NULL OR fi.owner_id = vr_owner_id) AND
				(vr_instance_id IS NULL OR fi.instance_id = vr_instance_id)
			GROUP BY efe.element_id
		) AS x;
END;
$$ LANGUAGE plpgsql;

