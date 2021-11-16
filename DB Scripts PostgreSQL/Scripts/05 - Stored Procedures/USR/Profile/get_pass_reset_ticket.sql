DROP FUNCTION IF EXISTS usr_get_pass_reset_ticket;

CREATE OR REPLACE FUNCTION usr_get_pass_reset_ticket
(
	vr_user_id	UUID
)
RETURNS UUID
AS
$$
BEGIN
	RETURN (
		SELECT pt.ticket AS "id"
		FROM usr_pass_reset_tickets AS pt
		WHERE pt.user_id = vr_user_id
		LIMIT 1
	);
END;
$$ LANGUAGE plpgsql;

