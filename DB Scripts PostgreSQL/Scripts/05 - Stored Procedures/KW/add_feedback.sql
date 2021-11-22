DROP FUNCTION IF EXISTS kw_add_feedback;

CREATE OR REPLACE FUNCTION kw_add_feedback
(
	vr_application_id	UUID,
    vr_knowledge_id		UUID,
	vr_user_id			UUID,
	vr_feedback_type_id INTEGER,
	vr_send_date	 	TIMESTAMP,
	vr_value			FLOAT,
	vr_description 		VARCHAR(2000)
)
RETURNS BIGINT
AS
$$
DECLARE
	vr_id	BIGINT;
BEGIN
	INSERT INTO kw_feedbacks (
		application_id,
		knowledge_id,
		user_id,
		feedback_type_id,
		send_date,
		"value",
		description,
		deleted
	)
	VALUES (
		vr_application_id,
		vr_knowledge_id,
		vr_user_id,
		vr_feedback_type_id,
		vr_send_date,
		COALESCE(vr_value, 0),
		gfn_verify_string(vr_description),
		FALSE
	)
	RETURNING "id"
	INTO vr_id;
	
	RETURN vr_id;
END;
$$ LANGUAGE plpgsql;

