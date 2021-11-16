DROP FUNCTION IF EXISTS usr_set_pass_reset_ticket;

CREATE OR REPLACE FUNCTION usr_set_pass_reset_ticket
(
	vr_user_id	UUID,
    vr_ticket	UUID
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result	INTEGER;
BEGIN
	IF EXISTS (
		SELECT 1 
		FROM usr_pass_reset_tickets AS x
		WHERE x.user_id = vr_user_id
		LIMIT 1
	) THEN
		UPDATE usr_pass_reset_tickets AS pt
		SET ticket = vr_ticket
		WHERE pt.user_id = vr_user_id;
	ELSE
		INSERT INTO usr_pass_reset_tickets (
			user_id,
			ticket
		)
		VALUES(
			vr_user_id,
			vr_ticket
		);
	END IF;
	
	GET DIAGNOSTICS vr_result := ROW_COUNT;
	
	RETURN vr_result;
END;
$$ LANGUAGE plpgsql;

