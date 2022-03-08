DROP FUNCTION IF EXISTS rv_get_deleted_states;

CREATE OR REPLACE FUNCTION rv_get_deleted_states
(
	vr_application_id	UUID,
	vr_count		 	INTEGER,
	vr_start_from		BIGINT
)
RETURNS TABLE (
	"id"					BIGINT,
	object_id				UUID,
	object_type				VARCHAR,
	date					TIMESTAMP,
	deleted					BOOLEAN,
	bidirectional			BOOLEAN,
	has_reverse				BOOLEAN,
	rel_source_id			UUID,
	rel_destination_id		UUID,
	rel_source_type			VARCHAR,
	rel_destination_type	VARCHAR,
	rel_creator_id			UUID
)
AS
$$
BEGIN
	IF COALESCE(vr_count, 0) < 1 THEN 
		vr_count := 1000;
	END IF;
	
	RETURN QUERY
	SELECT	d.id,
			d.object_id,
			d.object_type,
			d.date,
			d.deleted,
			CASE
				WHEN d.objectType = 'NodeRelation' THEN TRUE
				WHEN d.objectType = 'Friend' AND fr.are_friends = TRUE THEN TRUE
				ELSE FALSE
			END::BOOLEAN AS bidirectional,
			CASE
				WHEN d.objectType = 'Friend' AND fr.are_friends = FALSE THEN TRUE
				WHEN d.objectType = 'NodeMember' THEN TRUE
				WHEN d.objectType = 'Expert' THEN TRUE
				WHEN d.objectType = 'NodeLike' THEN TRUE
				WHEN d.objectType = 'ItemVisit' THEN TRUE
				WHEN d.objectType = 'NodeCreator' THEN TRUE
				WHEN d.objectType = 'TaggedItem' THEN TRUE
				WHEN d.objectType = 'WikiChange' THEN TRUE
				ELSE FALSE
			END::BOOLEAN AS has_reverse,
			CASE
				WHEN d.objectType = 'NodeCreator' THEN nc.node_id
				WHEN d.objectType = 'NodeRelation' THEN nr.source_node_id
				WHEN d.objectType = 'NodeMember' THEN nm.node_id
				WHEN d.objectType = 'Expert' THEN ex.node_id
				WHEN d.objectType = 'NodeLike' THEN nl.node_id
				WHEN d.objectType = 'ItemVisit' THEN iv.item_id
				WHEN d.objectType = 'Friend' THEN fr.sender_user_id
				WHEN d.objectType = 'WikiChange' THEN wt.owner_id
				WHEN d.objectType = 'TaggedItem' AND ti.context_type = 'WikiChange' THEN tgwt.owner_id
				WHEN d.objectType = 'TaggedItem' AND ti.context_type = 'Post' THEN tgps.owner_id
				WHEN d.objectType = 'TaggedItem' AND ti.context_type = 'Comment' THEN tgps2.owner_id
				ELSE NULL::UUID
			END::BOOLEAN AS rel_source_id,
			CASE
				WHEN d.objectType = 'NodeCreator' THEN nc.user_id
				WHEN d.objectType = 'NodeRelation' THEN nr.destination_node_id
				WHEN d.objectType = 'NodeMember' THEN nm.user_id
				WHEN d.objectType = 'Expert' THEN ex.user_id
				WHEN d.objectType = 'NodeLike' THEN nl.user_id
				WHEN d.objectType = 'ItemVisit' THEN iv.user_id
				WHEN d.objectType = 'Friend' THEN fr.receiver_user_id
				WHEN d.objectType = 'WikiChange' THEN wc.user_id
				WHEN d.objectType = 'TaggedItem' THEN ti.tagged_id
				ELSE NULL::UUID
			END::UUID AS rel_destination_id,
			CASE
				WHEN d.objectType = 'NodeCreator' THEN 'Node'
				WHEN d.objectType = 'NodeRelation' THEN 'Node'
				WHEN d.objectType = 'NodeMember' THEN 'Node'
				WHEN d.objectType = 'Expert' THEN 'Node'
				WHEN d.objectType = 'NodeLike' THEN 'Node'
				WHEN d.objectType = 'ItemVisit' AND iv.item_type = 'User' THEN 'User'
				WHEN d.objectType = 'ItemVisit' THEN 'Node'
				WHEN d.objectType = 'Friend' THEN 'User'
				WHEN d.objectType = 'WikiChange' THEN 'Node'
				WHEN d.objectType = 'TaggedItem' AND ti.context_type = 'WikiChange' THEN 'Node'
				WHEN d.objectType = 'TaggedItem' AND tgun.user_id IS NOT NULL THEN 'User'
				WHEN d.objectType = 'TaggedItem' THEN 'Node'
				ELSE NULL::VARCHAR
			END::VARCHAR AS rel_source_type,
			CASE
				WHEN d.objectType = 'NodeCreator' THEN 'User'
				WHEN d.objectType = 'NodeRelation' THEN 'User'
				WHEN d.objectType = 'NodeMember' THEN 'User'
				WHEN d.objectType = 'Expert' THEN 'User'
				WHEN d.objectType = 'NodeLike' THEN 'User'
				WHEN d.objectType = 'ItemVisit' THEN 'User'
				WHEN d.objectType = 'Friend' THEN 'User'
				WHEN d.objectType = 'WikiChange' THEN 'User'
				WHEN d.objectType = 'TaggedItem' THEN ti.tagged_type
				ELSE NULL::VARCHAR
			END::VARCHAR AS rel_destination_type,
			CASE
				WHEN d.objectType = 'TaggedItem' THEN ti.creator_user_id
				ELSE NULL::UUID
			END::UUID AS rel_creator_id
	FROM rv_deleted_states AS d
		LEFT JOIN cn_node_creators AS nc
		ON nc.application_id = vr_application_id AND nc.unique_id = d.object_id
		LEFT JOIN cn_node_relations AS nr
		ON nr.application_id = vr_application_id AND nr.unique_id = d.object_id
		LEFT JOIN cn_node_members AS nm
		ON nm.application_id = vr_application_id AND nm.unique_id = d.object_id
		LEFT JOIN cn_experts AS ex
		ON ex.application_id = vr_application_id AND ex.unique_id = d.object_id
		LEFT JOIN cn_node_likes AS nl
		ON nl.application_id = vr_application_id AND nl.unique_id = d.object_id
		LEFT JOIN usr_item_visits AS iv
		ON iv.application_id = vr_application_id AND iv.unique_id = d.object_id
		LEFT JOIN usr_friends AS fr
		ON fr.application_id = vr_application_id AND fr.unique_id = d.object_id
		LEFT JOIN wk_changes AS wc
		ON wc.application_id = vr_application_id AND wc.change_id = d.object_id
		LEFT JOIN wk_paragraphs AS wp
		ON wp.application_id = vr_application_id AND wp.paragraph_id = wc.paragraph_id
		LEFT JOIN wk_titles AS wt
		ON wt.application_id = vr_application_id AND wt.title_id = wp.title_id
		LEFT JOIN rv_tagged_items AS ti
		ON ti.application_id = vr_application_id AND ti.unique_id = d.object_id
		LEFT JOIN wk_paragraphs AS tgwp
		ON tgwp.application_id = vr_application_id AND tgwp.paragraph_id = ti.context_id
		LEFT JOIN wk_titles AS tgwt
		ON tgwt.application_id = vr_application_id AND tgwt.title_id = tgwp.title_id
		LEFT JOIN sh_post_shares AS tgps
		ON tgps.application_id = vr_application_id AND tgps.share_id = ti.context_id
		LEFT JOIN sh_comments AS tgpc
		ON tgpc.application_id = vr_application_id AND tgpc.comment_id = ti.context_id
		LEFT JOIN sh_post_shares AS tgps2
		ON tgps2.application_id = vr_application_id AND tgps2.share_id = tgpc.share_id
		LEFT JOIN users_normal AS tgun
		ON tgun.application_id = vr_application_id AND
			tgun.user_id = tgps.owner_id OR tgun.user_id = tgps2.owner_id
	WHERE d.application_id = vr_application_id AND d.id >= COALESCE(vr_start_from, 0)::BIGINT
	ORDER BY d.id ASC
	LIMIT vr_count;
END;
$$ LANGUAGE plpgsql;

