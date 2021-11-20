DROP FUNCTION IF EXISTS kw_accept_reject_knowledge;

CREATE OR REPLACE FUNCTION kw_accept_reject_knowledge
(
	vr_application_id	UUID,
    vr_node_id			UUID,
    vr_current_user_id	UUID,
    vr_accept		 	BOOLEAN,
    vr_textOptions 		VARCHAR(1000),
    vr_description 		VARCHAR(2000),
    vr_now		 		TIMESTAMP
)
RETURNS INTEGER
AS
$$
DECLARE
	vr_result				INTEGER;
BEGIN
	vr_result := kw_p_accept_reject_knowledge(vr_application_id, vr_node_id, vr_accept);
	
	IF vr_result <= 0 THEN
		RETURN vr_result;
	END IF;
	
	-- Create history
	INSERT INTO kw_history (
		application_id,
		knowledge_id,
		"action",
		text_options,
		description,
		actor_user_id,
		action_date,
		wf_version_id,
		unique_id
	)
	VALUES (
		vr_application_id,
		vr_node_id,
		CASE WHEN COALESCE(vr_accept, FALSE) = TRUE THEN 'Accept' ELSE 'Reject' END,
		vr_text_options,
		vr_description,
		vr_current_user_id,
		vr_now,
		kw_fn_get_wf_version_id(vr_application_id, vr_node_id),
		gen_random_uuid()
	);
	-- end of create history
	
	SELECT 1::INTEGER;
END;
$$ LANGUAGE plpgsql;

