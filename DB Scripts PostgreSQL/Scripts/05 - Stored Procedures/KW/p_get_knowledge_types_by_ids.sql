DROP FUNCTION IF EXISTS kw_p_get_knowledge_types_by_ids;

CREATE OR REPLACE FUNCTION kw_p_get_knowledge_types_by_ids
(
	vr_application_id		UUID,
	vr_knowledge_type_ids	UUID[],
	vr_total_count			BIGINT DEFAULT 0
)
RETURNS SETOF kw_knowledge_type_ret_composite
AS
$$
BEGIN
	RETURN QUERY
	SELECT kt.knowledge_type_id,
		   nt.name AS knowledge_type,
		   kt.node_select_type,
		   kt.evaluation_type,
		   kt.evaluators,
		   kt.pre_evaluate_by_owner,
		   kt.force_evaluators_describe,
		   kt.min_evaluations_count,
		   kt.searchable_after,
		   kt.score_scale,
		   kt.min_acceptable_score,
		   kt.convert_evaluators_to_experts,
		   kt.evaluations_editable,
		   kt.evaluations_editable_for_admin,
		   kt.evaluations_removable,
		   kt.unhide_evaluators,
		   kt.unhide_evaluations,
		   kt.unhide_node_creators,
		   kt.text_options,
		   nt.additional_id_pattern,
		   vr_total_count
	FROM UNNEST(vr_knowledge_type_ids) AS rf
		INNER JOIN kw_knowledge_types AS kt
		ON kt.application_id = vr_application_id AND kt.knowledge_type_id = rf
		INNER JOIN cn_node_types AS nt
		ON nt.application_id = vr_application_id AND nt.node_type_id = rf;
END;
$$ LANGUAGE plpgsql;

