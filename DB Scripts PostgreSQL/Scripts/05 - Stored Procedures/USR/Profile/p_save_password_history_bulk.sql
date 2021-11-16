DROP FUNCTION IF EXISTS usr_p_save_password_history_bulk;

CREATE OR REPLACE FUNCTION usr_p_save_password_history_bulk
(
	vr_items			guid_string_table_type[],
    vr_auto_generated	BOOLEAN,
    vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	INSERT INTO usr_passwords_history (
		user_id,
		"password",
		set_date,
		auto_generated
	)
	SELECT	i.first_value,
			i.second_value,
			vr_now,
			COALESCE(vr_auto_generated, FALSE)
	FROM UNNEST(vr_items) AS i;

	GET DIAGNOSTICS vr_result := ROW_COUNT;

	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

