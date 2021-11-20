DROP TYPE IF EXISTS kw_knowledge_type_ret_composite;

CREATE TYPE kw_knowledge_type_ret_composite AS (
	knowledge_type_id				UUID,
	knowledge_type					VARCHAR,
	node_select_type				VARCHAR,
	evaluation_type					VARCHAR,
	evaluators						VARCHAR,
	pre_evaluate_by_owner			BOOLEAN,
	force_evaluators_describe		BOOLEAN,
	min_evaluations_count			INTEGER,
	searchable_after				VARCHAR,
	score_scale						INTEGER,
	min_acceptable_score			FLOAT,
	convert_evaluators_to_experts	BOOLEAN,
	evaluations_editable			BOOLEAN,
	evaluations_editable_for_admin	BOOLEAN,
	evaluations_removable			BOOLEAN,
	unhide_evaluators				BOOLEAN,
	unhide_evaluations				BOOLEAN,
	unhide_node_creators			BOOLEAN,
	text_options					VARCHAR,
	additional_id_pattern			VARCHAR,
	total_count						BIGINT
);