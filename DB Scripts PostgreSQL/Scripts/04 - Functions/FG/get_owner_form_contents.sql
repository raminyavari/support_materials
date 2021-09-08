DROP FUNCTION IF EXISTS fg_fn_get_owner_form_contents;

CREATE OR REPLACE FUNCTION fg_fn_get_owner_form_contents
(
	vr_application_id	UUID,
	vr_owner_id			UUID,
	vr_max_level	 	INTEGER
)
RETURNS VARCHAR
AS
$$
DECLARE
	vr_ret	VARCHAR;
BEGIN
	WITH RECURSIVE partitioned AS 
	(
		SELECT	owner_id,
				CASE 
					WHEN ie.type = 'Form' 
						THEN fg_fn_get_owner_form_contents(vr_application_id, ie.element_id, vr_max_level - 1)
					ELSE fg_fn_to_string(vr_application_id, ie.element_id, ie.type, 
						ie.text_value, ie.float_value, ie.bit_value, ie.date_value)
				END AS "content",
				ROW_NUMBER() OVER (PARTITION BY vr_owner_id ORDER BY ie.element_id) AS "number",
				COUNT(*) OVER (PARTITION BY vr_owner_id) AS "count"
		FROM fg_form_instances AS fi
			INNER JOIN fg_instance_elements AS ie
			ON ie.application_id = vr_application_id AND ie.instance_id = fi.instance_id AND 
				ie.type <> 'File' AND ie.deleted = FALSE
		WHERE fi.application_id = vr_application_id AND fi.owner_id = vr_owner_id AND fi.deleted = FALSE
	),
	fetched AS 
	(
		SELECT	"p".owner_id, "p".content AS full_content, "p".content, "p".number, "p".count 
		FROM partitioned AS "p"
		WHERE "p".number = 1

		UNION ALL

		SELECT	"p".owner_id, COALESCE("c".full_content, N'') || ' ' || COALESCE("p".content, N''), 
			"p".content, "p".number, "p".count
		FROM partitioned AS "p"
			INNER JOIN fetched AS "c" 
			ON "p".owner_id = "c".owner_id AND "p".number = "c".number + 1
		WHERE "p".number <= 95
	)
	SELECT vr_ret = f.full_content
	FROM fetched AS f
	WHERE f.number = (CASE WHEN f.count > 90 THEN 90 ELSE f.count END)
	LIMIT 1;
	
	RETURN vr_ret;
END;
$$ LANGUAGE PLPGSQL;