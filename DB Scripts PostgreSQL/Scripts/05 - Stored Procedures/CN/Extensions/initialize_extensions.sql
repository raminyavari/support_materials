DROP FUNCTION IF EXISTS cn_initialize_extensions;

CREATE OR REPLACE FUNCTION cn_initialize_extensions
(
	vr_application_id		UUID,
	vr_owner_id				UUID,
	vr_enabled_extensions	string_table_type[],
	vr_disabled_extensions	string_table_type[],
	vr_current_user_id		UUID,
	vr_now		 			TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_sequence_number	INTEGER;
BEGIN
	vr_sequence_number := COALESCE((
		SELECT MAX(ex.sequence_number) 
		FROM cn_extensions AS ex
		WHERE ex.application_id = vr_application_id AND ex.owner_id = vr_owner_id
	), 0)::INTEGER;
	
	WITH "data" AS (
		SELECT rf.value AS ext, disabled, rf.seq
		FROM (
				SELECT x.val, FALSE AS disabled, x.seq::INTEGER
				FROM UNNEST(vr_enabled_extensions) WITH ORDINALITY AS x(val, seq)

				UNION ALL

				SELECT x.val, TRUE AS disabled, x.seq::INTEGER
				FROM UNNEST(vr_disabled_extensions) WITH ORDINALITY AS x(val, seq)
			) AS rf
		WHERE rf.value NOT IN (
				SELECT ex.extension
				FROM cn_extensions AS ex
				WHERE ex.application_id = vr_application_id AND ex.owner_id = vr_owner_id
			)
	),
	seq_data AS (
		SELECT	ROW_NUMBER() OVER (ORDER BY d.disabled DESC, d.seq ASC) AS "seq",
				d.ext,
				d.disabled
		FROM "data" AS d
	)
	INSERT INTO cn_extensions (
		application_id,
		owner_id,
		"extension",
		sequence_number,
		creator_user_id,
		creation_date,
		deleted
	)
	SELECT vr_application_id,
		   vr_owner_id, 
		   d.ext,
		   d.seq + vr_sequence_number,
		   vr_current_user_id,
		   vr_now,
		   d.disabled
	FROM seq_data AS d;
		
	RETURN 1::INTEGER;
END;
$$ LANGUAGE plpgsql;
