DROP TYPE IF EXISTS ntfn_message_template_ret_composite;

CREATE TYPE ntfn_message_template_ret_composite AS (
	template_id				UUID,
	owner_id				UUID,
	body_text				VARCHAR,
	audience_type			VARCHAR,
	audience_ref_owner_id	UUID,
	audience_node_id		UUID,
	audience_node_name		VARCHAR,
	audience_node_type_id	UUID,
	audience_node_type		VARCHAR,
	audience_node_admin		BOOLEAN,
	total_count				INTEGER
);