
DROP PROCEDURE IF EXISTS rv_overal_report;

CREATE PROCEDURE rv_overal_report
	vr_application_id	UUID,
	vr_current_user_id	UUID,
	vr_beginDate	 TIMESTAMP,
	vr_finish_date	 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT N'تعداد کاربران' AS item_name, COUNT(ref.user_id) AS count
	FROM users_normal AS ref
	WHERE ref.application_id = vr_application_id AND 
		(vr_beginDate IS NULL OR ref.creation_date >= vr_beginDate) AND
		(vr_finish_date IS NULL OR ref.creation_date <= vr_finish_date) AND ref.is_approved = TRUE
			
	UNION ALL
	
	SELECT N'تعداد کاربران با پروفایل تکمیل شده' AS item_name, COUNT(ref.user_id) AS count
	FROM users_normal AS ref
	WHERE ref.application_id = vr_application_id AND
		ref.first_name IS NOT NULL AND ref.first_name <> N'' AND
		ref.last_name IS NOT NULL AND ref.last_name <> N'' AND
		(vr_beginDate IS NULL OR ref.creation_date >= vr_beginDate) AND
		(vr_finish_date IS NULL OR ref.creation_date <= vr_finish_date) AND ref.is_approved = TRUE
			
	UNION ALL
	
	SELECT N'تعداد کاربران فعال' + ' (' + N'15 روزه' + N')' AS item_name, COUNT(ref.user_id) AS count
	FROM users_normal AS ref
	WHERE ref.application_id = vr_application_id AND
		ref.last_activity_date >= DATEADD(DAY, -15, GETDATE()) AND ref.is_approved = TRUE
			
	UNION ALL
	
	SELECT N'تعداد کاربران فعال' + ' (' + N'30 روزه' + N')' AS item_name, COUNT(ref.user_id) AS count
	FROM users_normal AS ref
	WHERE ref.application_id = vr_application_id AND
		ref.last_activity_date >= DATEADD(DAY, -30, GETDATE()) AND ref.is_approved = TRUE

	UNION ALL

	SELECT N'تعداد پرسش ها', COUNT(QuestionID)
	FROM qa_questions
	WHERE ApplicationID = vr_application_id AND deleted = FALSE AND
		(vr_beginDate IS NULL OR SendDate >= vr_beginDate) AND
		(vr_finish_date IS NULL OR SendDate <= vr_finish_date)
		
	UNION ALL

	SELECT N'تعداد پرسش های دارای بهترین پاسخ', COUNT(QuestionID)
	FROM qa_questions
	WHERE ApplicationID = vr_application_id AND status = N'Accepted' AND 
		PublicationDate IS NOT NULL AND deleted = FALSE AND 
		(vr_beginDate IS NULL OR SendDate >= vr_beginDate) AND
		(vr_finish_date IS NULL OR SendDate <= vr_finish_date)
		
	UNION ALL

	SELECT N'تعداد خبره های تعریف شده' + ' (' + N'کل خبره ها' + N')', COUNT(ex.user_id) 
	FROM cn_experts AS ex
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = ex.user_id
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = ex.node_id
	WHERE ex.application_id = vr_application_id AND 
		(ex.approved = TRUE OR ex.social_approved = TRUE) AND
		un.is_approved = TRUE AND nd.deleted = FALSE
		
		
	UNION ALL

	SELECT N'تعداد کاربران خبره' + N' (' + N'کل خبره ها' + N')', COUNT(CNT)
	FROM (
			SELECT COUNT(un.user_id) AS cnt
			FROM cn_experts AS ex
				INNER JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = ex.user_id
				INNER JOIN cn_view_nodes_normal AS nd
				ON nd.application_id = vr_application_id AND nd.node_id = ex.node_id
			WHERE ex.application_id = vr_application_id AND 
				(ex.approved = TRUE OR ex.social_approved = TRUE) AND
				un.is_approved = TRUE AND nd.deleted = FALSE
			GROUP BY un.user_id
		) AS ref
	
	UNION ALL

	SELECT N'تعداد لایک های پست ها', COUNT(sl.share_id)
	FROM sh_share_likes AS sl
	WHERE sl.application_id = vr_application_id AND sl.like = TRUE AND
		(vr_beginDate IS NULL OR sl.date >= vr_beginDate) AND
		(vr_finish_date IS NULL OR sl.date <= vr_finish_date)
		
	UNION ALL

	SELECT N'تعداد لایک های کامنت ها', COUNT(sl.comment_id)
	FROM sh_comment_likes AS sl
	WHERE sl.application_id = vr_application_id AND sl.like = TRUE AND
		(vr_beginDate IS NULL OR sl.date >= vr_beginDate) AND
		(vr_finish_date IS NULL OR sl.date <= vr_finish_date)
		
	UNION ALL

	SELECT N'تعداد لایک های صفحات', COUNT(nl.node_id)
	FROM cn_node_likes AS nl
	WHERE nl.application_id = vr_application_id AND nl.deleted = FALSE AND
		(vr_beginDate IS NULL OR nl.like_date >= vr_beginDate) AND
		(vr_finish_date IS NULL OR nl.like_date <= vr_finish_date)
			
	UNION ALL

	SELECT N'تعداد پست ها', COUNT(ps.share_id)
	FROM sh_post_shares AS ps
	WHERE ps.application_id = vr_application_id AND ps.deleted = FALSE AND
		(vr_beginDate IS NULL OR ps.send_date >= vr_beginDate) AND
		(vr_finish_date IS NULL OR ps.send_date <= vr_finish_date)
	
	UNION ALL

	SELECT N'تعداد کامنت ها', COUNT(c.comment_id)
	FROM sh_comments AS c
	WHERE c.application_id = vr_application_id AND c.deleted = FALSE AND
		(vr_beginDate IS NULL OR c.send_date >= vr_beginDate) AND
		(vr_finish_date IS NULL OR c.send_date <= vr_finish_date)
		
	UNION ALL

	SELECT N'تعداد دانش ها', COUNT(KnowledgeID)
	FROM kw_view_knowledges
	WHERE ApplicationID = vr_application_id AND deleted = FALSE AND
		(vr_beginDate IS NULL OR CreationDate >= vr_beginDate) AND
		(vr_finish_date IS NULL OR CreationDate <= vr_finish_date)

	UNION ALL

	SELECT N'تعداد دانش های تایید شده', COUNT(KnowledgeID)
	FROM kw_view_knowledges
	WHERE ApplicationID = vr_application_id AND 
		status = N'Accepted' AND deleted = FALSE AND
		(vr_beginDate IS NULL OR COALESCE(PublicationDate, CreationDate) >= vr_beginDate) AND
		(vr_finish_date IS NULL OR COALESCE(PublicationDate, CreationDate) <= vr_finish_date)
			
	UNION ALL
	
	SELECT x.item_name, x.count
	FROM (
			SELECT TOP(1000000) a.item_name, a.count
			FROM (
					SELECT	(N'تعداد ' + nt.name + (CASE WHEN ref.type = N'Count' THEN N'' ELSE N' - منتشر شده' END)) AS item_name, 
							COALESCE(ref.count, 0) AS count,
							COALESCE(ref.total_count, 0) AS total_count
					FROM (
							SELECT	NodeTypeID, 
									COUNT(NodeID) AS count, 
									COUNT(NodeID) AS total_count, 
									N'Count' AS type
							FROM cn_view_nodes_normal
							WHERE ApplicationID = vr_application_id AND deleted = FALSE AND
								(vr_beginDate IS NULL OR CreationDate >= vr_beginDate) AND
								(vr_finish_date IS NULL OR CreationDate <= vr_finish_date)
							GROUP BY NodeTypeID
							
							UNION ALL
							
							SELECT	NodeTypeID, 
									SUM(CAST((CASE WHEN ISNULL.searchable, TRUE = 1 THEN 1 ELSE 0 END) AS integer)) AS count,
									COUNT(NodeID) AS total_count,
									N'Published' AS type
							FROM cn_view_nodes_normal
							WHERE ApplicationID = vr_application_id AND deleted = FALSE AND
								(vr_beginDate IS NULL OR CreationDate >= vr_beginDate) AND
								(vr_finish_date IS NULL OR CreationDate <= vr_finish_date)
							GROUP BY NodeTypeID
						) AS ref
						RIGHT JOIN cn_node_types AS nt
						ON nt.application_id = vr_application_id AND nt.node_type_id = ref.node_type_id
					WHERE nt.application_id = vr_application_id AND nt.deleted = FALSE
				) AS a
			ORDER BY a.total_count DESC, a.item_name ASC
		) AS x
END;


DROP PROCEDURE IF EXISTS rv_logs_report;

CREATE PROCEDURE rv_logs_report
	vr_application_id		UUID,
	vr_current_user_id		UUID,
	vr_user_id				UUID,
	vr_actionsTemp		StringTableType readonly,
	vr_iPAddressesTemp	StringTableType readonly,
	vr_level				varchar(20),
	vr_not_authorized	 BOOLEAN,
	vr_anonymous		 BOOLEAN,
	vr_beginDate		 TIMESTAMP,
	vr_finish_date		 TIMESTAMP,
	vr_count			 INTEGER,
	vr_lower_boundary		bigint
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_actions StringTableType
	INSERT INTO vr_actions SELECT * FROM vr_actionsTemp
	
	DECLARE vr_actionExists BOOLEAN = CASE WHEN EXISTS(SELECT TOP(1) * FROM vr_actions) THEN 1 ELSE 0 END
	
	DECLARE vr_iPAddresses StringTableType
	INSERT INTO vr_iPAddresses SELECT * FROM vr_iPAddressesTemp
	
	DECLARE vr_iPExists BOOLEAN = CASE WHEN EXISTS(SELECT TOP(1) * FROM vr_iPAddresses) THEN 1 ELSE 0 END
	
	IF vr_not_authorized IS NULL SET vr_not_authorized = 0
	IF vr_level = N'' SET vr_level = NULL
	
	DECLARE vr_empty UUID = N'00000000-0000-0000-0000-000000000000'
	
	SET vr_anonymous = COALESCE(vr_anonymous, 0)
	IF vr_anonymous = 1 SET vr_user_id = NULL
	
	SELECT TOP(COALESCE(vr_count, 2000))
		(ref.row_number_hide + ref.rev_row_number_hide - 1) AS total_count_hide,
		ref.*
	FROM (
			SELECT	ROW_NUMBER() OVER (ORDER BY lg.log_id DESC) AS row_number_hide,
					ROW_NUMBER() OVER (ORDER BY lg.log_id ASC) AS rev_row_number_hide,
					lg.log_id AS log_id_hide,
					un.user_id AS user_id_hide,
					RTRIM(LTRIM(COALESCE(un.first_name, N'') + N' ' + 
						COALESCE(un.last_name, N''))) AS full_name,
					lg.action AS action_dic,
					lg.level AS level_dic,
					CASE 
						WHEN COALESCE(lg.not_authorized, FALSE) = 0 THEN N'' 
						ELSE N'بله' 
					END AS not_authorized,
					lg.date,
					lg.host_address,
					lg.host_name,
					CASE 
						WHEN lg.subject_id = vr_empty THEN NULL 
						ELSE lg.subject_id
					END AS subject_id,
					del_first.object_type AS first_type_hide,
					lg.second_subject_id,
					del_second.object_type AS second_type_hide,
					lg.third_subject_id,
					del_third.object_type AS third_type_hide,
					lg.fourth_subject_id,
					del_fourth.object_type AS fourth_type_hide,
					lg.info AS info_hide_c
			FROM lg_logs AS lg
				LEFT JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = lg.user_id
				LEFT JOIN rv_deleted_states AS del_first
				ON del_first.application_id = vr_application_id AND
					del_first.object_id = lg.subject_id
				LEFT JOIN rv_deleted_states AS del_second
				ON del_second.application_id = vr_application_id AND
					del_second.object_id = lg.second_subject_id
				LEFT JOIN rv_deleted_states AS del_third
				ON del_third.application_id = vr_application_id AND
					del_third.object_id = lg.third_subject_id
				LEFT JOIN rv_deleted_states AS del_fourth
				ON del_fourth.application_id = vr_application_id AND
					del_fourth.object_id = lg.fourth_subject_id
			WHERE lg.application_id = vr_application_id AND 
				(vr_user_id IS NULL OR lg.user_id = vr_user_id) AND
				(vr_anonymous = 0 OR lg.user_id = vr_empty) AND
				(vr_actionExists = 0 OR lg.action IN (SELECT * FROM vr_actions)) AND
				(vr_iPExists = 0 OR lg.host_address IN (SELECT * FROM vr_iPAddresses)) AND
				(vr_level IS NULL OR lg.level = vr_level) AND
				(vr_beginDate IS NULL OR lg.date >= vr_beginDate) AND
				(vr_finish_date IS NULL OR lg.date <= vr_finish_date) AND
				(vr_not_authorized = 0 OR lg.not_authorized = TRUE)
		) AS ref
	WHERE ref.row_number_hide >= COALESCE(vr_lower_boundary, 0)
	ORDER BY ref.row_number_hide ASC
	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'},' +
			'"Action_Dic": {"Action": "JSON", "Shows": "Info_HideC"},' +
			'"SubjectID": {"Action": "Link", "Type": "[first_type_hide]",' +
				'"Requires": {"ID": "SubjectID"}' +
			'},' +
			'"SecondSubjectID": {"Action": "Link", "Type": "[second_type_hide]",' +
				'"Requires": {"ID": "SecondSubjectID"}' +
			'},' +
			'"ThirdSubjectID": {"Action": "Link", "Type": "[third_type_hide]",' +
				'"Requires": {"ID": "ThirdSubjectID"}' +
			'},' +
			'"FourthSubjectID": {"Action": "Link", "Type": "[fourth_type_hide]",' +
				'"Requires": {"ID": "FourthSubjectID"}' +
			'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS rv_error_logs_report;

CREATE PROCEDURE rv_error_logs_report
	vr_application_id	UUID,
	vr_current_user_id	UUID,
	vr_level			varchar(20),
	vr_beginDate	 TIMESTAMP,
	vr_finish_date	 TIMESTAMP,
	vr_count		 INTEGER,
	vr_lower_boundary	bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_level = N'' SET vr_level = NULL
	
	SELECT TOP(COALESCE(vr_count, 2000))
		(ref.row_number_hide + ref.rev_row_number_hide - 1) AS total_count_hide,
		ref.*
	FROM (
			SELECT	ROW_NUMBER() OVER (ORDER BY lg.log_id DESC) AS row_number_hide,
					ROW_NUMBER() OVER (ORDER BY lg.log_id ASC) AS rev_row_number_hide,
					lg.log_id AS log_id_hide,
					lg.subject,
					lg.level AS level_dic,
					lg.description AS description_hide_c,
					lg.date
			FROM lg_error_logs AS lg
			WHERE lg.application_id = vr_application_id AND 
				(vr_level IS NULL OR lg.level = vr_level) AND
				(vr_beginDate IS NULL OR lg.date >= vr_beginDate) AND
				(vr_finish_date IS NULL OR lg.date <= vr_finish_date)
		) AS ref
	WHERE ref.row_number_hide >= COALESCE(vr_lower_boundary, 0)
	ORDER BY ref.row_number_hide ASC
	
	SELECT ('{' +
			'"Subject": {"Action": "Show", "Shows": "Description_HideC"}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS rv_knowledge_supply_indicators_report;

CREATE PROCEDURE rv_knowledge_supply_indicators_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_nodeTypeID				UUID,
	vr_creatorNodeTypeID		UUID,
	vr_strNodeIDs				varchar(max),
	vr_delimiter				char,
	vr_lower_creation_date_limit TIMESTAMP,
	vr_upper_creation_date_limit TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_creatorNodeIDs GuidTableType

	INSERT INTO vr_creatorNodeIDs (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strNodeIDs, vr_delimiter) AS ref

	DECLARE vr_creatorCount INTEGER = (SELECT COUNT(*) FROM vr_creatorNodeIDs)

	SELECT	r.group_id AS group_id_hide,
			MAX(n.name) AS group_name,
			COUNT(DISTINCT nm.user_id) AS members_count,
			MAX(r.contents_count) AS contents_count,
			MAX(r.average_collaboration_share) AS average_collaboration_share,
			MAX(r.accepted_count) AS accepted_count,
			MAX(r.average_accepted_score) AS average_accepted_score,
			MAX(r.published_count) AS published_count,
			MAX(r.answers_count) AS answers_count,
			MAX(r.wiki_changes_count) AS wiki_changes_count
	FROM (
			SELECT groups.node_id AS group_id, 
				COUNT(contents.node_id) AS contents_count,
				SUM(nc.collaboration_share) / COUNT(contents.node_id) AS average_collaboration_share,
				SUM(CASE WHEN contents.status = N'Accepted' THEN 1 ELSE 0 END) AS accepted_count,
				SUM(
					CASE 
						WHEN contents.status = N'Accepted' THEN COALESCE(contents.score, 0) 
						ELSE 0 
					END
				) / COUNT(contents.node_id) AS average_accepted_score,
				SUM(CASE WHEN contents.searchable = TRUE THEN 1 ElSE 0 END) AS published_count,
				0 AS answers_count,
				0 AS wiki_changes_count
			FROM cn_nodes AS groups
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id AND nm.node_id = groups.node_id AND
					nm.is_pending = FALSE
				INNER JOIN cn_node_creators AS nc
				ON nc.application_id = vr_application_id AND nc.user_id = nm.user_id
				INNER JOIN cn_nodes AS contents
				ON contents.application_id = vr_application_id AND contents.node_id = nc.node_id
			WHERE groups.application_id = vr_application_id AND (
					(vr_creatorCount > 0 AND groups.node_id IN (SELECT * FROM vr_creatorNodeIDs)) OR
					(vr_creatorCount = 0 AND
						(vr_creatorNodeTypeID IS NULL OR groups.node_type_id = vr_creatorNodeTypeID)
					)
				) AND groups.deleted = FALSE AND
				nc.deleted = FALSE AND contents.node_type_id = vr_nodeTypeID AND 
				(vr_lower_creation_date_limit IS NULL OR contents.creation_date >= vr_lower_creation_date_limit) AND
				(vr_upper_creation_date_limit IS NULL OR contents.creation_date <= vr_upper_creation_date_limit) AND
				contents.deleted = FALSE
			GROUP BY groups.node_id

			UNION ALL

			SELECT groups.node_id AS group_id,
				0 AS contents_count,
				0 AS average_collaboration_share,
				0 AS accepted_count,
				0 AS average_accepted_score,
				0 AS published_count,
				COUNT(a.answer_id) AS answers_count,
				0 AS wiki_changes_count
			FROM cn_nodes AS groups
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id AND nm.node_id = groups.node_id AND
					nm.is_pending = FALSE
				INNER JOIN qa_answers AS a
				ON a.application_id = vr_application_id AND a.sender_user_id = nm.user_id
				INNER JOIN qa_questions AS q
				ON q.application_id = vr_application_id AND q.question_id = a.question_id
			WHERE groups.application_id = vr_application_id AND (
					(vr_creatorCount > 0 AND groups.node_id IN (SELECT * FROM vr_creatorNodeIDs)) OR
					(vr_creatorCount = 0 AND
						(vr_creatorNodeTypeID IS NULL OR groups.node_type_id = vr_creatorNodeTypeID)
					)
				) AND groups.deleted = FALSE AND a.deleted = FALSE AND 
				(vr_lower_creation_date_limit IS NULL OR a.send_date >= vr_lower_creation_date_limit) AND
				(vr_upper_creation_date_limit IS NULL OR a.send_date <= vr_upper_creation_date_limit) AND
				q.deleted = FALSE
			GROUP BY groups.node_id

			UNION ALL

			SELECT x.group_id, 
				0 AS contents_count,
				0 AS average_collaboration_share,
				0 AS accepted_count,
				0 AS average_accepted_score,
				0 AS published_count,
				0 AS answers_count,
				COUNT(x.paragraph_id) AS wiki_changes_count
			FROM (
					SELECT DISTINCT groups.node_id AS group_id, nm.user_id, p.paragraph_id
					FROM cn_nodes AS groups
						INNER JOIN cn_view_node_members AS nm
						ON nm.application_id = vr_application_id AND nm.node_id = groups.node_id AND
							nm.is_pending = FALSE
						INNER JOIN wk_changes AS c
						ON c.application_id = vr_application_id AND c.user_id = nm.user_id
						INNER JOIN wk_paragraphs AS p
						ON p.application_id = vr_application_id AND p.paragraph_id = c.paragraph_id
						INNER JOIN wk_titles AS t
						ON t.application_id = vr_application_id AND t.title_id = p.title_id
						INNER JOIN cn_nodes AS nd
						ON nd.application_id = vr_application_id AND nd.node_id = t.owner_id
					WHERE groups.application_id = vr_application_id AND (
							(vr_creatorCount > 0 AND groups.node_id IN (SELECT * FROM vr_creatorNodeIDs)) OR
							(vr_creatorCount = 0 AND
								(vr_creatorNodeTypeID IS NULL OR groups.node_type_id = vr_creatorNodeTypeID)
							)
						) AND groups.deleted = FALSE AND
						(vr_lower_creation_date_limit IS NULL OR c.send_date >= vr_lower_creation_date_limit) AND
						(vr_upper_creation_date_limit IS NULL OR c.send_date <= vr_upper_creation_date_limit) AND
						(c.status = N'Accepted' OR c.applied = 1) AND c.deleted = FALSE AND p.deleted = FALSE AND
						(p.status = N'Accepted' OR p.status = N'CitationNeeded') AND
						t.deleted = FALSE AND nd.deleted = FALSE AND (nd.searchable = TRUE OR nd.status = N'Accepted')
				) AS x
			GROUP BY x.group_id
		) AS r
		INNER JOIN cn_nodes AS n
		ON n.application_id = vr_application_id AND n.node_id = r.group_id
		INNER JOIN cn_view_node_members AS nm
		ON nm.application_id = vr_application_id AND nm.node_id = n.node_id AND nm.is_pending = FALSE
	GROUP BY r.group_id

	SELECT ('{' +
		'"GroupName": {"Action": "Link", "Type": "Node",' +
			'"Requires": {"ID": "GroupID_Hide"}' +
		'}' +
	   '}') AS actions
END;


DROP PROCEDURE IF EXISTS rv_knowledge_demand_indicators_report;

CREATE PROCEDURE rv_knowledge_demand_indicators_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_creatorNodeTypeID		UUID,
	vr_strNodeIDs				varchar(max),
	vr_delimiter				char,
	vr_lower_creation_date_limit TIMESTAMP,
	vr_upper_creation_date_limit TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_creatorNodeIDs GuidTableType

	INSERT INTO vr_creatorNodeIDs (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strNodeIDs, vr_delimiter) AS ref

	DECLARE vr_creatorCount INTEGER = (SELECT COUNT(*) FROM vr_creatorNodeIDs)

	SELECT	r.group_id AS group_id_hide,
			MAX(n.name) AS group_name,
			COUNT(DISTINCT nm.user_id) AS members_count,
			MAX(r.searches_count) AS searches_count,
			MAX(r.questions_count) AS questions_count,
			MAX(r.content_visits_count) AS content_visits_count,
			MAX(r.distinct_content_visits_count) AS distinct_content_visits_count,
			MAX(r.posts_count) AS posts_count,
			MAX(r.comments_count) AS comments_count
	FROM (
			SELECT	groups.node_id AS group_id,
					COUNT(l.log_id) AS searches_count,
					0 AS questions_count,
					0 AS content_visits_count,
					0 AS distinct_content_visits_count,
					0 AS posts_count,
					0 AS comments_count
			FROM cn_nodes AS groups
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id AND nm.node_id = groups.node_id AND
					nm.is_pending = FALSE
				INNER JOIN lg_logs AS l
				ON l.application_id = vr_application_id AND l.user_id = nm.user_id
			WHERE groups.application_id = vr_application_id AND l.action = N'Search' AND (
					(vr_creatorCount > 0 AND groups.node_id IN (SELECT * FROM vr_creatorNodeIDs)) OR
					(vr_creatorCount = 0 AND
						(vr_creatorNodeTypeID IS NULL OR groups.node_type_id = vr_creatorNodeTypeID)
					)
				) AND groups.deleted = FALSE AND
				(vr_lower_creation_date_limit IS NULL OR l.date >= vr_lower_creation_date_limit) AND
				(vr_upper_creation_date_limit IS NULL OR l.date <= vr_upper_creation_date_limit)
			GROUP BY groups.node_id

			UNION ALL

			SELECT	groups.node_id AS group_id,
					0 AS searches_count,
					COUNT(q.question_id) AS questions_count,
					0 AS content_visits_count,
					0 AS distinct_content_visits_count,
					0 AS posts_count,
					0 AS comments_count
			FROM cn_nodes AS groups
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id AND nm.node_id = groups.node_id AND
					nm.is_pending = FALSE
				INNER JOIN qa_questions AS q
				ON q.application_id = vr_application_id AND q.sender_user_id = nm.user_id
			WHERE groups.application_id = vr_application_id AND (
					(vr_creatorCount > 0 AND groups.node_id IN (SELECT * FROM vr_creatorNodeIDs)) OR
					(vr_creatorCount = 0 AND
						(vr_creatorNodeTypeID IS NULL OR groups.node_type_id = vr_creatorNodeTypeID)
					)
				) AND groups.deleted = FALSE AND q.deleted = FALSE AND
				(vr_lower_creation_date_limit IS NULL OR q.send_date >= vr_lower_creation_date_limit) AND
				(vr_upper_creation_date_limit IS NULL OR q.send_date <= vr_upper_creation_date_limit)
			GROUP BY groups.node_id

			UNION ALL

			SELECT	groups.node_id AS group_id,
					0 AS searches_count,
					0 AS questions_count,
					COUNT(iv.item_id) AS content_visits_count,
					0 AS distinct_content_visits_count,
					0 AS posts_count,
					0 AS comments_count
			FROM cn_nodes AS groups
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id AND nm.node_id = groups.node_id AND
					nm.is_pending = FALSE
				INNER JOIN usr_item_visits AS iv
				ON nm.application_id = vr_application_id AND iv.user_id = nm.user_id
			WHERE groups.application_id = vr_application_id AND
				(iv.item_type = N'Node' OR iv.item_type = N'Knowledge') AND (
					(vr_creatorCount > 0 AND groups.node_id IN (SELECT * FROM vr_creatorNodeIDs)) OR
					(vr_creatorCount = 0 AND
						(vr_creatorNodeTypeID IS NULL OR groups.node_type_id = vr_creatorNodeTypeID)
					)
				) AND groups.deleted = FALSE AND 
				(vr_lower_creation_date_limit IS NULL OR iv.visit_date >= vr_lower_creation_date_limit) AND
				(vr_upper_creation_date_limit IS NULL OR iv.visit_date <= vr_upper_creation_date_limit)
			GROUP BY groups.node_id
			
			UNION ALL
			
			SELECT	groups.node_id AS group_id,
					0 AS searches_count,
					0 AS questions_count,
					0 AS content_visits_count,
					COUNT(DISTINCT iv.item_id) AS distinct_content_visits_count,
					0 AS posts_count,
					0 AS comments_count
			FROM cn_nodes AS groups
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id AND nm.node_id = groups.node_id AND
					nm.is_pending = FALSE
				INNER JOIN usr_item_visits AS iv
				ON iv.application_id = vr_application_id AND iv.user_id = nm.user_id
			WHERE groups.application_id = vr_application_id AND 
				(iv.item_type = N'Node' OR iv.item_type = N'Knowledge') AND (
					(vr_creatorCount > 0 AND groups.node_id IN (SELECT * FROM vr_creatorNodeIDs)) OR
					(vr_creatorCount = 0 AND
						(vr_creatorNodeTypeID IS NULL OR groups.node_type_id = vr_creatorNodeTypeID)
					)
				) AND groups.deleted = FALSE AND 
				(vr_lower_creation_date_limit IS NULL OR iv.visit_date >= vr_lower_creation_date_limit) AND
				(vr_upper_creation_date_limit IS NULL OR iv.visit_date <= vr_upper_creation_date_limit)
			GROUP BY groups.node_id

			UNION ALL

			SELECT	groups.node_id AS group_id,
					0 AS searches_count,
					0 AS questions_count,
					0 AS content_visits_count,
					0 AS distinct_content_visits_count,
					COUNT(ps.share_id) AS posts_count,
					0 AS comments_count
			FROM cn_nodes AS groups
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id AND nm.node_id = groups.node_id AND
					nm.is_pending = FALSE
				INNER JOIN sh_post_shares AS ps
				ON ps.application_id = vr_application_id AND ps.sender_user_id = nm.user_id
			WHERE groups.application_id = vr_application_id AND 
				(ps.owner_type = N'Node' OR ps.owner_type = N'Knowledge') AND (
					(vr_creatorCount > 0 AND groups.node_id IN (SELECT * FROM vr_creatorNodeIDs)) OR
					(vr_creatorCount = 0 AND
						(vr_creatorNodeTypeID IS NULL OR groups.node_type_id = vr_creatorNodeTypeID)
					)
				) AND groups.deleted = FALSE AND ps.deleted = FALSE AND 
				(vr_lower_creation_date_limit IS NULL OR ps.send_date >= vr_lower_creation_date_limit) AND
				(vr_upper_creation_date_limit IS NULL OR ps.send_date <= vr_upper_creation_date_limit)
			GROUP BY groups.node_id

			UNION ALL

			SELECT	groups.node_id AS group_id,
					0 AS searches_count,
					0 AS questions_count,
					0 AS content_visits_count,
					0 AS distinct_content_visits_count,
					0 AS posts_count,
					COUNT(c.comment_id) AS comments_count
			FROM cn_nodes AS groups
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id AND nm.node_id = groups.node_id AND
					nm.is_pending = FALSE
				INNER JOIN sh_comments AS c
				ON c.application_id = vr_application_id AND c.sender_user_id = nm.user_id
				INNER JOIN sh_post_shares AS ps
				ON ps.application_id = vr_application_id AND ps.share_id = c.share_id
			WHERE groups.application_id = vr_application_id AND 
				(ps.owner_type = N'Node' OR ps.owner_type = N'Knowledge') AND (
					(vr_creatorCount > 0 AND groups.node_id IN (SELECT * FROM vr_creatorNodeIDs)) OR
					(vr_creatorCount = 0 AND
						(vr_creatorNodeTypeID IS NULL OR groups.node_type_id = vr_creatorNodeTypeID)
					)
				) AND groups.deleted = FALSE AND c.deleted = FALSE AND ps.deleted = FALSE AND 
				(vr_lower_creation_date_limit IS NULL OR ps.send_date >= vr_lower_creation_date_limit) AND
				(vr_upper_creation_date_limit IS NULL OR ps.send_date <= vr_upper_creation_date_limit)
			GROUP BY groups.node_id
		) AS r
		INNER JOIN cn_nodes AS n
		ON n.application_id = vr_application_id AND n.node_id = r.group_id
		INNER JOIN cn_view_node_members AS nm
		ON nm.application_id = vr_application_id AND nm.node_id = n.node_id AND nm.is_pending = FALSE
	GROUP BY r.group_id
	
	SELECT ('{' +
		'"GroupName": {"Action": "Link", "Type": "Node",' +
			'"Requires": {"ID": "GroupID_Hide"}' +
		'}' +
	   '}') AS actions
END;


DROP PROCEDURE IF EXISTS rv_social_contribution_indicators_report;

CREATE PROCEDURE rv_social_contribution_indicators_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_creatorNodeTypeID		UUID,
	vr_strNodeIDs				varchar(max),
	vr_delimiter				char,
	vr_lower_creation_date_limit TIMESTAMP,
	vr_upper_creation_date_limit TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_creatorNodeIDs GuidTableType

	INSERT INTO vr_creatorNodeIDs (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strNodeIDs, vr_delimiter) AS ref

	DECLARE vr_creatorCount INTEGER = (SELECT COUNT(*) FROM vr_creatorNodeIDs)

	SELECT	r.group_id AS group_id_hide,
			MAX(n.name) AS group_name,
			COUNT(DISTINCT nm.user_id) MembersCount,
			MAX(r.active_users_count) AS active_users_count,
			MAX(r.posts_count) AS posts_count,
			MAX(r.comments_count) AS comments_count
	FROM (
			SELECT	groups.node_id AS group_id,
					COUNT(DISTINCT un.user_id) AS active_users_count,
					0 AS posts_count,
					0 AS comments_count
			FROM cn_nodes AS groups
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id AND nm.node_id = groups.node_id AND
					nm.is_pending = FALSE
				INNER JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = nm.user_id
			WHERE groups.application_id = vr_application_id AND (
					(vr_creatorCount > 0 AND groups.node_id IN (SELECT * FROM vr_creatorNodeIDs)) OR
					(vr_creatorCount = 0 AND
						(vr_creatorNodeTypeID IS NULL OR groups.node_type_id = vr_creatorNodeTypeID)
					)
				) AND groups.deleted = FALSE AND un.is_approved = TRUE AND
				(vr_lower_creation_date_limit IS NULL OR un.last_activity_date >= vr_lower_creation_date_limit) AND
				(vr_upper_creation_date_limit IS NULL OR un.last_activity_date <= vr_upper_creation_date_limit)
			GROUP BY groups.node_id

			UNION ALL

			SELECT	groups.node_id AS group_id,
					0 AS active_users_count,
					COUNT(ps.share_id) AS posts_count,
					0 AS comments_count
			FROM cn_nodes AS groups
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id AND nm.node_id = groups.node_id AND
					nm.is_pending = FALSE
				INNER JOIN sh_post_shares AS ps
				ON ps.application_id = vr_application_id AND ps.sender_user_id = nm.user_id
			WHERE groups.application_id = vr_application_id AND (
					(vr_creatorCount > 0 AND groups.node_id IN (SELECT * FROM vr_creatorNodeIDs)) OR
					(vr_creatorCount = 0 AND
						(vr_creatorNodeTypeID IS NULL OR groups.node_type_id = vr_creatorNodeTypeID)
					)
				) AND groups.deleted = FALSE AND ps.deleted = FALSE AND 
				(vr_lower_creation_date_limit IS NULL OR ps.send_date >= vr_lower_creation_date_limit) AND
				(vr_upper_creation_date_limit IS NULL OR ps.send_date <= vr_upper_creation_date_limit)
			GROUP BY groups.node_id

			UNION ALL

			SELECT	groups.node_id AS group_id,
					0 AS active_users_count,
					0 AS posts_count,
					COUNT(c.comment_id) AS comments_count
			FROM cn_nodes AS groups
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id AND nm.node_id = groups.node_id AND
					nm.is_pending = FALSE
				INNER JOIN sh_comments AS c
				ON c.application_id = vr_application_id AND c.sender_user_id = nm.user_id
				INNER JOIN sh_post_shares AS ps
				ON ps.application_id = vr_application_id AND ps.share_id = c.share_id
			WHERE groups.application_id = vr_application_id AND (
					(vr_creatorCount > 0 AND groups.node_id IN (SELECT * FROM vr_creatorNodeIDs)) OR
					(vr_creatorCount = 0 AND
						(vr_creatorNodeTypeID IS NULL OR groups.node_type_id = vr_creatorNodeTypeID)
					)
				) AND groups.deleted = FALSE AND c.deleted = FALSE AND ps.deleted = FALSE AND 
				(vr_lower_creation_date_limit IS NULL OR ps.send_date >= vr_lower_creation_date_limit) AND
				(vr_upper_creation_date_limit IS NULL OR ps.send_date <= vr_upper_creation_date_limit)
			GROUP BY groups.node_id
		) AS r
		INNER JOIN cn_nodes AS n
		ON n.application_id = vr_application_id AND n.node_id = r.group_id
		INNER JOIN cn_view_node_members AS nm
		ON nm.application_id = vr_application_id AND nm.node_id = n.node_id AND nm.is_pending = FALSE
	GROUP BY r.group_id
	
	SELECT ('{' +
		'"GroupName": {"Action": "Link", "Type": "Node",' +
			'"Requires": {"ID": "GroupID_Hide"}' +
		'}' +
	   '}') AS actions
END;


DROP PROCEDURE IF EXISTS rv_applications_performance_report;

CREATE PROCEDURE rv_applications_performance_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_strTeamIDs varchar(max),
	vr_delimiter	char,
	vr_date_from TIMESTAMP,
	vr_dateMiddle TIMESTAMP,
	vr_date_to	 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_team_ids GuidTableType

	INSERT INTO vr_team_ids (value)
	SELECT ref.value 
	FROM gfn_str_to_guid_table(vr_strTeamIDs, vr_delimiter) AS ref

	DECLARE vr_teams_count INTEGER = (SELECT COUNT(*) FROM vr_team_ids)
	DECLARE vr_node_ids GuidTableType
	DECLARE vr_archive BOOLEAN = 0

	;WITH Applications
 AS 
	(
		SELECT	app.application_id AS application_id, 
				app.title,
				(
					SELECT COUNT(*)
					FROM usr_user_applications AS u
					WHERE u.application_id = app.application_id
				) AS members_count,
				(
					SELECT COUNT(*)
					FROM cn_node_types AS nt
						LEFT JOIN cn_services AS s
						ON s.application_id = app.application_id AND s.node_type_id = nt.node_type_id
					WHERE nt.application_id = app.application_id AND nt.deleted = FALSE AND COALESCE(s.service_title, N'') <> N''
				) AS templates_count
		FROM rv_applications AS app
		WHERE ((vr_teams_count = 0 AND COALESCE(app.deleted, FALSE) = 0) OR app.application_id IN (SELECT t.value FROM vr_team_ids AS t))
	),
	Nodes
 AS 
	(
		SELECT	app.application_id,
				nd.node_type_id,
				nd.node_id,
				nd.type_name AS node_type, 
				nd.node_name, 
				nd.node_additional_id AS additional_id, 
				nd.creation_date,
				(CASE 
					WHEN nd.creation_date >= vr_date_from AND nd.creation_date < DATEADD(DAY, 1, vr_dateMiddle) THEN 1 
					WHEN nd.creation_date >= DATEADD(DAY, 1, vr_dateMiddle) AND nd.creation_date < DATEADD(DAY, 1, vr_date_to) THEN 2
					ELSE 0
				END) AS period,
				COALESCE(email.email_address, usr.username) AS creator_username,
				LTRIM(RTRIM(COALESCE(usr.first_name, N'') + N' ' + COALESCE(usr.last_name, N''))) AS creator_full_name
		FROM Applications AS app
			INNER JOIN cn_view_nodes_normal AS nd
			ON nd.application_id = app.application_id AND 
				(vr_archive IS NULL OR nd.deleted = vr_archive)
			INNER JOIN usr_view_users AS usr
			ON usr.user_id = nd.creator_user_id
			LEFT JOIN usr_email_addresses AS email
			ON email.email_id = usr.main_email_id
	),
	Files
 AS 
	(
		SELECT	nd.application_id, 
				files.file_id,
				files.file_name,
				files.extension,
				files.size,
				files.owner_type,
				files.creation_date,
				files.creator_user_id,
				files.deleted AS file_archived,
				(CASE 
					WHEN files.creation_date >= vr_date_from AND files.creation_date < DATEADD(DAY, 1, vr_dateMiddle) THEN 1 
					WHEN files.creation_date >= DATEADD(DAY, 1, vr_dateMiddle) AND files.creation_date < DATEADD(DAY, 1, vr_date_to) THEN 2
					ELSE 0
				END) AS period
		FROM Nodes AS nd
			INNER JOIN dct_fn_list_deep_attachments(vr_team_ids, vr_node_ids, vr_archive) AS files
			ON files.application_id = nd.application_id AND files.node_id = nd.node_id
	),
	Visits
 AS 
	(
		SELECT x.application_id, x.period, COUNT(x.unique_id) AS visits_count, COUNT(DISTINCT x.node_id) AS visited_nodes_count
		FROM (
				SELECT	nd.application_id,
						v.unique_id,
						nd.node_id, 
						v.visit_date, 
						(CASE 
							WHEN v.visit_date >= vr_date_from AND v.visit_date < DATEADD(DAY, 1, vr_dateMiddle) THEN 1 
							WHEN v.visit_date >= DATEADD(DAY, 1, vr_dateMiddle) AND v.visit_date < DATEADD(DAY, 1, vr_date_to) THEN 2
							ELSE 0
						END) AS period
				FROM Nodes AS nd
					INNER JOIN usr_item_visits AS v
					ON v.application_id = nd.application_id AND v.item_id = nd.node_id
			) AS x
		GROUP BY x.application_id, x.period
	),
	Logs
 AS 
	(
		SELECT x.application_id, x.action, x.period, COUNT(x.log_id) AS count
		FROM (
				SELECT	app.application_id,
						lg.log_id, 
						lg.date, 
						lg.action,
						(CASE 
							WHEN lg.date >= vr_date_from AND lg.date < DATEADD(DAY, 1, vr_dateMiddle) THEN 1 
							WHEN lg.date >= DATEADD(DAY, 1, vr_dateMiddle) AND lg.date < DATEADD(DAY, 1, vr_date_to) THEN 2
							ELSE 0
						END) AS period
				FROM Applications AS app
					INNER JOIN lg_logs AS lg
					ON lg.application_id = app.application_id AND lg.action IN ('Login', 'Search')
			) AS x
		GROUP BY x.application_id, x.action, x.period
	),
	AggregatedNodes
 AS 
	(
		SELECT	app.application_id,
				COALESCE(COUNT(n.node_id), 0) AS created_nodes_count,
				COALESCE(COUNT(CASE WHEN n.period = 1 THEN n.node_id ELSE NULL END), 0) AS created_nodes_count_1,
				COALESCE(COUNT(CASE WHEN n.period = 2 THEN n.node_id ELSE NULL END), 0) AS created_nodes_count_2,
				COALESCE(COUNT(DISTINCT n.node_type_id), 0) AS used_templates_count,
				COALESCE(COUNT(DISTINCT CASE WHEN n.period = 1 THEN n.node_type_id ELSE NULL END), 0) AS used_templates_count_1,
				COALESCE(COUNT(DISTINCT CASE WHEN n.period = 2 THEN n.node_type_id ELSE NULL END), 0) AS used_templates_count_2
		FROM Applications AS app
			INNER JOIN Nodes AS n
			ON n.application_id = app.application_id
		GROUP BY app.application_id
	),
	AggregatedLogin
 AS 
	(
		SELECT	app.application_id,
				COALESCE(SUM(l.count), 0) AS login_count,
				COALESCE(SUM(CASE WHEN l.period = 1 THEN l.count ELSE 0 END), 0) AS login_count_1,
				COALESCE(SUM(CASE WHEN l.period = 2 THEN l.count ELSE 0 END), 0) AS login_count_2
		FROM Applications AS app
			INNER JOIN Logs AS l
			ON l.application_id = app.application_id AND l.action = N'Login'
		GROUP BY app.application_id
	),
	AggregatedSearch
 AS 
	(
		SELECT	app.application_id,
				COALESCE(SUM(l.count), 0) AS search_count,
				COALESCE(SUM(CASE WHEN l.period = 1 THEN l.count ELSE 0 END), 0) AS search_count_1,
				COALESCE(SUM(CASE WHEN l.period = 2 THEN l.count ELSE 0 END), 0) AS search_count_2
		FROM Applications AS app
			INNER JOIN Logs AS l
			ON l.application_id = app.application_id AND l.action = N'Search'
		GROUP BY app.application_id
	),
	AggregatedFiles
 AS 
	(
		SELECT	app.application_id,
				COALESCE(COUNT(f.file_id), 0) AS attachments,
				COALESCE(COUNT(CASE WHEN f.period = 1 THEN f.file_id ELSE NULL END), 0) AS attachments_1,
				COALESCE(COUNT(CASE WHEN f.period = 2 THEN f.file_id ELSE NULL END), 0) AS attachments_2,
				ROUND(CAST(SUM(COALESCE(f.size, 0)) AS float) / 1024 / 1024, 2) AS attachment_size_m_b,
				ROUND(CAST(SUM(COALESCE(CASE WHEN f.period = 1 THEN f.size ELSE 0 END, 0)) AS float) / 1024 / 1024, 2) AS attachment_size_m_b_1,
				ROUND(CAST(SUM(COALESCE(CASE WHEN f.period = 2 THEN f.size ELSE 0 END, 0)) AS float) / 1024 / 1024, 2) AS attachment_size_m_b_2
		FROM Applications AS app
			INNER JOIN Files AS f
			ON f.application_id = app.application_id
		GROUP BY app.application_id
	),
	Aggregated
 AS 
	(
		SELECT	app.title,
				app.members_count,
				app.templates_count AS total_templates_count,
				COALESCE(nd.created_nodes_count, 0) AS created_nodes_count,
				COALESCE(nd.created_nodes_count_1, 0) AS created_nodes_count_1,
				COALESCE(nd.created_nodes_count_2, 0) AS created_nodes_count_2,
				COALESCE(nd.used_templates_count, 0) AS used_templates_count,
				COALESCE(nd.used_templates_count_1, 0) AS used_templates_count_1,
				COALESCE(nd.used_templates_count_2, 0) AS used_templates_count_2,
				COALESCE(lg.login_count, 0) AS login_count,
				COALESCE(lg.login_count_1, 0) AS login_count_1,
				COALESCE(lg.login_count_2, 0) AS login_count_2,
				COALESCE(sh.search_count, 0) AS search_count,
				COALESCE(sh.search_count_1, 0) AS search_count_1,
				COALESCE(sh.search_count_2, 0) AS search_count_2,
				COALESCE(f.attachments, 0) AS attachments,
				COALESCE(f.attachments_1, 0) AS attachments_1,
				COALESCE(f.attachments_2, 0) AS attachments_2,
				COALESCE(f.attachment_size_m_b, 0) AS attachment_size_m_b,
				COALESCE(f.attachment_size_m_b_1, 0) AS attachment_size_m_b_1,
				COALESCE(f.attachment_size_m_b_2, 0) AS attachment_size_m_b_2
		FROM Applications AS app
			LEFT JOIN AggregatedNodes AS nd
			ON nd.application_id = app.application_id
			LEFT JOIN AggregatedLogin AS lg
			ON lg.application_id = app.application_id
			LEFT JOIN AggregatedSearch AS sh
			ON sh.application_id = app.application_id
			LEFT JOIN AggregatedFiles AS f
			ON f.application_id = app.application_id
	)
	SELECT	a.title AS team_name,
			a.members_count,
			a.total_t_emplates_count,
			a.created_nodes_count,
			a.created_nodes_count_1,
			a.created_nodes_count_2,
			CAST(ROUND((CASE 
				WHEN a.created_nodes_count_1 = 0 THEN 0 
				ELSE ((CAST(a.created_nodes_count_2 AS float) / CAST(a.created_nodes_count_1 AS float)) - 1) * 100
			END), 0) AS varchar(10)) + '%' AS created_nodes_change,
			a.used_templates_count,
			a.used_templates_count_1,
			a.used_templates_count_2,
			CAST(ROUND((CASE 
				WHEN a.used_templates_count_1 = 0 THEN 0 
				ELSE ((CAST(a.used_templates_count_2 AS float) / CAST(a.used_templates_count_1 AS float)) - 1) * 100
			END), 0) AS varchar(10)) + '%' AS used_templates_change,
			a.login_count,
			a.login_count_1,
			a.login_count_2,
			CAST(ROUND((CASE 
				WHEN a.login_count_1 = 0 THEN 0 
				ELSE ((CAST(a.login_count_2 AS float) / CAST(a.login_count_1 AS float)) - 1) * 100
			END), 0) AS varchar(10)) + '%' AS login_count_change,
			a.search_count,
			a.search_count_1,
			a.search_count_2,
			CAST(ROUND((CASE 
				WHEN a.search_count_1 = 0 THEN 0 
				ELSE ((CAST(a.search_count_2 AS float) / CAST(a.search_count_1 AS float)) - 1) * 100
			END), 0) AS varchar(10)) + '%' AS search_count_change,
			a.attachments,
			a.attachments_1,
			a.attachments_2,
			CAST(ROUND((CASE 
				WHEN a.attachments_1 = 0 THEN 0 
				ELSE ((CAST(a.attachments_2 AS float) / CAST(a.attachments_1 AS float)) - 1) * 100
			END), 0) AS varchar(10)) + '%' AS attachments_change,
			a.attachment_size_m_b,
			a.attachment_size_m_b_1,
			a.attachment_size_m_b_2,
			CAST(ROUND((CASE 
				WHEN a.attachment_size_m_b_1 = 0 THEN 0 
				ELSE ((CAST(a.attachment_size_m_b_2 AS float) / CAST(a.attachment_size_m_b_1 AS float)) - 1) * 100
			END), 0) AS varchar(10)) + '%' AS attachment_size_m_b_change
	FROM Aggregated AS a
END;

DROP PROCEDURE IF EXISTS fg_forms_list_report;

CREATE PROCEDURE fg_forms_list_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
    vr_form_id					UUID,
    vr_lower_creation_date_limit TIMESTAMP,
    vr_upper_creation_date_limit TIMESTAMP,
    vr_form_filtersTemp		FormFilterTableType readonly,
    vr_delimiter				char
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_form_filters FormFilterTableType
	INSERT INTO vr_form_filters SELECT * FROM vr_form_filtersTemp
	
	DECLARE vr_results Table (
		InstanceID_Hide UUID primary key clustered,
		CreationDate TIMESTAMP,
		CreatorUserID_Hide UUID,
		CreatorName VARCHAR(1000),
		CreatorUserName VARCHAR(1000)
	)
	
	INSERT INTO vr_results (
		InstanceID_Hide, 
		CreationDate, 
		CreatorUserID_Hide, 
		CreatorName, 
		CreatorUserName
	)
	SELECT	fi.instance_id, 
			fi.creation_date,
			fi.creator_user_id,
			LTRIM(RTRIM(COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N''))),
			un.username
	FROM fg_form_instances AS fi
		LEFT JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = fi.creator_user_id
	WHERE fi.application_id = vr_application_id AND fi.form_id = vr_form_id AND
		(vr_lower_creation_date_limit IS NULL OR fi.creation_date >= vr_lower_creation_date_limit) AND
		(vr_upper_creation_date_limit IS NULL OR fi.creation_date <= vr_upper_creation_date_limit) AND
		fi.deleted = FALSE
	
	DECLARE vr_instanceIDs GuidTableType
		
	INSERT INTO vr_instanceIDs
	SELECT ref.instance_id_hide
	FROM vr_results AS ref
	
	IF (SELECT COUNT(ref.element_id) FROM vr_form_filters AS ref) > 0 BEGIN
		DELETE I
		FROM vr_instanceIDs AS i
			LEFT JOIN fg_fn_filter_instances(
				vr_application_id, NULL, vr_instanceIDs, vr_form_filters, vr_delimiter, 1
			) AS ref
			ON ref.instance_id = i.value
		WHERE ref.instance_id IS NULL
	END
	
	SELECT r.*
	FROM vr_instanceIDs AS i
		INNER JOIN vr_results AS r
		ON r.instance_id_hide = i.value
	ORDER BY r.creation_date DESC
	
	SELECT ('{' +
			'"CreatorName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "CreatorUserID_Hide"}' +
			'}' +
		   '}') AS actions

	
	-- Second Part: Describes the Third Part
	SELECT CAST(efe.element_id AS varchar(50)) AS column_name, efe.title AS translation,
		CASE
			WHEN efe.type = N'Binary' THEN N'bool'
			WHEN efe.type = N'Number' THEN N'double'
			WHEN efe.type = N'Date' THEN N'datetime'
			WHEN efe.type = N'User' THEN N'user'
			WHEN efe.type = N'Node' THEN N'node'
			ELSE N'string'
		END AS type
	FROM fg_extended_form_elements AS efe
	WHERE efe.application_id = vr_application_id AND 
		efe.form_id = vr_form_id AND efe.deleted = FALSE
	ORDER BY efe.sequence_number ASC
	
	SELECT ('{"IsDescription": "true"}') AS info
	-- end of Second Part
	
	-- Third Part: The Form Info
	DECLARE vr_element_ids GuidTableType
	DECLARE vr_fake_owner_ids GuidTableType, vr_fake_filters FormFilterTableType
	
	EXEC fg_p_get_form_records vr_application_id, vr_form_id, vr_element_ids, 
		vr_instanceIDs, vr_fake_owner_ids, vr_fake_filters, NULL, 1000000, NULL, NULL
	
	SELECT ('{' +
		'"ColumnsMap": "InstanceID_Hide:InstanceID",' +
		'"ColumnsToTransfer": "' + STUFF((
			SELECT ',' + CAST(efe.element_id AS varchar(50))
			FROM fg_extended_form_elements AS efe
			WHERE efe.application_id = vr_application_id AND 
				efe.form_id = vr_form_id AND efe.deleted = FALSE
			ORDER BY efe.sequence_number ASC
			FOR xml path('a'), type
		).value('.','nvarchar(max)'), 1, 1, '') + '"' +
	   '}') AS info
	-- End of Third Part
END;


DROP PROCEDURE IF EXISTS fg_poll_detail_report;

CREATE PROCEDURE fg_poll_detail_report
	vr_application_id	UUID,
	vr_current_user_id	UUID,
    vr_poll_id			UUID,
    vr_nodeTypeID		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT	a.title, 
			a.user_id AS user_id_hide,
			LTRIM(RTRIM(COALESCE(a.first_name, N'') + N' ' + COALESCE(a.last_name, N''))) AS full_name, 
			a.username, 
			a.membership_node_id AS node_id_hide,
			nd.name AS node_name,
			a.value,
			a.number_value
	FROM (
			SELECT	MAX(x.seq) AS seq,
					x.user_id,
					MAX(un.first_name) AS first_name, 
					MAX(un.last_name) AS last_name, 
					MAX(un.username) AS username,
					MAX(x.title) AS title,
					MAX(x.value) AS value,
					MAX(x.float_value) AS number_value,
					CAST(MAX(CAST(nm.node_id AS varchar(50))) AS uuid) AS membership_node_id
			FROM (
					SELECT	i.creator_user_id AS user_id, 
							fe.element_id AS element_id,
							fe.title,
							fe.sequence_number AS seq,
							fg_fn_to_string(vr_application_id, e.element_id, e.type, 
								e.text_value, e.float_value, e.bit_value, e.date_value) AS value,
							e.float_value
					FROM fg_form_instances AS i
						INNER JOIN fg_instance_elements AS e
						ON e.application_id = vr_application_id AND e.instance_id = i.instance_id AND e.deleted = FALSE
						INNER JOIN fg_extended_form_elements AS fe
						ON fe.application_id = vr_application_id AND fe.element_id = e.ref_element_id AND fe.deleted = FALSE
					WHERE i.application_id = vr_application_id AND i.owner_id = vr_poll_id AND i.deleted = FALSE
				) AS x
				INNER JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = x.user_id
				LEFT JOIN cn_view_node_members AS nm
				ON vr_nodeTypeID IS NOT NULL AND nm.application_id = vr_application_id AND
					nm.node_type_id = vr_nodeTypeID AND nm.user_id = un.user_id AND nm.is_pending = FALSE
			WHERE COALESCE(x.value, N'') <> N''
			GROUP BY x.element_id, x.user_id
		) AS a
		LEFT JOIN cn_nodes AS nd
		ON vr_nodeTypeID IS NOT NULL AND nd.application_id = vr_application_id AND nd.node_id = a.membership_node_id
	ORDER BY a.first_name ASC, a.last_name ASC, a.seq ASC
	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'},' +
			'"NodeName": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'}' +
		   '}') AS actions
END;

DROP PROCEDURE IF EXISTS cn_nodes_list_report;

CREATE PROCEDURE cn_nodes_list_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
    vr_nodeTypeID				UUID,
    vr_searchText			 VARCHAR(1000),
    vr_status					varchar(100),
    vr_min_contributors_count INTEGER,
    vr_lower_creation_date_limit TIMESTAMP,
    vr_upper_creation_date_limit TIMESTAMP,
    vr_form_filtersTemp		FormFilterTableType readonly,
    vr_delimiter				char
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_form_filters FormFilterTableType
	INSERT INTO vr_form_filters SELECT * FROM vr_form_filtersTemp
	
	SET vr_searchText = gfn_get_search_text(vr_searchText)
	
	DECLARE vr_results Table (
		NodeID_Hide UUID primary key clustered,
		Name VARCHAR(1000),
		AdditionalID varchar(1000),
		NodeType VARCHAR(1000),
		Classification VARCHAR(250),
		Description_HTML VARCHAR(max),
		CreationDate TIMESTAMP,
		PublicationDate TIMESTAMP,
		CreatorUserID_Hide UUID,
		CreatorName VARCHAR(1000),
		CreatorUserName VARCHAR(1000),
		OwnerID_Hide UUID,
		OwnerName VARCHAR(1000),
		OwnerType VARCHAR(1000),
		Score float,
		Status_Dic VARCHAR(100),
		WFState VARCHAR(1000),
		UsersCount INTEGER,
		Collaboration float,
		MaxCollaboration float,
		UploadSize float
	)
	
	IF vr_searchText IS NULL BEGIN
		INSERT INTO vr_results
		SELECT	nd.node_id AS node_id_hide,
				nd.node_name AS name,
				nd.node_additional_id AS additional_id,
				nd.type_name AS node_type,
				conf.level AS classification,
				nd.description AS description_h_t_m_l,
				nd.creation_date,
				nd.publication_date,
				nd.creator_user_id AS creator_user_id_hide,
				(COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N'')) AS creator_name,
				un.username AS creator_username,
				nd.owner_id AS owner_id_hide,
				ow.node_name AS owner_name,
				ow.type_name AS owner_type,
				nd.score,
				nd.status,
				nd.wf_state,
				ref.users_count,
				ref.collaboration,
				ref.max_collaboration,
				ref.upload_size
		FROM (
				SELECT	nd.node_id, 
						COALESCE(COUNT(nc.user_id), 0) AS users_count, 
						CASE
							WHEN COALESCE(COUNT(nc.user_id), 1) = 0 THEN 0
							ELSE COALESCE(SUM(nc.collaboration_share), 0) / COALESCE(COUNT(nc.user_id), 1)
						END AS collaboration,
						COALESCE(MAX(nc.collaboration_share), 0) AS max_collaboration,
						SUM(COALESCE(f.size, 0)) / (1024.0 * 1024.0) AS upload_size
				FROM cn_nodes AS nd
					LEFT JOIN cn_node_creators AS nc
					ON nc.application_id = vr_application_id AND 
						nc.node_id = nd.node_id AND nc.deleted = FALSE
					LEFT JOIN dct_files AS f
					ON f.application_id = vr_application_id AND f.owner_id = nd.node_id AND 
						(f.owner_type = N'Node') AND f.deleted = FALSE
				WHERE nd.application_id = vr_application_id AND 
					(vr_nodeTypeID IS NULL OR nd.node_type_id = vr_nodeTypeID) AND 
					(vr_status IS NULL OR nd.status = vr_status) AND nd.deleted = FALSE AND
					(vr_lower_creation_date_limit IS NULL OR nd.creation_date >= vr_lower_creation_date_limit) AND
					(vr_upper_creation_date_limit IS NULL OR nd.creation_date <= vr_upper_creation_date_limit)
				GROUP BY nd.node_id
			) AS ref
			INNER JOIN cn_view_nodes_normal AS nd
			ON nd.application_id = vr_application_id AND nd.node_id = ref.node_id
			LEFT JOIN users_normal AS un
			ON un.application_id = vr_application_id AND un.user_id = nd.creator_user_id
			LEFT JOIN cn_view_nodes_normal AS ow
			ON ow.application_id = vr_application_id AND ow.node_id = nd.owner_id
			LEFT JOIN prvc_view_confidentialities AS conf
			ON conf.application_id = vr_application_id AND conf.object_id = nd.node_id
		WHERE (vr_min_contributors_count IS NULL OR ref.users_count >= vr_min_contributors_count)
	END
	ELSE BEGIN
		INSERT INTO vr_results
		SELECT	nd.node_id AS node_id_hide,
				nd.node_name AS name,
				nd.node_additional_id AS additional_id,
				nd.type_name AS node_type,
				conf.level AS classification,
				nd.description AS description_h_t_m_l,
				nd.creation_date,
				nd.publication_date,
				nd.creator_user_id AS creator_user_id_hide,
				(COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N'')) AS creator_name,
				un.username AS creator_username,
				nd.owner_id AS owner_id_hide,
				ow.node_name AS owner_name,
				ow.type_name AS owner_type,
				nd.score,
				nd.status,
				nd.wf_state,
				ref.users_count,
				ref.collaboration,
				ref.max_collaboration,
				ref.upload_size
		FROM (
				SELECT	nd.node_id, 
						COALESCE(COUNT(nc.user_id), 0) AS users_count, 
						CASE
							WHEN COALESCE(COUNT(nc.user_id), 1) = 0 THEN 0
							ELSE COALESCE(SUM(nc.collaboration_share), 0) / COALESCE(COUNT(nc.user_id), 1)
						END AS collaboration,
						COALESCE(MAX(nc.collaboration_share), 0) AS max_collaboration,
						SUM(COALESCE(f.size, 0)) / (1024.0 * 1024.0) AS upload_size
				FROM CONTAINSTABLE(cn_nodes, (name), vr_searchText) AS srch
					INNER JOIN cn_nodes AS nd
					ON nd.application_id = vr_application_id AND nd.node_id = srch.key
					LEFT JOIN cn_node_creators AS nc
					ON nc.application_id = vr_application_id AND 
						nc.node_id = nd.node_id AND nc.deleted = FALSE
					LEFT JOIN dct_files AS f
					ON f.application_id = vr_application_id AND f.owner_id = nd.node_id AND 
						(f.owner_type = N'Node') AND f.deleted = FALSE
				WHERE (vr_nodeTypeID IS NULL OR nd.node_type_id = vr_nodeTypeID) AND 
					(vr_status IS NULL OR nd.status = vr_status) AND nd.deleted = FALSE AND
					(vr_lower_creation_date_limit IS NULL OR nd.creation_date >= vr_lower_creation_date_limit) AND
					(vr_upper_creation_date_limit IS NULL OR nd.creation_date <= vr_upper_creation_date_limit)
				GROUP BY nd.node_id
			) AS ref
			INNER JOIN cn_view_nodes_normal AS nd
			ON nd.application_id = vr_application_id AND nd.node_id = ref.node_id
			LEFT JOIN users_normal AS un
			ON un.application_id = vr_application_id AND un.user_id = nd.creator_user_id
			LEFT JOIN cn_view_nodes_normal AS ow
			ON ow.application_id = vr_application_id AND ow.node_id = nd.owner_id
			LEFT JOIN prvc_view_confidentialities AS conf
			ON conf.application_id = vr_application_id AND conf.object_id = nd.node_id
		WHERE (vr_min_contributors_count IS NULL OR ref.users_count >= vr_min_contributors_count)
	END
	
	DECLARE vr_node_ids GuidTableType
	
	INSERT INTO vr_node_ids
	SELECT ref.node_id_hide
	FROM vr_results AS ref
	
	DECLARE vr_instanceIDs GuidTableType
	
	DECLARE vr_form_id UUID = NULL
	
	IF vr_nodeTypeID IS NOT NULL BEGIN
		SET vr_form_id = (
			SELECT TOP(1) FormID
			FROM fg_form_owners
			WHERE ApplicationID = vr_application_id AND OwnerID = vr_nodeTypeID AND deleted = FALSE
		)
	END
	
	IF vr_form_id IS NOT NULL AND (SELECT COUNT(ref.element_id) FROM vr_form_filters AS ref) > 0 BEGIN
		DECLARE vr_form_instance_owners Table (InstanceID UUID, OwnerID UUID)
	
		INSERT INTO vr_form_instance_owners (InstanceID, OwnerID)
		SELECT fi.instance_id, fi.owner_id
		FROM vr_node_ids AS ref 
			INNER JOIN fg_form_instances AS fi
			ON fi.application_id = vr_application_id AND fi.owner_id = ref.value AND fi.deleted = FALSE
		
		INSERT INTO vr_instanceIDs (Value)
		SELECT DISTINCT ref.instance_id
		FROM vr_form_instance_owners AS ref
		
		DELETE N
		FROM vr_node_ids AS n
			LEFT JOIN vr_form_instance_owners AS o
			ON o.owner_id = n.value
			LEFT JOIN fg_fn_filter_instances(
				vr_application_id, NULL, vr_instanceIDs, vr_form_filters, vr_delimiter, 1
			) AS ref
			ON ref.instance_id = o.instance_id
		WHERE ref.instance_id IS NULL
		
		DELETE I
		FROM vr_instanceIDs AS i
			LEFT JOIN vr_form_instance_owners AS o
			LEFT JOIN vr_node_ids AS n
			ON n.value = o.owner_id
			ON o.instance_id = i.value
		WHERE o.instance_id IS NULL OR n.value IS NULL
	END
	
	SELECT r.*
	FROM vr_node_ids AS n
		INNER JOIN vr_results AS r
		ON r.node_id_hide = n.value
	
	SELECT ('{' +
			'"Name": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'},' +
			'"CreatorName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "CreatorUserID_Hide"}' +
			'},' +
			'"OwnerName": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "OwnerID_Hide"}' +
			'},' +
			'"Contributor": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "ContributorID_Hide"}' +
			'},' +
			'"UsersCount": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "CN", "ReportName": "CreatorUsersReport",' +
		   		'"Requires": {"NodeID": {"Value": "NodeID_Hide", "Title": "Name"}}, ' + 
		   		'"Params": {}' + 
		   	'}' +
		   '}') AS actions

	IF vr_form_id IS NOT NULL AND EXISTS(
		SELECT TOP(1) *
		FROM cn_extensions AS ex
		WHERE ex.application_id = vr_application_id AND 
			ex.owner_id = vr_nodeTypeID AND ex.extension = N'Form' AND ex.deleted = FALSE
	) BEGIN
		-- Second Part: Describes the Third Part
		SELECT CAST(efe.element_id AS varchar(50)) AS column_name, efe.title AS translation,
			CASE
				WHEN efe.type = N'Binary' THEN N'bool'
				WHEN efe.type = N'Number' THEN N'double'
				WHEN efe.type = N'Date' THEN N'datetime'
				WHEN efe.type = N'User' THEN N'user'
				WHEN efe.type = N'Node' THEN N'node'
				ELSE N'string'
			END AS type
		FROM fg_extended_form_elements AS efe
		WHERE efe.application_id = vr_application_id AND 
			efe.form_id = vr_form_id AND efe.deleted = FALSE
		ORDER BY efe.sequence_number ASC
		
		SELECT ('{"IsDescription": "true"}') AS info
		-- end of Second Part
		
		-- Third Part: The Form Info
		DECLARE vr_element_ids GuidTableType
		DECLARE vr_fake_owner_ids GuidTableType, vr_fake_filters FormFilterTableType
		
		EXEC fg_p_get_form_records vr_application_id, vr_form_id, vr_element_ids, 
			vr_instanceIDs, vr_fake_owner_ids, vr_fake_filters, NULL, 1000000, NULL, NULL
		
		SELECT ('{' +
			'"ColumnsMap": "NodeID_Hide:OwnerID",' +
			'"ColumnsToTransfer": "' + STUFF((
				SELECT ',' + CAST(efe.element_id AS varchar(50))
				FROM fg_extended_form_elements AS efe
				WHERE efe.application_id = vr_application_id AND 
					efe.form_id = vr_form_id AND efe.deleted = FALSE
				ORDER BY efe.sequence_number ASC
				FOR xml path('a'), type
			).value('.','nvarchar(max)'), 1, 1, '') + '"' +
		   '}') AS info
		-- End of Third Part
	END
	
	
	-- Add Contributor Columns
	
	DECLARE vr_proc VARCHAR(max) = N''
	
	SELECT x.*
	INTO #Result
	FROM (
			SELECT	c.node_id, 
					CAST(c.user_id AS varchar(50)) AS unq,
					c.user_id, 
					c.collaboration_share AS share,
					ROW_NUMBER() OVER (PARTITION BY c.node_id ORDER BY c.collaboration_share DESC, c.user_id DESC) AS row_number
			FROM vr_node_ids AS i_ds
				INNER JOIN cn_node_creators AS c
				ON c.application_id = vr_application_id AND c.node_id = i_ds.value AND c.deleted = FALSE
		) AS x
		
	DECLARE vr_count INTEGER = (SELECT MAX(RowNumber) FROM #Result)
	DECLARE vr_itemsList varchar(max) = N'', vr_selectList varchar(max) = N'', vr_cols_to_transfer varchar(max) = N''
	
	SET vr_proc = N''

	DECLARE vr_ind INTEGER = vr_count - 1
	WHILE vr_ind >= 0 BEGIN
		DECLARE vr_tmp varchar(10) = CAST((vr_count - vr_ind) AS varchar(10))
		
		SET vr_selectList = vr_selectList + '[' + vr_tmp + '] AS contributor_id_hide_' + vr_tmp + '], ' + 
			'CAST(NULL AS varchar(500)) AS contributor_' + vr_tmp + '], ' +
			'CAST(NULL AS float) AS contributor_share_' + vr_tmp + ']'
			
		SET vr_itemsList = vr_itemsList + '[' + vr_tmp + ']'
		
		SET vr_proc = vr_proc + 
			'SELECT ''ContributorID_Hide_' + vr_tmp + ''' AS column_name, null AS translation, ''string'' AS type ' +
			'UNION ALL ' +
			'SELECT ''Contributor_' + vr_tmp + ''' AS column_name, null AS translation, ''string'' AS type ' +
			'UNION ALL ' +
			'SELECT ''ContributorShare_' + vr_tmp + ''' AS column_name, null AS translation, ''double'' AS type '
			
		SET vr_cols_to_transfer = vr_cols_to_transfer + 
			'ContributorID_Hide_' + vr_tmp + ',Contributor_' + vr_tmp + ',ContributorShare_' + vr_tmp
		
		IF vr_ind > 0 BEGIN 
			SET vr_selectList = vr_selectList + ', '
			SET vr_itemsList = vr_itemsList + ', '
			SET vr_proc = vr_proc + N'UNION ALL '
			SET vr_cols_to_transfer = vr_cols_to_transfer + ','
		END
		
		SET vr_ind = vr_ind - 1
	END
	
	-- Second Part: Describes the Third Part
	EXEC (vr_proc)
	
	SELECT ('{"IsDescription": "true"}') AS info
	-- end of Second Part

	-- Third Part: The Data
	SET vr_proc = 
		'SELECT NodeID AS node_id_hide, ' + vr_selectList + 
		'INTO #Final ' +
		'FROM ( ' +
				'SELECT NodeID, unq, RowNumber ' +
				'FROM #Result ' +
			') AS p ' +
			'PIVOT (MAX(unq) FOR RowNumber IN (' + vr_itemsList + ')) AS pvt '

	SET vr_ind = vr_count - 1
	WHILE vr_ind >= 0 BEGIN
		DECLARE vr_no varchar(10) = CAST((vr_count - vr_ind) AS varchar(10))
		
		SET vr_proc = vr_proc + 
			'UPDATE F ' + 
				'SET Contributor_' + vr_no + ' = LTRIM(RTRIM(COALESCE(un.first_name, N'''') + N'' '' + COALESCE(un.last_name, N''''))) ' + 
			'FROM #Final AS f ' + 
				'INNER JOIN users_normal AS un ' + 
				'ON un.application_id = ''' + CAST(vr_application_id AS varchar(50)) + ''' AND un.user_id = f.contributor_id_hide_' + vr_no + ' '
				
		SET vr_proc = vr_proc + 
			'UPDATE F ' + 
				'SET ContributorShare_' + vr_no + ' = r.share ' + 
			'FROM #Final AS f ' + 
				'INNER JOIN #Result AS r ' + 
				'ON r.node_id = f.node_id_hide AND r.user_id = f.contributor_id_hide_' + vr_no + ' '
		
		SET vr_ind = vr_ind - 1
	END

	SET vr_proc = vr_proc + 'SELECT * FROM #Final'

	EXEC (vr_proc)
	
	SELECT ('{' +
			'"ColumnsMap": "NodeID_Hide:NodeID_Hide",' +
			'"ColumnsToTransfer": "' + vr_cols_to_transfer + '"' +
		   '}') AS info
	-- end of Third Part
	
	-- end of Add Contributor Columns
END;


DROP PROCEDURE IF EXISTS cn_most_favorite_nodes_report;

CREATE PROCEDURE cn_most_favorite_nodes_report
	vr_application_id	UUID,
	vr_current_user_id	UUID,
	vr_count		 INTEGER,
	vr_nodeTypeID		UUID,
	vr_beginDate	 TIMESTAMP,
	vr_finish_date	 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_count IS NULL SET vr_count = 20
	
	SELECT TOP(vr_count) 
		nd.node_id AS node_id_hide, 
		nd.node_name, 
		nd.type_name, 
		conf.level AS classification,
		ref.cnt AS count
	FROM (
			SELECT nl.node_id, COUNT(nl.user_id) AS cnt
			FROM cn_node_likes AS nl
			WHERE nl.application_id = vr_application_id AND 
				(vr_beginDate IS NULL OR nl.like_date >= vr_beginDate) AND
				(vr_finish_date IS NULL OR nl.like_date <= vr_finish_date) AND
				nl.deleted = FALSE
			GROUP BY nl.node_id
		) AS ref
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = ref.node_id
		LEFT JOIN prvc_view_confidentialities AS conf
		ON conf.application_id = vr_application_id AND conf.object_id = nd.node_id
	WHERE (vr_nodeTypeID IS NULL OR nd.node_type_id = vr_nodeTypeID) AND nd.deleted = FALSE
	ORDER BY ref.cnt DESC
	
	SELECT ('{' +
			'"NodeName": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS cn_creator_users_report;

CREATE PROCEDURE cn_creator_users_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_node_id					UUID,
	vr_membershipNodeTypeID	UUID,
	vr_membershipNodeID		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT nc.user_id AS user_id_hide,
		(un.first_name + N' ' + un.last_name) AS name, un.username AS username,
		nc.collaboration_share AS collaboration
	FROM cn_node_creators AS nc
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = nc.user_id
	WHERE nc.application_id = vr_application_id AND nc.node_id = vr_node_id AND nc.deleted = FALSE AND
		((vr_membershipNodeID IS NULL AND vr_membershipNodeTypeID IS NULL) OR EXISTS(
			SELECT TOP(1) *
			FROM cn_view_node_members AS nm
				INNER JOIN cn_nodes AS nd
				ON nd.application_id = vr_application_id AND nd.node_id = nm.node_id
			WHERE nm.application_id = vr_application_id AND 
				(
					(vr_membershipNodeID IS NULL AND nd.node_type_id = vr_membershipNodeTypeID) OR
					(vr_membershipNodeID IS NOT NULL AND nd.node_id = vr_membershipNodeID)
				) AND nm.user_id = un.user_id AND nm.is_pending = FALSE AND nd.deleted = FALSE
		))

	
	SELECT ('{' +
			'"Name": {"Action": "Link", "Type": "User",' +
				'"Requires": {"ID": "UserID_Hide"}' +
			'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS cn_node_creators_report;

CREATE PROCEDURE cn_node_creators_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_nodeTypeID				UUID,
	vr_strUserIDs				varchar(max),
	vr_strNodeIDs				varchar(max),
	vr_delimiter				char,
	vr_showPersonalItems	 BOOLEAN,
	vr_lower_creation_date_limit TIMESTAMP,
	vr_upper_creation_date_limit TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType
	
	INSERT INTO vr_user_ids
	SELECT ref.value FROM gfn_str_to_guid_table(vr_strUserIDs, vr_delimiter) AS ref
	
	DECLARE vr_node_ids GuidTableType, vr_nodeUserIDs GuidTableType
	
	INSERT INTO vr_node_ids
	SELECT ref.value FROM gfn_str_to_guid_table(vr_strNodeIDs, vr_delimiter) AS ref
	
	INSERT INTO vr_nodeUserIDs
	EXEC cn_p_get_member_user_ids vr_application_id, vr_node_ids, N'Accepted', NULL
	
	INSERT INTO vr_user_ids
	SELECT ref.value
	FROM vr_nodeUserIDs AS ref
	WHERE ref.value NOT IN (SELECT u.value FROM vr_user_ids AS u)
	
	IF((SELECT COUNT(*) FROM vr_user_ids) = 0) BEGIN
		INSERT INTO vr_user_ids
		SELECT UserID
		FROM users_normal
		WHERE ApplicationID = vr_application_id AND is_approved = TRUE
	END

	DECLARE vr_dep_type_ids GuidTableType
	INSERT INTO vr_dep_type_ids (Value)
	SELECT ref.node_type_id
	FROM cn_fn_get_department_node_type_ids(vr_application_id) AS ref

	SELECT un.user_id AS user_id_hide, 
		CAST(MAX(CAST(nd.node_id AS varchar(36))) AS uuid) AS department_id_hide,
		(MAX(un.first_name) + N' ' + MAX(un.last_name)) AS name, 
		MAX(un.username) AS username,  
		MAX(nd.name) AS department, 
		MAX(ref.count) AS count, 
		MAX(ref.personal) AS personal_count, 
		MAX(ref.group) AS group_count, 
		MAX(ref.collaboration) AS collaboration,
		MAX(ref.upload_size) AS upload_size
	FROM
		(
			SELECT nc.user_id, 
				COUNT(nc.node_id) AS count,
				SUM(
					CASE
						WHEN nc.collaboration_share = 100 THEN 1
						ELSE 0
					END
				) AS personal,
				SUM(
					CASE
						WHEN nc.collaboration_share = 100 THEN 0
						ELSE 1
					END
				) AS group,
				CASE
					WHEN COALESCE(COUNT(nc.user_id), 1) = 0 THEN 0
					ELSE COALESCE(SUM(nc.collaboration_share), 0) / COALESCE(COUNT(nc.user_id), 1)
				END AS collaboration,
				SUM(COALESCE(f.size, 0)) / (1024.0 * 1024.0) AS upload_size
			FROM vr_user_ids AS uds
				INNER JOIN cn_node_creators AS nc
				ON nc.application_id = vr_application_id AND nc.user_id = uds.value
				INNER JOIN cn_nodes AS nd
				ON nd.application_id = vr_application_id AND nd.node_id = nc.node_id
				LEFT JOIN dct_files AS f
				ON f.application_id = vr_application_id AND f.owner_id = nd.node_id AND 
					(f.owner_type = N'Node') AND f.deleted = FALSE
			WHERE nc.deleted = FALSE AND nd.deleted = FALSE AND
				(vr_nodeTypeID IS NULL OR nd.node_type_id = vr_nodeTypeID) AND
				(vr_showPersonalItems IS NULL OR
					(vr_showPersonalItems = 1 AND nc.collaboration_share = 100) OR
					(vr_showPersonalItems = 0 AND nc.collaboration_share < 100)
				) AND
				(vr_lower_creation_date_limit IS NULL OR nd.creation_date >= vr_lower_creation_date_limit) AND
				(vr_upper_creation_date_limit IS NULL OR nd.creation_date <= vr_upper_creation_date_limit)
			GROUP BY nc.user_id
		) AS ref
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND ref.user_id = un.user_id
		LEFT JOIN cn_node_members AS nm
		LEFT JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND 
			nd.node_type_id IN (SELECT Value FROM vr_dep_type_ids) AND nd.deleted = FALSE
		ON nm.application_id = vr_application_id AND 
			nm.node_id = nd.node_id AND  nm.user_id = un.user_id AND nm.deleted = FALSE
	GROUP BY un.user_id
	ORDER BY MAX(ref.count) DESC
	
	SELECT ('{' +
			'"Name": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'},' +
			'"Department": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "DepartmentID_Hide"}' +
			'},' +
		    '"Count": {"Action": "Report", 
		   		"ModuleIdentifier": "CN", "ReportName": "UserCreatedNodesReport",' +
		   		'"Requires": {"UserID": {"Value": "UserID_Hide", ' + 
		   			'"Title": "~[name] (~[username])"}}, ' + 
		   		'"Params": {"ShowPersonalItems": null}' + 
		   	'},' +
		    '"PersonalCount": {"Action": "Report", 
		   		"ModuleIdentifier": "CN", "ReportName": "UserCreatedNodesReport",' +
		   		'"Requires": {"UserID": {"Value": "UserID_Hide", ' + 
		   			'"Title": "~[name] (~[username])"}}, ' + 
		   		'"Params": {"ShowPersonalItems": true}' + 
		   	'},' +
		   	'"GroupCount": {"Action": "Report", 
		   		"ModuleIdentifier": "CN", "ReportName": "UserCreatedNodesReport",' +
		   		'"Requires": {"UserID": {"Value": "UserID_Hide", ' + 
		   			'"Title": "~[name] (~[username])"}}, ' + 
		   		'"Params": {"ShowPersonalItems": false}' + 
		   	'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS cn_user_created_nodes_report;

CREATE PROCEDURE cn_user_created_nodes_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_nodeTypeID				UUID,
	vr_user_id					UUID,
	vr_showPersonalItems	 BOOLEAN,
	vr_lower_creation_date_limit TIMESTAMP,
	vr_upper_creation_date_limit TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType

	SELECT	nc.node_id AS node_id_hide, 
			nd.name AS node_name, 
			nd.additional_id AS additional_id,
			conf.level AS classification,
			nc.collaboration_share, nd.creation_date AS creation_date,
			COALESCE((
				SELECT SUM(COALESCE(f.size, 0))
				FROM dct_files AS f
				WHERE f.application_id = vr_application_id AND f.owner_id = nc.node_id AND 
					(f.owner_type = N'Node') AND f.deleted = FALSE
			), 0) / (1024.0 * 1024.0) AS upload_size
	FROM cn_node_creators AS nc
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = nc.node_id
		LEFT JOIN prvc_view_confidentialities AS conf
		ON conf.application_id = vr_application_id AND conf.object_id = nd.node_id
	WHERE nc.application_id = vr_application_id AND 
		nc.user_id = vr_user_id AND nc.deleted = FALSE AND 
		(vr_nodeTypeID IS NULL OR nd.node_type_id = vr_nodeTypeID) AND 
		nd.deleted = FALSE AND
		(vr_showPersonalItems IS NULL OR
			(vr_showPersonalItems = 1 AND nc.collaboration_share = 100) OR
			(vr_showPersonalItems = 0 AND nc.collaboration_share < 100)
		) AND
		(vr_lower_creation_date_limit IS NULL OR nd.creation_date >= vr_lower_creation_date_limit) AND
		(vr_upper_creation_date_limit IS NULL OR nd.creation_date <= vr_upper_creation_date_limit)
	
	SELECT ('{' +
			'"NodeName": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS cn_nodes_created_nodes_report;

CREATE PROCEDURE cn_nodes_created_nodes_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_nodeTypeID				UUID,
	vr_creatorNodeTypeID		UUID,
	vr_strNodeIDs				varchar(max),
	vr_delimiter				char,
	vr_showPersonalItems	 BOOLEAN,
	vr_lower_creation_date_limit TIMESTAMP, 
	vr_upper_creation_date_limit TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_node_ids GuidTableType
	INSERT INTO vr_node_ids
	SELECT ref.value FROM gfn_str_to_guid_table(vr_strNodeIDs, vr_delimiter) AS ref
	
	IF vr_creatorNodeTypeID IS NOT NULL AND (SELECT COUNT(*) FROM vr_node_ids) = 0 BEGIN
		INSERT INTO vr_node_ids
		SELECT NodeID
		FROM cn_nodes
		WHERE ApplicationID = vr_application_id AND 
			NodeTypeID = vr_creatorNodeTypeID AND deleted = FALSE
	END
	

	SELECT	nd.node_id AS node_id_hide, 
			MAX(nd.node_name) AS node, 
			MAX(nd.type_name) AS node_type, 
			COUNT(ref.created_node_id) AS count, 
			SUM(ref.personal) AS personal_count, 
			(COUNT(ref.created_node_id) - SUM(ref.personal)) AS group_count, 
			AVG(ref.collaboration) AS collaboration,
			SUM(ref.published) AS published,
			SUM(ref.sent_to_admin) AS sent_to_admin,
			SUM(ref.sent_to_evaluators) AS sent_to_evaluators,
			SUM(ref.accepted) AS accepted,
			SUM(ref.rejected) AS rejected,
			SUM(ref.upload_size) AS upload_size
	FROM
		(
			SELECT nm.node_id, nc.node_id AS created_node_id, 
				CAST(MAX(CASE WHEN nc.collaboration_share = 100 THEN 1 ELSE 0 END) AS integer) AS personal,
				CASE
					WHEN COALESCE(COUNT(nc.user_id), 1) = 0 THEN 0
					ELSE COALESCE(SUM(nc.collaboration_share), 0) / COALESCE(COUNT(nc.user_id), 1)
				END AS collaboration,
				CASE WHEN MAX(CAST(nd.searchable AS integer)) = 1 THEN 1 ELSE 0 END AS published,
				CASE WHEN MAX(nd.status) = N'SentToAdmin' THEN 1 ELSE 0 END AS sent_to_admin,
				CASE WHEN MAX(nd.status) = N'SentToEvaluators' THEN 1 ELSE 0 END AS sent_to_evaluators,
				CASE WHEN MAX(nd.status) = N'Accepted' THEN 1 ELSE 0 END AS accepted,
				CASE WHEN MAX(nd.status) = N'Rejected' THEN 1 ELSE 0 END AS rejected,
				((SUM(COALESCE(f.size, 0)) / (1024.0 * 1024.0)) / COUNT(DISTINCT nc.user_id)) AS upload_size
			FROM vr_node_ids AS nds
				INNER JOIN cn_node_members AS nm
				ON nm.application_id = vr_application_id AND nm.node_id = nds.value AND nm.deleted = FALSE
				INNER JOIN cn_node_creators AS nc
				ON nc.application_id = vr_application_id AND nc.user_id = nm.user_id AND nc.deleted = FALSE
				INNER JOIN cn_nodes AS nd
				ON nd.application_id = vr_application_id AND nd.node_id = nc.node_id AND nd.deleted = FALSE
				LEFT JOIN dct_files AS f
				ON f.application_id = vr_application_id AND f.owner_id = nd.node_id AND 
					(f.owner_type = N'Node') AND f.deleted = FALSE
			WHERE (vr_nodeTypeID IS NULL OR nd.node_type_id = vr_nodeTypeID) AND 
				(vr_showPersonalItems IS NULL OR
					(vr_showPersonalItems = 1 AND nc.collaboration_share = 100) OR
					(vr_showPersonalItems = 0 AND nc.collaboration_share < 100)
				) AND
				(vr_lower_creation_date_limit IS NULL OR 
					nd.creation_date >= vr_lower_creation_date_limit) AND
				(vr_upper_creation_date_limit IS NULL OR 
					nd.creation_date <= vr_upper_creation_date_limit)
			GROUP BY nm.node_id, nc.node_id
		) AS ref
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = ref.node_id
	GROUP BY nd.node_id
	ORDER BY COUNT(ref.created_node_id) DESC

	
	SELECT ('{' +
			'"Node": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'},' +
		   	'"Count": {"Action": "Report", 
		   		"ModuleIdentifier": "CN", "ReportName": "NodeCreatedNodesReport",' +
		   		'"Requires": {"CreatorNodeID": {"Value": "NodeID_Hide", ' + 
		   		'"Title": "~[node] (~[node_type])"}}, ' + 
		   		'"Params": {"ShowPersonalItems": null}' + 
		   	'},' +
		   	'"PersonalCount": {"Action": "Report", 
		   		"ModuleIdentifier": "CN", "ReportName": "NodeCreatedNodesReport",' +
		   		'"Requires": {"CreatorNodeID": {"Value": "NodeID_Hide", ' + 
		   		'"Title": "~[node] (~[node_type])"}}, ' + 
		   		'"Params": {"ShowPersonalItems": true}' + 
		   	'},' +
		   	'"GroupCount": {"Action": "Report", 
		   		"ModuleIdentifier": "CN", "ReportName": "NodeCreatedNodesReport",' +
		   		'"Requires": {"CreatorNodeID": {"Value": "NodeID_Hide", ' + 
		   		'"Title": "~[node] (~[node_type])"}}, ' + 
		   		'"Params": {"ShowPersonalItems": false}' + 
		   	'},' +
		   	'"Published": {"Action": "Report", 
		   		"ModuleIdentifier": "CN", "ReportName": "NodeCreatedNodesReport",' +
		   		'"Requires": {"CreatorNodeID": {"Value": "NodeID_Hide", ' + 
		   		'"Title": "~[node] (~[node_type])"}}, ' + 
		   		'"Params": {"Published": true}' + 
		   	'},' +
		   	'"SentToAdmin": {"Action": "Report", 
		   		"ModuleIdentifier": "CN", "ReportName": "NodeCreatedNodesReport",' +
		   		'"Requires": {"CreatorNodeID": {"Value": "NodeID_Hide", ' + 
		   		'"Title": "~[node] (~[node_type])"}}, ' + 
		   		'"Params": {"Status": "SentToAdmin"}' + 
		   	'},' +
		   	'"SentToEvaluators": {"Action": "Report", 
		   		"ModuleIdentifier": "CN", "ReportName": "NodeCreatedNodesReport",' +
		   		'"Requires": {"CreatorNodeID": {"Value": "NodeID_Hide", ' + 
		   		'"Title": "~[node] (~[node_type])"}}, ' + 
		   		'"Params": {"Status": "SentToEvaluators"}' + 
		   	'},' +
		   	'"Accepted": {"Action": "Report", 
		   		"ModuleIdentifier": "CN", "ReportName": "NodeCreatedNodesReport",' +
		   		'"Requires": {"CreatorNodeID": {"Value": "NodeID_Hide", ' + 
		   		'"Title": "~[node] (~[node_type])"}}, ' + 
		   		'"Params": {"Status": "Accepted"}' + 
		   	'},' +
		   	'"Rejected": {"Action": "Report", 
		   		"ModuleIdentifier": "CN", "ReportName": "NodeCreatedNodesReport",' +
		   		'"Requires": {"CreatorNodeID": {"Value": "NodeID_Hide", ' + 
		   		'"Title": "~[node] (~[node_type])"}}, ' + 
		   		'"Params": {"Status": "Rejected"}' + 
		   	'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS cn_node_created_nodes_report;

CREATE PROCEDURE cn_node_created_nodes_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_nodeTypeID				UUID,
	vr_creatorNodeID			UUID,
	vr_status					varchar(50),
	vr_showPersonalItems	 BOOLEAN,
	vr_published			 BOOLEAN,
	vr_lower_creation_date_limit TIMESTAMP, 
	vr_upper_creation_date_limit TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT	nc.node_id AS node_id_hide, 
			MAX(nd.node_name) AS node,
			MAX(nd.node_additional_id) AS additional_id,
			MAX(nd.type_name) AS node_type,
			MAX(conf.level) AS classification,
			CAST(MAX(CAST(nd.creator_user_id AS varchar(40))) AS uuid) AS creator_user_id_hide,
			MAX(COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N'')) AS creator_name,
			MAX(un.username) AS creator_username,
			MAX(nd.creation_date) AS creation_date,
			COALESCE(COUNT(DISTINCT nc.user_id), 0) AS users_count, 
			CASE
				WHEN COALESCE(COUNT(nc.user_id), 1) = 0 THEN 0
				ELSE COALESCE(SUM(nc.collaboration_share), 0) / COALESCE(COUNT(nc.user_id), 1)
			END AS collaboration,
			CAST(MAX(CAST(nd.searchable AS integer)) AS boolean) AS published_dic,
			MAX(nd.status) AS status_dic,
			MAX(nd.wf_state) AS workflow_state,
			((SUM(COALESCE(f.size, 0)) / (1024.0 * 1024.0)) / COALESCE(COUNT(DISTINCT nc.user_id), 0)) AS upload_size
	FROM cn_node_members AS nm
		INNER JOIN cn_node_creators AS nc
		ON nc.application_id = vr_application_id AND nc.user_id = nm.user_id
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = nc.node_id
		LEFT JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = nd.creator_user_id
		LEFT JOIN dct_files AS f
		ON f.application_id = vr_application_id AND f.owner_id = nd.node_id AND 
			(f.owner_type = N'Node') AND f.deleted = FALSE
		LEFT JOIN prvc_view_confidentialities AS conf
		ON conf.application_id = vr_application_id AND conf.object_id = nd.node_id
	WHERE nm.application_id = vr_application_id AND nm.node_id = vr_creatorNodeID AND 
		(vr_nodeTypeID IS NULL OR nd.node_type_id = vr_nodeTypeID) AND
		nc.deleted = FALSE AND nd.deleted = FALSE AND nm.deleted = FALSE AND
		(COALESCE(vr_status, N'') = N'' OR nd.status = vr_status) AND
		(vr_showPersonalItems IS NULL OR
			(vr_showPersonalItems = 1 AND nc.collaboration_share = 100) OR
			(vr_showPersonalItems = 0 AND nc.collaboration_share < 100)
		) AND
		(vr_published IS NULL OR COALESCE(nd.searchable, TRUE) = vr_published) AND
		(vr_lower_creation_date_limit IS NULL OR 
			nd.creation_date >= vr_lower_creation_date_limit) AND
		(vr_upper_creation_date_limit IS NULL OR 
			nd.creation_date <= vr_upper_creation_date_limit)
	GROUP BY nc.node_id

	
	SELECT ('{' +
			'"Node": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'},' +
			'"CreatorName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "CreatorUserID_Hide"}' +
			'},' +
			'"UsersCount": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "CN", "ReportName": "CreatorUsersReport",' +
		   		'"Rename": {"CreatorNodeID": "MembershipNodeID"}, ' + 
		   		'"Requires": {"NodeID": {"Value": "NodeID_Hide", "Title": "Node"}}, ' + 
		   		'"Params": {}' + 
		   	'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS cn_nodes_own_nodes_report;

CREATE PROCEDURE cn_nodes_own_nodes_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_nodeTypeID				UUID,
	vr_creatorNodeTypeID		UUID,
	vr_strNodeIDs				varchar(max),
	vr_delimiter				char,
	vr_lower_creation_date_limit TIMESTAMP, 
	vr_upper_creation_date_limit TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_node_ids GuidTableType
	INSERT INTO vr_node_ids
	SELECT ref.value FROM gfn_str_to_guid_table(vr_strNodeIDs, vr_delimiter) AS ref
	
	IF vr_creatorNodeTypeID IS NOT NULL AND (SELECT COUNT(*) FROM vr_node_ids) = 0 BEGIN
		INSERT INTO vr_node_ids
		SELECT NodeID
		FROM cn_nodes
		WHERE ApplicationID = vr_application_id AND 
			NodeTypeID = vr_creatorNodeTypeID AND deleted = FALSE
	END
	

	SELECT nd.node_id AS node_id_hide, MAX(nd.node_name) AS node, 
		MAX(nd.type_name) AS node_type, MAX(ref.count) AS count
	FROM
		(
			SELECT nd.owner_id, COUNT(DISTINCT nd.node_id) AS count
			FROM vr_node_ids AS nds
				INNER JOIN cn_nodes AS nd
				ON nd.application_id = vr_application_id AND nd.owner_id = nds.value
			WHERE (vr_nodeTypeID IS NULL OR nd.node_type_id = vr_nodeTypeID) AND 
				nd.deleted = FALSE AND
				(vr_lower_creation_date_limit IS NULL OR 
					nd.creation_date >= vr_lower_creation_date_limit) AND
				(vr_upper_creation_date_limit IS NULL OR 
					nd.creation_date <= vr_upper_creation_date_limit)
			GROUP BY nd.owner_id
		) AS ref
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = ref.owner_id
	GROUP BY nd.node_id
	ORDER BY MAX(ref.count) DESC

	
	SELECT ('{' +
			'"Node": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'},' +
		   	'"Count": {"Action": "Report", 
		   		"ModuleIdentifier": "CN", "ReportName": "NodeOwnNodesReport",' +
		   		'"Requires": {"CreatorNodeID": {"Value": "NodeID_Hide", ' + 
		   		'"Title": "~[node] (~[node_type])"}} ' +
		   	'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS cn_node_own_nodes_report;

CREATE PROCEDURE cn_node_own_nodes_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_nodeTypeID				UUID,
	vr_creatorNodeID			UUID,
	vr_lower_creation_date_limit TIMESTAMP, 
	vr_upper_creation_date_limit TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT	nc.node_id AS node_id_hide, 
			MAX(nd.name) AS node,
			MAX(nd.additional_id) AS additional_id,
			MAX(conf.level) AS classification,
			MAX(nd.creation_date) AS creation_date,
			COUNT(nc.user_id) AS users_count, 
			CASE
				WHEN COALESCE(COUNT(nc.user_id), 1) = 0 THEN 0
				ELSE COALESCE(SUM(nc.collaboration_share), 0) / COALESCE(COUNT(nc.user_id), 1)
			END AS collaboration,
			MAX(nd.wf_state) AS workflow_state
	FROM cn_nodes AS nd
		INNER JOIN cn_node_creators AS nc
		ON nc.application_id = vr_application_id AND nc.node_id = nd.node_id
		LEFT JOIN prvc_view_confidentialities AS conf
		ON conf.application_id = vr_application_id AND conf.object_id = nd.node_id
	WHERE nd.application_id = vr_application_id AND nd.owner_id = vr_creatorNodeID AND 
		(vr_nodeTypeID IS NULL OR nd.node_type_id = vr_nodeTypeID) AND 
		nc.deleted = FALSE AND nd.deleted = FALSE AND
		(vr_lower_creation_date_limit IS NULL OR 
			nd.creation_date >= vr_lower_creation_date_limit) AND
		(vr_upper_creation_date_limit IS NULL OR 
			nd.creation_date <= vr_upper_creation_date_limit)
	GROUP BY nc.node_id

	
	SELECT ('{' +
			'"Node": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'},' +
			'"UsersCount": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "CN", "ReportName": "CreatorUsersReport",' +
		   		'"Rename": {"CreatorNodeID": "MembershipNodeID"}, ' + 
		   		'"Requires": {"NodeID": {"Value": "NodeID_Hide", "Title": "Node"}}, ' + 
		   		'"Params": {}' + 
		   	'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS cn_related_nodes_count_report;

CREATE PROCEDURE cn_related_nodes_count_report
	vr_application_id		UUID,
	vr_current_user_id		UUID,
	vr_nodeTypeID			UUID,
	vr_related_node_type_id	UUID,
	vr_creation_dateFrom TIMESTAMP,
	vr_creation_dateTo	 TIMESTAMP,
	vr_in				 BOOLEAN,
	vr_out			 BOOLEAN,
	vr_inTags			 BOOLEAN,
	vr_outTags		 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE vr_node_ids GuidTableType
	DECLARE vr_node_type_ids GuidTableType
	DECLARE vr_related_node_type_ids GuidTableType

	IF vr_nodeTypeID IS NULL RETURN

	INSERT INTO vr_node_type_ids (Value)
	VALUES (vr_nodeTypeID)

	IF vr_related_node_type_id IS NOT NULL BEGIN
		INSERT INTO vr_related_node_type_ids (Value)
		VALUES (vr_related_node_type_id)
	END

	SELECT	nd.node_id AS node_id_hide,
			nd.node_name AS name,
			nd.node_additional_id AS additional_id,
			x.cnt AS count
	FROM (
			SELECT ref.node_id, COUNT(ref.related_node_id) AS cnt
			FROM cn_fn_get_related_node_ids(vr_application_id, 
					vr_node_ids, vr_node_type_ids, vr_related_node_type_ids, vr_in, vr_out, vr_inTags, vr_outTags) AS ref
			GROUP BY ref.node_id
		) AS x
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = x.node_id
	WHERE (vr_creation_dateFrom IS NULL OR nd.creation_date >= vr_creation_dateFrom) AND
		(vr_creation_dateTo IS NULL OR nd.creation_date < vr_creation_dateTo)
	ORDER BY x.cnt DESC, nd.creation_date DESC
	
	SELECT ('{' +
			'"Name": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'},' +
			'"Count": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "CN", "ReportName": "RelatedNodesReport",' +
		   		'"Requires": {"NodeID": {"Value": "NodeID_Hide", "Title": "Name"}}, ' + 
		   		'"Params": {}' + 
		   	'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS cn_related_nodes_report;

CREATE PROCEDURE cn_related_nodes_report
	vr_application_id		UUID,
	vr_current_user_id		UUID,
	vr_node_id				UUID,
	vr_related_node_type_id	UUID,
	vr_creation_dateFrom TIMESTAMP,
	vr_creation_dateTo	 TIMESTAMP,
	vr_in				 BOOLEAN,
	vr_out			 BOOLEAN,
	vr_inTags			 BOOLEAN,
	vr_outTags		 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE vr_node_ids GuidTableType
	DECLARE vr_node_type_ids GuidTableType
	DECLARE vr_related_node_type_ids GuidTableType

	IF vr_node_id IS NULL RETURN

	INSERT INTO vr_node_ids (Value)
	VALUES (vr_node_id)

	IF vr_related_node_type_id IS NOT NULL BEGIN
		INSERT INTO vr_related_node_type_ids (Value)
		VALUES (vr_related_node_type_id)
	END

	SELECT	r.node_id AS node_id_hide,
			r.node_name AS name,
			r.node_additional_id AS additional_id,
			r.type_name AS node_type
	FROM cn_fn_get_related_node_ids(vr_application_id, 
			vr_node_ids, vr_node_type_ids, vr_related_node_type_ids, vr_in, vr_out, vr_inTags, vr_outTags) AS ref
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = ref.node_id
		INNER JOIN cn_view_nodes_normal AS r
		ON r.application_id = vr_application_id AND r.node_id = ref.related_node_id
	WHERE (vr_creation_dateFrom IS NULL OR nd.creation_date >= vr_creation_dateFrom) AND
		(vr_creation_dateTo IS NULL OR nd.creation_date < vr_creation_dateTo)
	ORDER BY nd.creation_date DESC
	
	SELECT ('{' +
			'"Name": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS cn_downloaded_files_report;

CREATE PROCEDURE cn_downloaded_files_report
	vr_application_id	UUID,
	vr_current_user_id	UUID,
	vr_strNodeTypeIDs	varchar(max),
	vr_strUserIDs		varchar(max),
	vr_delimiter		char,
	vr_beginDate	 TIMESTAMP, 
	vr_finish_date	 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE vr_node_type_ids GuidTableType
	DECLARE vr_user_ids GuidTableType
	
	INSERT INTO vr_node_type_ids (Value)
	SELECT DISTINCT ref.value 
	FROM gfn_str_to_guid_table(vr_strNodeTypeIDs, vr_delimiter) AS ref
	
	INSERT INTO vr_user_ids (Value)
	SELECT DISTINCT ref.value 
	FROM gfn_str_to_guid_table(vr_strUserIDs, vr_delimiter) AS ref

	DECLARE vr_has_user_id BOOLEAN = CAST(COALESCE((SELECT TOP(1) 1 FROM vr_user_ids), 0) AS boolean)
	DECLARE vr_has_node_type_id BOOLEAN = CAST(COALESCE((SELECT TOP(1) 1 FROM vr_node_type_ids), 0) AS boolean)
	
	DECLARE vr_empty UUID = N'00000000-0000-0000-0000-000000000000'
	
	DECLARE vr_logs TABLE (LogID bigint, SubjectID UUID, UserID UUID, date TIMESTAMP)
	
	INSERT INTO vr_logs (LogID, SubjectID, UserID, date)
	SELECT lg.log_id, lg.subject_id, lg.user_id, lg.date
	FROM lg_logs AS lg
	WHERE lg.application_id = vr_application_id AND lg.action = N'Download' AND
		lg.subject_id IS NOT NULL AND lg.subject_id <> vr_empty AND
		(vr_has_user_id = 0 OR lg.user_id IN (SELECT u.value FROM vr_user_ids AS u)) AND
		(vr_beginDate IS NULL OR lg.date >= vr_beginDate) AND
		(vr_finish_date IS NULL OR lg.date <= vr_finish_date)
		
	DECLARE vr_file_ids GuidTableType
	
	INSERT INTO vr_file_ids
	SELECT DISTINCT lg.subject_id
	FROM vr_logs AS lg
	WHERE lg.subject_id IS NOT NULL
	
	DECLARE vr_extensions StringTableType
	
	INSERT INTO vr_extensions (Value)
	VALUES (N'jpg'), (N'png'), (N'gif'), (N'jpeg'), (N'bmp')
	
	SELECT TOP(2000)	
			((ROW_NUMBER() OVER (ORDER BY ref.log_id_hide DESC)) +
			(ROW_NUMBER() OVER (ORDER BY ref.log_id_hide ASC)) - 1) AS total_count_hide,
			ref.*
	FROM (
			SELECT	MAX(lg.log_id) AS log_id_hide,
					CAST(MAX(CAST(x.node_id AS varchar(50))) AS uuid) AS node_id_hide,
					CAST(MAX(CAST(un.user_id AS varchar(50))) AS uuid) AS user_id_hide,
					MAX(LTRIM(RTRIM(COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N'')))) AS full_name,
					MAX(un.username) AS username,
					MAX(x.node_name) AS node_name,
					MAX(x.node_type) AS node_type,
					MAX(x.file_name) AS file_name,
					MAX(x.extension) AS extension,
					MAX(lg.date) AS last_download_date,
					COUNT(DISTINCT lg.log_id) AS downloads_count
			FROM vr_logs AS lg
				INNER JOIN dct_fn_get_file_owner_nodes(vr_application_id, vr_file_ids) AS x
				INNER JOIN dct_files AS f
				ON f.application_id = vr_application_id AND f.file_name_guid = x.file_id
				ON f.file_name_guid = lg.subject_id AND
					(vr_has_node_type_id = 0 OR x.node_type_id IN (SELECT a.value FROM vr_node_type_ids AS a))
				INNER JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = lg.user_id
			WHERE LOWER(COALESCE(x.extension, N'')) NOT IN (SELECT a.value FROM vr_extensions AS a)
			GROUP BY lg.subject_id, lg.user_id
		) AS ref
	ORDER BY ref.log_id_hide DESC

	SELECT ('{' +
			'"NodeName": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'},' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'}' +
		   '}') AS actions
END;

DROP PROCEDURE IF EXISTS usr_users_list_report;

CREATE PROCEDURE usr_users_list_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
    vr_employment_type			varchar(20),
    vr_searchText			 VARCHAR(1000),
    vr_isApproved			 BOOLEAN,
    vr_lowerBirthDateLimit TIMESTAMP,
    vr_upper_birth_date_limit TIMESTAMP,
    vr_lower_creation_date_limit TIMESTAMP,
    vr_upper_creation_date_limit TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_searchText = gfn_get_search_text(vr_searchText)
	
	DECLARE vr_results Table(UserID_Hide UUID primary key clustered,
		Name VARCHAR(1000), UserName VARCHAR(1000), Birthday TIMESTAMP,
		JobTitle VARCHAR(1000), EmploymentType_Dic varchar(50), CreationDate TIMESTAMP,
		DepartmentID_Hide UUID, Department VARCHAR(1000))
	
	IF vr_searchText IS NULL BEGIN
		INSERT INTO vr_results(
			UserID_Hide, Name, UserName, Birthday, JobTitle, EmploymentType_Dic, CreationDate
		)
		SELECT	un.user_id AS user_id_hide,
				LTRIM(RTRIM((COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N'')))) AS name,
				un.username AS username,
				un.birthdate,
				un.job_title,
				un.employment_type,
				un.creation_date
		FROM users_normal AS un
		WHERE un.application_id = vr_application_id AND
			(vr_employment_type IS NULL OR un.employment_type = vr_employment_type) AND
			(vr_lowerBirthDateLimit IS NULL OR un.birthdate >= vr_lowerBirthDateLimit) AND
			(vr_upper_birth_date_limit IS NULL OR un.birthdate <= vr_upper_birth_date_limit) AND
			(vr_lower_creation_date_limit IS NULL OR un.creation_date >= vr_lower_creation_date_limit) AND
			(vr_upper_creation_date_limit IS NULL OR un.creation_date <= vr_upper_creation_date_limit) AND 
			un.is_approved = COALESCE(vr_isApproved, 1)
	END
	ELSE BEGIN
		INSERT INTO vr_results(
			UserID_Hide, Name, UserName, Birthday, JobTitle, EmploymentType_Dic, CreationDate
		)
		SELECT	un.user_id AS user_id_hide,
				LTRIM(RTRIM((COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N'')))) AS name,
				un.username AS username,
				un.birthdate,
				un.job_title,
				un.employment_type,
				un.creation_date
		FROM CONTAINSTABLE(usr_view_users, 
			(username, first_name, last_name), vr_searchText) AS srch
			INNER JOIN users_normal AS un
			ON un.application_id = vr_application_id AND un.user_id = srch.key
		WHERE (vr_employment_type IS NULL OR un.employment_type = vr_employment_type) AND
			(vr_lowerBirthDateLimit IS NULL OR un.birthdate >= vr_lowerBirthDateLimit) AND
			(vr_upper_birth_date_limit IS NULL OR un.birthdate <= vr_upper_birth_date_limit) AND
			(vr_lower_creation_date_limit IS NULL OR un.creation_date >= vr_lower_creation_date_limit) AND
			(vr_upper_creation_date_limit IS NULL OR un.creation_date <= vr_upper_creation_date_limit) AND
			un.is_approved = COALESCE(vr_isApproved, 1)
	END
	
	DECLARE vr_dep_type_ids GuidTableType
	INSERT INTO vr_dep_type_ids (Value)
	SELECT ref.node_type_id
	FROM cn_fn_get_department_node_type_ids(vr_application_id) AS ref
	
	UPDATE R
		SET DepartmentID_Hide = ref.department_id,
			Department = ref.department
	FROM vr_results AS r
		INNER JOIN (
			SELECT t.user_id_hide,
				CAST(MAX(CAST(nd.node_id AS varchar(36))) AS uuid) 
				 AS department_id,
				MAX(nd.name) AS department
			FROM vr_results AS t
				LEFT JOIN cn_node_members AS nm
				LEFT JOIN cn_nodes AS nd
				ON nd.application_id = vr_application_id AND 
					nd.node_type_id IN (SELECT Value FROM vr_dep_type_ids) AND nd.deleted = FALSE
				ON nm.application_id = vr_application_id AND 
					nm.node_id = nd.node_id AND nm.user_id = t.user_id_hide AND nm.deleted = FALSE
			GROUP BY t.user_id_hide
		) AS ref
		ON r.user_id_hide = ref.user_id_hide
		
	
	SELECT * FROM vr_results
	
	SELECT ('{' +
			'"Name": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'},' +
			'"Department": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "DepartmentID_Hide"}' +
			'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS usr_invitations_report;

CREATE PROCEDURE usr_invitations_report
	vr_application_id	UUID,
	vr_current_user_id	UUID,
    vr_beginDate	 TIMESTAMP,
    vr_finish_date	 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	WITH X AS(
		SELECT
			i.sender_user_id,
			COUNT(i.id) AS sent_invitations_count,
			COUNT(tu.user_id) AS registered_users_count,
			COUNT(un.user_id) AS activated_users_count
		FROM u_s_r_invitations AS i
			LEFT JOIN u_s_r_temporary_users AS tu
			ON tu.email = i.email
			LEFT JOIN users_normal AS un
			ON un.application_id = vr_application_id AND un.user_id = tu.user_id
		WHERE i.application_id = vr_application_id AND 
			(vr_beginDate IS NULL OR i.send_date >= vr_beginDate) AND
			(vr_finish_date IS NULL OR i.send_date <= vr_finish_date)
		GROUP BY i.sender_user_id
	)
	SELECT 
		x.sender_user_id AS sender_user_id_hide,
		un.first_name + ' ' + un.last_name AS name,
		x.sent_invitations_count,
		x.registered_users_count,
		x.activated_users_count
	FROM X
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = x.sender_user_id
	ORDER BY x.sent_invitations_count DESC
	
	SELECT (
		'{' +
			'"Name": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "SenderUserID_Hide"}' +
			'}'+
		'}') AS actions
END;


DROP PROCEDURE IF EXISTS usr_users_membership_flow_report;

CREATE PROCEDURE usr_users_membership_flow_report
	vr_application_id					UUID,
	vr_current_user_id					UUID,
	vr_senderUserID					UUID,
    vr_lowerInvitationSentDateLimit TIMESTAMP,
    vr_upper_invitation_sent_date_limit TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT 
		un.user_id AS user_id_hide,
		CASE
			WHEN (un.user_id IS NOT NULL) THEN un.first_name + ' ' + un.last_name
			WHEN (tu.user_id IS NOT NULL) THEN tu.first_name + ' ' + tu.last_name 
			ELSE N'بی نام'
		END AS name,
		i.email,
		i.send_date AS received_date,
		tu.creation_date AS registeration_date,
		un.creation_date AS activation_date
	FROM u_s_r_invitations AS i
		LEFT JOIN u_s_r_temporary_users AS tu
		ON tu.email = i.email
		LEFT JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = tu.user_id
	WHERE i.application_id = vr_application_id AND 
		(vr_senderUserID IS NULL OR i.sender_user_id = vr_senderUserID) AND
		(vr_lowerInvitationSentDateLimit IS NULL OR i.send_date >= vr_lowerInvitationSentDateLimit) AND
		(vr_upper_invitation_sent_date_limit IS NULL OR i.send_date <= vr_upper_invitation_sent_date_limit)
	ORDER BY i.send_date DESC
	
	SELECT (
		'{' +
			'"Name": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'}'+
		'}') AS actions
END;


DROP PROCEDURE IF EXISTS usr_most_visited_items_report;

CREATE PROCEDURE usr_most_visited_items_report
	vr_application_id		UUID,
	vr_current_user_id		UUID,
    vr_itemType			varchar(20),
    vr_nodeTypeID			UUID,
    vr_count			 INTEGER,
    vr_beginDate		 TIMESTAMP,
    vr_finish_date		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF vr_count IS NULL OR vr_count <= 0 SET vr_count = 50
	
	DECLARE vr_results Table (ItemID UUID primary key clustered, 
		VisitsCount INTEGER, LastVisitDate TIMESTAMP)
	
	IF vr_nodeTypeID IS NOT NULL BEGIN
		INSERT INTO vr_results (ItemID, VisitsCount, LastVisitDate)
		SELECT TOP(vr_count) ref.item_id, ref.count, ref.visit_date
		FROM (
				SELECT iv.item_id, COUNT(iv.item_id) AS count, MAX(iv.visit_date) AS visit_date
				FROM usr_item_visits AS iv
					INNER JOIN cn_nodes AS nd
					ON nd.application_id = vr_application_id AND nd.node_id = iv.item_id
				WHERE iv.application_id = vr_application_id AND nd.node_type_id = vr_nodeTypeID AND
					(vr_beginDate IS NULL OR iv.visit_date >= vr_beginDate) AND
					(vr_finish_date IS NULL OR iv.visit_date <= vr_finish_date)
				GROUP BY iv.item_id
			) AS ref
		ORDER BY ref.count DESC, ref.visit_date DESC
	END
	ELSE BEGIN
		INSERT INTO vr_results (ItemID, VisitsCount, LastVisitDate)
		SELECT TOP(vr_count) ref.item_id, ref.count, ref.visit_date
		FROM (
				SELECT ItemID, COUNT(ItemID) AS count, MAX(VisitDate) AS visit_date
				FROM usr_item_visits
				WHERE ApplicationID = vr_application_id AND ItemType = vr_itemType AND
					(vr_beginDate IS NULL OR VisitDate >= vr_beginDate) AND
					(vr_finish_date IS NULL OR VisitDate <= vr_finish_date)
				GROUP BY ItemID
			) AS ref
		ORDER BY ref.count DESC, ref.visit_date DESC
	END
	
	IF vr_itemType = N'User' BEGIN
		SELECT r.item_id AS item_id_hide, 
			(un.first_name + N' ' + un.last_name) AS item_name, 
			un.username,
			r.visits_count
		FROM vr_results AS r
			INNER JOIN users_normal AS un
			ON un.application_id = vr_application_id AND un.user_id = r.item_id
		ORDER BY r.visits_count DESC, r.last_visit_date DESC
	END
	ELSE BEGIN
		SELECT r.item_id AS item_id_hide, nd.node_name AS item_name, r.visits_count
		FROM vr_results AS r
			INNER JOIN cn_view_nodes_normal AS nd
			ON nd.application_id = vr_application_id AND nd.node_id = r.item_id
		ORDER BY r.visits_count DESC, r.last_visit_date DESC
	END
END;


DROP PROCEDURE IF EXISTS usr_p_users_performance_report;

CREATE PROCEDURE usr_p_users_performance_report
	vr_application_id			UUID,
    vr_user_group_ids_temp		GuidPairTableType readonly,
    vr_knowledge_type_idsTemp	GuidTableType readonly,
    vr_compensate_per_score	 BOOLEAN,
    vr_compensation_volume		float,
    vr_scoreItemsTemp			FloatStringTableType readonly,
    vr_beginDate			 TIMESTAMP,
    vr_finish_date			 TIMESTAMP
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_users TABLE (UserID UUID primary key clustered, GroupID UUID, GroupName VARCHAR(500)) 
	INSERT INTO vr_users (UserID, GroupID, GroupName)
	SELECT t.first_value, nd.node_id, nd.name
	FROM vr_user_group_ids_temp AS t
		LEFT JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = t.second_value
	
    DECLARE vr_knowledge_type_ids GuidTableType
    INSERT INTO vr_knowledge_type_ids SELECT * FROM vr_knowledge_type_idsTemp
    
    DECLARE vr_scoreItems FloatStringTableType
    INSERT INTO vr_scoreItems SELECT * FROM vr_scoreItemsTemp

	SELECT data.*
	INTO #Results
	FROM (
			-- (1) تعداد به اشتراک گذاری ها روی تخته دانش
			---- ItemName: SharesOnWall ----
			SELECT users.user_id, posts.score, N'AA_SharesOnWall' AS item_name 
			FROM vr_users AS users
				LEFT JOIN (
					SELECT ps.sender_user_id, COALESCE(COUNT(ps.share_id), 0) AS score 
					FROM sh_post_shares AS ps
					WHERE ps.application_id = vr_application_id AND 
						ps.owner_type = N'User' AND ps.deleted = FALSE AND
						(vr_beginDate IS NULL OR ps.send_date >= vr_beginDate) AND
						(vr_finish_date IS NULL OR ps.send_date <= vr_finish_date)
					GROUP BY ps.sender_user_id
				) AS posts
				ON users.user_id = posts.sender_user_id
			-- end of (1)

			UNION ALL

			-- (8) تعداد نظرات دریافت شده بر روی دانش ها
			---- ItemName: ReceivedSharesOnKnowledges ----
			SELECT usr.user_id, (
				(SELECT COALESCE(COUNT(ps.share_id), 0)
				 FROM sh_post_shares AS ps
					INNER JOIN kw_view_knowledges AS vk
					INNER JOIN cn_node_creators AS nc
					ON nc.application_id = vr_application_id AND nc.node_id = vk.knowledge_id
					ON vk.application_id = vr_application_id AND vk.knowledge_id = ps.owner_id
				 WHERE nc.application_id = vr_application_id AND 
					nc.user_id = usr.user_id AND nc.deleted = FALSE AND 
					ps.sender_user_id <> usr.user_id AND ps.owner_type = N'Knowledge' AND
					vk.deleted = FALSE AND ps.deleted = FALSE AND
					(vr_beginDate IS NULL OR ps.send_date >= vr_beginDate) AND
					(vr_finish_date IS NULL OR ps.send_date <= vr_finish_date))
			), N'AB_ReceivedSharesOnKnowledges'
			FROM vr_users AS usr
			-- end of (8)

			UNION ALL

			-- (9) تعداد نظرهای ارسال کرده بر روی دانش های دیگران
			---- ItemName: SentSharesOnKnowledges ----
			SELECT usr.user_id, (
				SELECT COALESCE(COUNT(ps.share_id), 0)
				FROM sh_post_shares AS ps
					INNER JOIN kw_view_knowledges VK
					ON vk.application_id = vr_application_id AND vk.knowledge_id = ps.owner_id
				WHERE ps.application_id = vr_application_id AND ps.sender_user_id = usr.user_id AND
					ps.owner_type = N'Knowledge' AND ps.deleted = FALSE AND
					(vr_beginDate IS NULL OR ps.send_date >= vr_beginDate) AND
					(vr_finish_date IS NULL OR ps.send_date <= vr_finish_date) AND
					NOT EXISTS(SELECT TOP(1) * FROM cn_node_creators AS nc
						WHERE nc.node_id = vk.knowledge_id AND nc.user_id = usr.user_id AND nc.deleted = FALSE)
			), N'AC_SentSharesOnKnowledges'
			FROM vr_users AS usr
			-- end of (9)

			UNION ALL

			-- (10) مجموع صرفه جویی های زمانی دانش های ثبت شده
			---- ItemName: ReceivedTemporalFeedBacks ----
			SELECT usr.user_id, (
				(SELECT COALESCE(SUM(fb.value), 0)
				 FROM kw_feedbacks AS fb
					INNER JOIN kw_view_knowledges AS vk
					INNER JOIN cn_node_creators AS nc
					ON nc.application_id = vr_application_id AND nc.node_id = vk.knowledge_id
					ON vk.application_id = vr_application_id AND vk.knowledge_id = fb.knowledge_id
				 WHERE fb.application_id = vr_application_id AND 
					nc.user_id = usr.user_id AND nc.deleted = FALSE AND 
					fb.feedback_type_id = 2 AND fb.user_id <> usr.user_id AND
					vk.deleted = FALSE AND fb.deleted = FALSE AND
					(vr_beginDate IS NULL OR fb.send_date >= vr_beginDate) AND
					(vr_finish_date IS NULL OR fb.send_date <= vr_finish_date))
			), N'AD_ReceivedTemporalFeedBacks'
			FROM vr_users AS usr
			-- end of (10)

			UNION ALL

			-- (11) مجموع صرفه جویی های ریالی دانش های ثبت شده
			---- ItemName: ReceivedFinancialFeedBacks ----
			SELECT usr.user_id, (
				(SELECT COALESCE(SUM(fb.value), 0)
				 FROM kw_feedbacks AS fb
					INNER JOIN kw_view_knowledges AS vk
					INNER JOIN cn_node_creators AS nc
					ON nc.application_id = vr_application_id AND nc.node_id = vk.knowledge_id
					ON vk.application_id = vr_application_id AND vk.knowledge_id = fb.knowledge_id
				 WHERE fb.application_id = vr_application_id AND 
					nc.user_id = usr.user_id AND nc.deleted = FALSE AND 
					fb.feedback_type_id = 1 AND fb.user_id <> usr.user_id AND
					vk.deleted = FALSE AND fb.deleted = FALSE AND
					(vr_beginDate IS NULL OR fb.send_date >= vr_beginDate) AND
					(vr_finish_date IS NULL OR fb.send_date <= vr_finish_date))
			), N'AE_ReceivedFinancialFeedBacks'
			FROM vr_users AS usr
			-- end of (11)

			UNION ALL

			-- (12) تعداد صرفه جویی های اعلام کرده بر روی دانش های دیگران
			---- ItemName: SentFeedBacksCount ----
			SELECT usr.user_id, (
				SELECT COUNT(fb.value) 
				FROM kw_feedbacks AS fb
					INNER JOIN kw_view_knowledges AS vk
					ON vk.application_id = vr_application_id AND vk.knowledge_id = fb.knowledge_id
				WHERE fb.application_id = vr_application_id AND 
					fb.user_id = usr.user_id AND fb.deleted = FALSE AND
					(vr_beginDate IS NULL OR fb.send_date >= vr_beginDate) AND
					(vr_finish_date IS NULL OR fb.send_date <= vr_finish_date) AND
					NOT EXISTS(SELECT TOP(1) * FROM cn_node_creators AS nc
						WHERE nc.node_id = vk.knowledge_id AND nc.user_id = usr.user_id AND nc.deleted = FALSE)
			), N'AF_SentFeedBacksCount'
			FROM vr_users AS usr
			-- end of (12)

			UNION ALL

			-- (13) تعداد سوالات پرسیده شده
			---- ItemName: SentQuestions ----
			SELECT users.user_id, COALESCE(qtn.score, 0), N'AG_SentQuestions' 
			FROM vr_users AS users
				LEFT JOIN (
					SELECT qu.sender_user_id, COUNT(qu.question_id) AS score
					FROM qa_questions AS qu
					WHERE qu.application_id = vr_application_id AND qu.deleted = FALSE AND 
						(vr_beginDate IS NULL OR qu.send_date >= vr_beginDate) AND
						(vr_finish_date IS NULL OR qu.send_date <= vr_finish_date)
					GROUP BY qu.sender_user_id
				) AS qtn
				ON users.user_id = qtn.sender_user_id
			-- end of (13)

			UNION ALL

			-- (14) مجموع امتیاز پاسخ های ارسال شده بر روی سوالات دیگران
			---- ItemName: SentAnswers ----
			SELECT usr.user_id, (
				SELECT COALESCE(COUNT(ans.answer_id), 0)
				FROM qa_answers AS ans
					INNER JOIN qa_questions AS qu
					ON qu.application_id = vr_application_id AND qu.question_id = ans.question_id
				WHERE ans.application_id = vr_application_id AND ans.sender_user_id = usr.user_id AND 
					qu.sender_user_id <> usr.user_id AND ans.deleted = FALSE AND
					(vr_beginDate IS NULL OR ans.send_date >= vr_beginDate) AND
					(vr_finish_date IS NULL OR ans.send_date <= vr_finish_date)
			), N'AH_SentAnswers'
			FROM vr_users AS usr 
			-- end of (14)

			UNION ALL

			-- (15) تعداد ارزیابی اولیه دانش های دیگران
			---- ItemName: KnowledgeOverview ----
			SELECT	usr.user_id,
					SUM(
						CASE 
							WHEN h.knowledge_id IS NOT NULL THEN 1
							ELSE 0
						END
					),
					N'AI_KnowledgeOverview'
			FROM vr_users AS usr
				LEFT JOIN (
					SELECT ROW_NUMBER() OVER (PARTITION BY h.knowledge_id, h.actor_user_id ORDER BY h.id ASC) AS row_number,
						h.knowledge_id,
						h.actor_user_id,
						h.action_date
					FROM kw_history AS h
					WHERE h.application_id = vr_application_id AND h.action IN (
							N'Accept', N'Reject', N'SendBackForRevision', 
							N'SendToEvaluators', N'TerminateEvaluation'
						)
				) AS h
				INNER JOIN cn_nodes AS nd
				ON nd.application_id = vr_application_id AND 
					nd.node_id = h.knowledge_id AND nd.deleted = FALSE
				ON h.row_number = 1 AND h.actor_user_id = usr.user_id AND
					(vr_beginDate IS NULL OR h.action_date >= vr_beginDate) AND
					(vr_finish_date IS NULL OR h.action_date <= vr_finish_date) AND
					NOT EXISTS(
						SELECT TOP(1) * 
						FROM cn_node_creators AS nc
						WHERE nc.application_id = vr_application_id AND 
							nc.node_id = h.knowledge_id AND nc.user_id = usr.user_id AND nc.deleted = FALSE
					)
			GROUP BY usr.user_id
			-- end of (15)

			UNION ALL

			-- (16) تعداد ارزیابی خبرگی دانش های دیگران
			---- ItemName: KnowledgeEvaluation ----
			SELECT	usr.user_id,
					SUM(
						CASE 
							WHEN h.knowledge_id IS NOT NULL THEN 1
							ELSE 0
						END
					),
					N'AJ_KnowledgeEvaluation'
			FROM vr_users AS usr
				LEFT JOIN (
					SELECT ROW_NUMBER() OVER (PARTITION BY h.knowledge_id, h.actor_user_id ORDER BY h.id ASC) AS row_number,
						h.knowledge_id,
						h.actor_user_id,
						h.action_date
					FROM kw_history AS h
					WHERE h.application_id = vr_application_id AND h.action IN (N'Evaluation')
				) AS h
				INNER JOIN cn_nodes AS nd
				ON nd.application_id = vr_application_id AND 
					nd.node_id = h.knowledge_id AND nd.deleted = FALSE
				ON h.row_number = 1 AND h.actor_user_id = usr.user_id AND
					(vr_beginDate IS NULL OR h.action_date >= vr_beginDate) AND
					(vr_finish_date IS NULL OR h.action_date <= vr_finish_date) AND
					NOT EXISTS(
						SELECT TOP(1) * 
						FROM cn_node_creators AS nc
						WHERE nc.application_id = vr_application_id AND 
							nc.node_id = h.knowledge_id AND nc.user_id = usr.user_id AND nc.deleted = FALSE
					)
			GROUP BY usr.user_id
			-- end of (16)

			UNION ALL

			-- (17) امتیاز انجمن
			---- ItemName: CommunityScore ----
			SELECT usr.user_id, (
				(
					SELECT COALESCE(COUNT(ans.answer_id), 0)
					FROM qa_answers AS ans
						INNER JOIN qa_questions AS qu
						ON qu.application_id = vr_application_id AND qu.question_id = ans.question_id
					WHERE ans.application_id = vr_application_id AND 
						ans.sender_user_id = usr.user_id AND qu.sender_user_id <> usr.user_id AND 
						ans.deleted = FALSE AND
						(vr_beginDate IS NULL OR ans.send_date >= vr_beginDate) AND
						(vr_finish_date IS NULL OR ans.send_date <= vr_finish_date)
				) + (
					SELECT CAST(COALESCE(COUNT(ps.share_id), 0) AS float)
					FROM sh_post_shares AS ps
					WHERE ps.application_id = vr_application_id AND ps.sender_user_id = usr.user_id AND
						ps.owner_type = N'Node' AND ps.deleted = FALSE AND
						(vr_beginDate IS NULL OR ps.send_date >= vr_beginDate) AND
						(vr_finish_date IS NULL OR ps.send_date <= vr_finish_date)
				)
			), N'AK_CommunityScore'
			FROM vr_users AS usr
			-- end of (17)

			UNION ALL

			-- (18) تعداد تغییرات ویکی تایید شده
			---- ItemName: AcceptedWikiChanges ----
			SELECT users.user_id, COALESCE(cng.score, 0), N'AL_AcceptedWikiChanges' 
			FROM vr_users AS users
				LEFT JOIN (
					SELECT ch.user_id, COUNT(ch.change_id) AS score
					FROM wk_changes AS ch
					WHERE ch.application_id = vr_application_id AND ch.status = N'Accepted' AND
						(vr_beginDate IS NULL OR ch.acception_date >= vr_beginDate) AND
						(vr_finish_date IS NULL OR ch.acception_date <= vr_finish_date)
					GROUP BY ch.user_id
				) AS cng
				ON users.user_id = cng.user_id
			-- end of (18)

			UNION ALL

			-- (19) تعداد ویکی های داوری کرده به عنوان خبره
			---- ItemName: WikiEvaluation ----
			SELECT users.user_id, COALESCE(cng.score, 0), N'AM_WikiEvaluation' 
			FROM vr_users AS users
				LEFT JOIN (
					SELECT ch.evaluator_user_id, COUNT(ch.change_id) AS score
					FROM wk_changes AS ch
					WHERE ch.application_id = vr_application_id AND 
						(vr_beginDate IS NULL OR ch.evaluation_date >= vr_beginDate) AND
						(vr_finish_date IS NULL OR ch.evaluation_date <= vr_finish_date)
					GROUP BY ch.evaluator_user_id
				) AS cng
				ON users.user_id = cng.evaluator_user_id
			-- end of (19)

			UNION ALL

			-- (20) تعداد بازدید دیگران از صفحه شخصی
			---- ItemName: PersonalPageVisit ----
			SELECT usr.user_id, 
				(
					SELECT COUNT(iv.user_id) 
					FROM usr_item_visits AS iv
					WHERE iv.application_id = vr_application_id AND iv.item_id = usr.user_id AND
						(vr_beginDate IS NULL OR iv.visit_date >= vr_beginDate) AND
						(vr_finish_date IS NULL OR iv.visit_date <= vr_finish_date)
				), N'AN_PersonalPageVisit'
			FROM vr_users AS usr
			-- end of (20)
			
			UNION ALL
			
			-- (N) دانش ها
			SELECT	users.user_id AS user_id, COALESCE(kn.score, 0), kn.registered_type
			FROM vr_users AS users
				LEFT JOIN (
					SELECT	nc.user_id,
							N'AO_Registered_' + REPLACE(CAST(nd.node_type_id AS varchar(100)), '-', '') AS registered_type, 
							SUM(
								CASE
									WHEN (vr_beginDate IS NULL OR nd.creation_date >= vr_beginDate) AND
										(vr_finish_date IS NULL OR nd.creation_date <= vr_finish_date) THEN 1
									ELSE 0
								END * (nc.collaboration_share / 100)
							) AS score
					FROM vr_knowledge_type_ids AS k
						INNER JOIN cn_nodes AS nd
						ON nd.application_id = vr_application_id AND nd.node_type_id = k.value
						INNER JOIN cn_node_creators AS nc
						ON nc.application_id = vr_application_id AND nc.node_id = nd.node_id
					WHERE nd.deleted = FALSE AND nc.deleted = FALSE
					GROUP BY nc.user_id, nd.node_type_id
				) AS kn
				ON users.user_id = kn.user_id
				
			UNION ALL

			SELECT	users.user_id AS user_id, COALESCE(kn.score, 0), kn.accepted_type_count
			FROM vr_users AS users
				LEFT JOIN (
					SELECT	nc.user_id,
							N'AP_AcceptedCount_' + REPLACE(CAST(nd.node_type_id AS varchar(100)), '-', '') AS accepted_type_count,
							SUM(
								CASE
									WHEN nd.status = N'Accepted' AND 
										(vr_beginDate IS NULL OR COALESCE(nd.publication_date, nd.creation_date) >= vr_beginDate) AND
										(vr_finish_date IS NULL OR COALESCE(nd.publication_date, nd.creation_date) <= vr_finish_date)
										THEN 1
									ELSE 0
								END * (nc.collaboration_share / 100)
							) AS score
					FROM vr_knowledge_type_ids AS k
						INNER JOIN cn_nodes AS nd
						ON nd.application_id = vr_application_id AND nd.node_type_id = k.value
						INNER JOIN cn_node_creators AS nc
						ON nc.application_id = vr_application_id AND nc.node_id = nd.node_id
					WHERE nd.deleted = FALSE AND nc.deleted = FALSE
					GROUP BY nc.user_id, nd.node_type_id
				) AS kn
				ON users.user_id = kn.user_id
				
			UNION ALL

			SELECT	users.user_id AS user_id, COALESCE(kn.score, 0), kn.accepted_type_score
			FROM vr_users AS users
				LEFT JOIN (
					SELECT	nc.user_id,
							N'AQ_AcceptedScore_' + REPLACE(CAST(nd.node_type_id AS varchar(100)), '-', '') AS accepted_type_score,
							SUM(
								CASE
									WHEN nd.status = N'Accepted' AND 
										(vr_beginDate IS NULL OR COALESCE(nd.publication_date, nd.creation_date) >= vr_beginDate) AND
										(vr_finish_date IS NULL OR COALESCE(nd.publication_date, nd.creation_date) <= vr_finish_date)
										THEN COALESCE(nd.score, 0)
									ELSE 0
								END * (nc.collaboration_share / 100)
							) AS score
					FROM vr_knowledge_type_ids AS k
						INNER JOIN cn_nodes AS nd
						ON nd.application_id = vr_application_id AND nd.node_type_id = k.value
						INNER JOIN cn_node_creators AS nc
						ON nc.application_id = vr_application_id AND nc.node_id = nd.node_id
					WHERE nd.deleted = FALSE AND nc.deleted = FALSE
					GROUP BY nc.user_id, nd.node_type_id
				) AS kn
				ON users.user_id = kn.user_id
			-- end of (N)
		) AS data
		INNER JOIN vr_scoreItems AS si
		ON si.second_value = data.item_name AND si.first_value > 0
	
	
	DECLARE vr_itemsList VARCHAR(MAX)   

	SELECT vr_itemsList = COALESCE(vr_itemsList + ', ', '') + '[' + ItemName + ']'
	FROM (SELECT DISTINCT ItemName FROM #Results) AS q
	ORDER BY q.item_name
	
	CREATE TABLE #TMPR (UserID_Hide UUID, GroupID_Hide UUID, 
		Name VARCHAR(1000), UserName VARCHAR(256), GroupName VARCHAR(500),
		Score float, Compensation float
	)
	
	INSERT INTO #TMPR (UserID_Hide)
	SELECT DISTINCT UserID
	FROM #Results AS r
	
	-- Compute Users' Scores
	UPDATE T
		SET Score = ref.score
	FROM #TMPR AS t
		INNER JOIN (
			SELECT r.user_id, SUM(COALESCE(s.first_value, 0) * COALESCE(r.score, 0)) AS score
			FROM #Results AS r
				INNER JOIN vr_scoreItems AS s
				ON LOWER(r.item_name) = LOWER(s.second_value)
			GROUP BY r.user_id
		) AS ref
		ON t.user_id_hide = ref.user_id
	-- end of Compute Users' Scores
	
	-- Compute Users' Compensations
	DECLARE vr_scoreReward float = vr_compensation_volume
	
	IF(vr_compensate_per_score IS NULL OR vr_compensate_per_score = 0)
		SET vr_scoreReward = vr_compensation_volume / (SELECT SUM(Score) FROM #TMPR)
	
	UPDATE #TMPR
	SET Compensation = Score * COALESCE(vr_scoreReward, 0)
	-- end of Compute Users' Compensations
	
	-- Determine Full Names & Groups
	UPDATE R
		SET GroupID_Hide = u.group_id,
			Name = LTRIM(RTRIM(COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N''))),
			UserName = un.username,
			GroupName = u.group_name
	FROM #TMPR AS r
		INNER JOIN vr_users AS u
		ON u.user_id = r.user_id_hide
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = u.user_id
	-- end of Determine Names & Departments
	
	
	EXEC (
		'SELECT ROW_NUMBER() OVER(ORDER BY t.score DESC, t.user_id_hide ASC) AS rank, t.user_id_hide, t.group_id_hide, t.name, t.username, ' +
			't.group_name, t.score, t.compensation, ' + vr_itemsList + ' ' +
		'FROM #TMPR AS t ' +
			'INNER JOIN ( ' +
				'SELECT UserID, ' + vr_itemsList + ' ' +
				'FROM ( ' +
						'SELECT UserID, Score, ItemName ' +
						'FROM #Results ' +
					') AS p ' +
					'PIVOT ' +
					'(SUM(Score) FOR ItemName IN (' + vr_itemsList + ')) AS pvt ' +
			') AS x ' +
			'ON x.user_id = t.user_id_hide ' +
		'ORDER BY t.score DESC, t.user_id_hide ASC'
	)
	
	SELECT ('{' +
			'"Name": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'},' +
			'"GroupName": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "GroupID_Hide"}' +
			'}' +
		   '}') AS actions
	
	SELECT *
	FROM (
		SELECT	'AO_Registered_' + REPLACE(CAST(nt.node_type_id AS varchar(100)), '-', '') AS column_name,
				N'تعداد ''' + nt.name + N''' ثبت شده' AS translation,
				'double' AS type
		FROM vr_knowledge_type_ids AS k
			INNER JOIN cn_node_types AS nt
			ON nt.node_type_id = k.value
			
		UNION ALL
		
		SELECT	'AP_AcceptedCount_' + REPLACE(CAST(nt.node_type_id AS varchar(100)), '-', '') AS column_name,
				N'تعداد ''' + nt.name + N''' تایید شده' AS translation,
				'double' AS type
		FROM vr_knowledge_type_ids AS k
			INNER JOIN cn_node_types AS nt
			ON nt.node_type_id = k.value
		
		UNION ALL
		
		SELECT	'AQ_AcceptedScore_' + REPLACE(CAST(nt.node_type_id AS varchar(100)), '-', '') AS column_name,
				N'جمع امتیازات ''' + nt.name + N''' تایید شده' AS translation,
				'double' AS type
		FROM vr_knowledge_type_ids AS k
			INNER JOIN cn_node_types AS nt
			ON nt.node_type_id = k.value
	) AS x
			
	SELECT ('{"IsDescription": "true", "IsColumnsDictionary": "true"}') AS info
END;


DROP PROCEDURE IF EXISTS usr_users_performance_report;

CREATE PROCEDURE usr_users_performance_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
    vr_strUserIDs				varchar(max),
    vr_strNodeIDs				varchar(max),
    vr_strListIDs				varchar(max),
    vr_strKnowledgeTypeIDs	varchar(max),
    vr_delimiter				char,
    vr_beginDate			 TIMESTAMP,
    vr_finish_date			 TIMESTAMP,
    vr_compensate_per_score	 BOOLEAN,
    vr_compensation_volume		float,
    vr_strScoreItems			varchar(max),
    vr_inner_delimiter			char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_node_ids GuidTableType
	
	INSERT INTO vr_node_ids (Value)
	SELECT DISTINCT ref.value
	FROM gfn_str_to_guid_table(vr_strNodeIDs, vr_delimiter) AS ref
	
	DECLARE vr_list_ids GuidTableType
	
	INSERT INTO vr_list_ids (Value)
	SELECT DISTINCT ref.value
	FROM gfn_str_to_guid_table(vr_strListIDs, vr_delimiter) AS ref
	
	DECLARE vr_groups_count INTEGER = (SELECT COUNT(*) FROM vr_node_ids) + (SELECT COUNT(*) FROM vr_list_ids)
	
	DECLARE vr_scoreItems FloatStringTableType
	INSERT INTO vr_scoreItems (FirstValue, SecondValue)
	SELECT ref.first_value, ref.second_value
	FROM gfn_str_to_float_string_table(vr_strScoreItems, vr_inner_delimiter, vr_delimiter) AS ref
	
	DECLARE vr_user_ids TABLE (UserID UUID, GroupID UUID)
	
	INSERT INTO vr_user_ids(UserID, GroupID)
	SELECT uid.user_id, CAST(MAX(CAST(uid.group_id AS varchar(50))) AS uuid) AS group_id
	FROM (
			SELECT ref.value AS user_id, NULL AS group_id
			FROM GFN_StrToGuidTable(vr_strUserIDs, vr_delimiter) AS ref	
			
			UNION ALL
			
			SELECT nm.user_id AS user_id, nm.node_id AS group_id
			FROM (
					SELECT ref.value AS value
					FROM vr_node_ids AS ref
					
					UNION ALL
					 
					SELECT nd.node_id
					FROM vr_list_ids AS l_ids
						INNER JOIN cn_list_nodes AS ln
						ON ln.application_id = vr_application_id AND ln.list_id = l_ids.value
						INNER JOIN cn_nodes AS nd
						ON nd.application_id = vr_application_id AND nd.node_id = ln.node_id
					WHERE ln.deleted = FALSE AND nd.deleted = FALSE
				) AS nid
				INNER JOIN cn_node_members AS nm
				ON nm.application_id = vr_application_id AND nm.node_id = nid.value
				INNER JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = nm.user_id
			WHERE nm.status = N'Accepted' AND nm.deleted = FALSE AND un.is_approved = TRUE
		) AS uid
	GROUP BY uid.user_id
	
	IF vr_groups_count = 0 BEGIN
		IF (SELECT COUNT(*) FROM vr_user_ids) = 0 BEGIN
			INSERT INTO vr_user_ids (UserID)
			SELECT UserID
			FROM users_normal
			WHERE ApplicationID = vr_application_id AND is_approved = TRUE
		END
		
		DECLARE vr_dep_type_ids GuidTableType
		INSERT INTO vr_dep_type_ids (Value)
		SELECT ref.node_type_id
		FROM cn_fn_get_department_node_type_ids(vr_application_id) AS ref
	
		UPDATE R
			SET GroupID = ref.group_id
		FROM vr_user_ids AS r
			INNER JOIN (
				SELECT t.user_id,
					CAST(MAX(CAST(nd.node_id AS varchar(36))) AS uuid) AS group_id
				FROM vr_user_ids AS t
					INNER JOIN cn_node_members AS nm
					INNER JOIN cn_nodes AS nd
					ON nd.application_id = vr_application_id AND 
						nd.node_type_id IN (SELECT Value FROM vr_dep_type_ids) AND nd.deleted = FALSE
					ON nm.application_id = vr_application_id AND
						nm.node_id = nd.node_id AND nm.user_id = t.user_id AND nm.deleted = FALSE
				GROUP BY t.user_id
			) AS ref
			ON r.user_id = ref.user_id
	END
	
	DECLARE vr_knowledge_type_ids GuidTableType
	
	INSERT INTO vr_knowledge_type_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strKnowledgeTypeIDs, vr_delimiter) AS ref
	
	DECLARE vr_user_group_ids GuidPairTableType
	
	INSERT INTO vr_user_group_ids (FirstValue, SecondValue)
	SELECT DISTINCT u.user_id, COALESCE(u.group_id, gen_random_uuid())
	FROM vr_user_ids AS u
	
	EXEC usr_p_users_performance_report vr_application_id, vr_user_group_ids, vr_knowledge_type_ids,
		vr_compensate_per_score, vr_compensation_volume, vr_scoreItems, vr_beginDate, vr_finish_date
END;


DROP PROCEDURE IF EXISTS usr_profile_filled_percentage_report;

CREATE PROCEDURE usr_profile_filled_percentage_report
	vr_application_id		UUID,
	vr_current_user_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT	x.filled_percentage,
			COUNT(x.user_id) AS users_count,
			SUM(x.has_job_title) AS job_titles_count,
			SUM(x.jobs_count) AS jobs_count,
			SUM(x.schools_count) AS schools_count,
			SUM(x.courses_count) AS courses_count,
			SUM(x.honors_count) AS honors_count,
			SUM(x.languages_count) AS languages_count
	FROM (
			SELECT	r.user_id,
					(
						CASE WHEN r.has_job_title > 0 THEN 1 ELSE 0 END +
						CASE WHEN r.jobs_count > 0 THEN 1 ELSE 0 END +
						CASE WHEN r.schools_count > 0 THEN 1 ELSE 0 END +
						CASE WHEN r.courses_count > 0 THEN 1 ELSE 0 END +
						CASE WHEN r.honors_count > 0 THEN 1 ELSE 0 END +
						CASE WHEN r.languages_count > 0 THEN 1 ELSE 0 END
					) * 100 / 6 AS filled_percentage,
					r.has_job_title,
					r.jobs_count,
					r.schools_count,
					r.courses_count,
					r.honors_count,
					r.languages_count
			FROM (
					SELECT	un.user_id,
							CASE WHEN COALESCE(MAX(un.job_title), N'') = N'' THEN 0 ELSE 1 END AS has_job_title,
							COUNT(DISTINCT je.job_id) AS jobs_count,
							COUNT(DISTINCT
								CASE 
									WHEN ee.education_id IS NOT NULL AND ee.is_school = 1 THEN ee.education_id 
									ELSE NULL 
								END
							) AS schools_count,
							COUNT(DISTINCT
								CASE 
									WHEN ee.education_id IS NOT NULL AND ee.is_school = 0 THEN ee.education_id 
									ELSE NULL 
								END
							) AS courses_count,
							COUNT(DISTINCT ha.id) AS honors_count,
							COUNT(DISTINCT ul.id) AS languages_count
					FROM users_normal AS un
						LEFT JOIN usr_job_experiences AS je
						ON je.application_id = vr_application_id AND 
							je.user_id = un.user_id AND je.deleted = FALSE
						LEFT JOIN usr_educational_experiences AS ee
						ON ee.application_id = vr_application_id AND
							ee.user_id = un.user_id AND ee.deleted = FALSE
						LEFT JOIN usr_honors_and_awards AS ha
						ON ha.application_id = vr_application_id AND
							ha.user_id = un.user_id AND ha.deleted = FALSE
						LEFT JOIN usr_user_languages AS ul
						ON ul.application_id = vr_application_id AND
							ul.user_id = un.user_id AND ul.deleted = FALSE
					WHERE un.application_id = vr_application_id AND un.is_approved = TRUE
					GROUP BY un.user_id
				) AS r
		) AS x
	GROUP BY x.filled_percentage
	
	SELECT ('{' +
			'"FilledPercentage": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "USR", "ReportName": "UsersWithSpecificPercentageOfFilledProfileReport",' +
		   		'"Requires": {"FilledPercentage": {"Value": "FilledPercentage"}}, ' + 
		   		'"Params": {}' + 
		   	'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS usr_users_with_specific_percentage_of_filled_profile_report;

CREATE PROCEDURE usr_users_with_specific_percentage_of_filled_profile_report
	vr_application_id		UUID,
	vr_current_user_id		UUID,
	vr_percentage		 INTEGER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT	x.user_id AS user_id_hide,
			LTRIM(RTRIM(COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N''))) AS full_name,
			x.filled_percentage,
			CASE WHEN x.has_job_title = 1 THEN N'Yes' ELSE N'No' END AS has_job_title_dic,
			x.jobs_count,
			x.schools_count,
			x.courses_count,
			x.honors_count,
			x.languages_count
	FROM (
			SELECT	r.user_id,
					(
						CASE WHEN r.has_job_title > 0 THEN 1 ELSE 0 END +
						CASE WHEN r.jobs_count > 0 THEN 1 ELSE 0 END +
						CASE WHEN r.schools_count > 0 THEN 1 ELSE 0 END +
						CASE WHEN r.courses_count > 0 THEN 1 ELSE 0 END +
						CASE WHEN r.honors_count > 0 THEN 1 ELSE 0 END +
						CASE WHEN r.languages_count > 0 THEN 1 ELSE 0 END
					) * 100 / 6 AS filled_percentage,
					r.has_job_title,
					r.jobs_count,
					r.schools_count,
					r.courses_count,
					r.honors_count,
					r.languages_count
			FROM (
					SELECT	un.user_id,
							CASE WHEN COALESCE(MAX(un.job_title), N'') = N'' THEN 0 ELSE 1 END AS has_job_title,
							COUNT(DISTINCT je.job_id) AS jobs_count,
							COUNT(DISTINCT
								CASE 
									WHEN ee.education_id IS NOT NULL AND ee.is_school = 1 THEN ee.education_id 
									ELSE NULL 
								END
							) AS schools_count,
							COUNT(DISTINCT
								CASE 
									WHEN ee.education_id IS NOT NULL AND ee.is_school = 0 THEN ee.education_id 
									ELSE NULL 
								END
							) AS courses_count,
							COUNT(DISTINCT ha.id) AS honors_count,
							COUNT(DISTINCT ul.id) AS languages_count
					FROM users_normal AS un
						LEFT JOIN usr_job_experiences AS je
						ON je.application_id = vr_application_id AND 
							je.user_id = un.user_id AND je.deleted = FALSE
						LEFT JOIN usr_educational_experiences AS ee
						ON ee.application_id = vr_application_id AND
							ee.user_id = un.user_id AND ee.deleted = FALSE
						LEFT JOIN usr_honors_and_awards AS ha
						ON ha.application_id = vr_application_id AND
							ha.user_id = un.user_id AND ha.deleted = FALSE
						LEFT JOIN usr_user_languages AS ul
						ON ul.application_id = vr_application_id AND
							ul.user_id = un.user_id AND ul.deleted = FALSE
					WHERE un.application_id = vr_application_id AND un.is_approved = TRUE
					GROUP BY un.user_id
				) AS r
		) AS x
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = x.user_id
	WHERE (vr_percentage IS NULL OR x.filled_percentage = vr_percentage)
	ORDER BY x.filled_percentage DESC
	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS usr_resume_job_experience_report;

CREATE PROCEDURE usr_resume_job_experience_report
	vr_application_id	UUID,
	vr_current_user_id	UUID,
	vr_strUserIDs		varchar(max),
	vr_strGroupIDs	varchar(max),
	vr_delimiter		char,
	vr_hierarchy	 BOOLEAN,
	vr_date_from	 TIMESTAMP,
	vr_date_to		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType

	INSERT INTO vr_user_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strUserIDs, vr_delimiter) AS ref

	DECLARE vr_group_ids GuidTableType

	INSERT INTO vr_group_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strGroupIDs, vr_delimiter) AS ref

	IF ((SELECT COUNT(*) FROM vr_group_ids) > 0) AND ((SELECT COUNT(*) FROM vr_user_ids) = 0) BEGIN
		IF COALESCE(vr_hierarchy, 0) = 1 BEGIN
			INSERT INTO vr_user_ids (Value)
			SELECT DISTINCT nm.user_id
			FROM cn_fn_get_child_nodes_deep_hierarchy(vr_application_id, vr_group_ids) AS h
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id and nm.node_id = h.node_id
		END
		ELSE BEGIN
			INSERT INTO vr_user_ids (Value)
			SELECT DISTINCT nm.user_id
			FROM vr_group_ids AS g
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id and nm.node_id = g.value
		END
	END

	DECLARE vr_usersCount INTEGER = (SELECT COUNT(*) FROM vr_user_ids)
	DECLARE vr_groups_count INTEGER = (SELECT COUNT(*) FROM vr_group_ids)

	SELECT	e.user_id AS user_id_hide, 
			LTRIM(RTRIM(COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N''))) AS full_name,
			un.username,
			e.title, 
			e.employer, 
			e.start_date,
			e.end_date
	FROM usr_job_experiences AS e
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = e.user_id
	WHERE e.application_id = vr_application_id AND e.deleted = FALSE AND
		((vr_usersCount = 0 AND vr_groups_count = 0) OR un.user_id IN (SELECT u.value FROM vr_user_ids AS u)) AND
		(vr_usersCount > 0 OR un.is_approved = TRUE) AND
		(vr_date_from IS NULL OR COALESCE(e.start_date, e.end_date) >= vr_date_from) AND
		(vr_date_to IS NULL OR COALESCE(e.start_date, e.end_date) >= vr_date_to)
	ORDER BY e.user_id ASC, COALESCE(e.start_date, e.end_date) ASC, e.end_date ASC
	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS usr_resume_education_report;

CREATE PROCEDURE usr_resume_education_report
	vr_application_id	UUID,
	vr_current_user_id	UUID,
	vr_strUserIDs		varchar(max),
	vr_strGroupIDs	varchar(max),
	vr_delimiter		char,
	vr_hierarchy	 BOOLEAN,
	vr_date_from	 TIMESTAMP,
	vr_date_to		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType

	INSERT INTO vr_user_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strUserIDs, vr_delimiter) AS ref

	DECLARE vr_group_ids GuidTableType

	INSERT INTO vr_group_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strGroupIDs, vr_delimiter) AS ref

	IF ((SELECT COUNT(*) FROM vr_group_ids) > 0) AND ((SELECT COUNT(*) FROM vr_user_ids) = 0) BEGIN
		IF COALESCE(vr_hierarchy, 0) = 1 BEGIN
			INSERT INTO vr_user_ids (Value)
			SELECT DISTINCT nm.user_id
			FROM cn_fn_get_child_nodes_deep_hierarchy(vr_application_id, vr_group_ids) AS h
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id and nm.node_id = h.node_id
		END
		ELSE BEGIN
			INSERT INTO vr_user_ids (Value)
			SELECT DISTINCT nm.user_id
			FROM vr_group_ids AS g
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id and nm.node_id = g.value
		END
	END

	DECLARE vr_usersCount INTEGER = (SELECT COUNT(*) FROM vr_user_ids)
	DECLARE vr_groups_count INTEGER = (SELECT COUNT(*) FROM vr_group_ids)

	SELECT	e.user_id AS user_id_hide, 
			LTRIM(RTRIM(COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N''))) AS full_name,
			un.username,
			e.school, 
			e.study_field, 
			(CASE WHEN e.level = N'None' THEN N'' ELSE e.level END) AS level_dic,
			e.start_date,
			e.end_date
	FROM usr_educational_experiences AS e
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = e.user_id
	WHERE e.application_id = vr_application_id AND e.deleted = FALSE AND e.is_school = 1 AND
		((vr_usersCount = 0 AND vr_groups_count = 0) OR un.user_id IN (SELECT u.value FROM vr_user_ids AS u)) AND
		(vr_usersCount > 0 OR un.is_approved = TRUE) AND
		(vr_date_from IS NULL OR COALESCE(e.start_date, e.end_date) >= vr_date_from) AND
		(vr_date_to IS NULL OR COALESCE(e.start_date, e.end_date) >= vr_date_to)
	ORDER BY e.user_id ASC, COALESCE(e.start_date, e.end_date) ASC, e.end_date ASC
	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS usr_resume_courses_report;

CREATE PROCEDURE usr_resume_courses_report
	vr_application_id	UUID,
	vr_current_user_id	UUID,
	vr_strUserIDs		varchar(max),
	vr_strGroupIDs	varchar(max),
	vr_delimiter		char,
	vr_hierarchy	 BOOLEAN,
	vr_date_from	 TIMESTAMP,
	vr_date_to		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType

	INSERT INTO vr_user_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strUserIDs, vr_delimiter) AS ref

	DECLARE vr_group_ids GuidTableType

	INSERT INTO vr_group_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strGroupIDs, vr_delimiter) AS ref

	IF ((SELECT COUNT(*) FROM vr_group_ids) > 0) AND ((SELECT COUNT(*) FROM vr_user_ids) = 0) BEGIN
		IF COALESCE(vr_hierarchy, 0) = 1 BEGIN
			INSERT INTO vr_user_ids (Value)
			SELECT DISTINCT nm.user_id
			FROM cn_fn_get_child_nodes_deep_hierarchy(vr_application_id, vr_group_ids) AS h
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id and nm.node_id = h.node_id
		END
		ELSE BEGIN
			INSERT INTO vr_user_ids (Value)
			SELECT DISTINCT nm.user_id
			FROM vr_group_ids AS g
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id and nm.node_id = g.value
		END
	END

	DECLARE vr_usersCount INTEGER = (SELECT COUNT(*) FROM vr_user_ids)
	DECLARE vr_groups_count INTEGER = (SELECT COUNT(*) FROM vr_group_ids)

	SELECT	e.user_id AS user_id_hide, 
			LTRIM(RTRIM(COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N''))) AS full_name,
			un.username,
			e.school, 
			e.study_field, 
			e.start_date,
			e.end_date
	FROM usr_educational_experiences AS e
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = e.user_id
	WHERE e.application_id = vr_application_id AND e.deleted = FALSE AND COALESCE(e.is_school, 0) = 0 AND
		((vr_usersCount = 0 AND vr_groups_count = 0) OR un.user_id IN (SELECT u.value FROM vr_user_ids AS u)) AND
		(vr_usersCount > 0 OR un.is_approved = TRUE) AND
		(vr_date_from IS NULL OR COALESCE(e.start_date, e.end_date) >= vr_date_from) AND
		(vr_date_to IS NULL OR COALESCE(e.start_date, e.end_date) >= vr_date_to)
	ORDER BY e.user_id ASC, COALESCE(e.start_date, e.end_date) ASC, e.end_date ASC
	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS usr_resume_honors_report;

CREATE PROCEDURE usr_resume_honors_report
	vr_application_id	UUID,
	vr_current_user_id	UUID,
	vr_strUserIDs		varchar(max),
	vr_strGroupIDs	varchar(max),
	vr_delimiter		char,
	vr_hierarchy	 BOOLEAN,
	vr_date_from	 TIMESTAMP,
	vr_date_to		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType

	INSERT INTO vr_user_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strUserIDs, vr_delimiter) AS ref

	DECLARE vr_group_ids GuidTableType

	INSERT INTO vr_group_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strGroupIDs, vr_delimiter) AS ref

	IF ((SELECT COUNT(*) FROM vr_group_ids) > 0) AND ((SELECT COUNT(*) FROM vr_user_ids) = 0) BEGIN
		IF COALESCE(vr_hierarchy, 0) = 1 BEGIN
			INSERT INTO vr_user_ids (Value)
			SELECT DISTINCT nm.user_id
			FROM cn_fn_get_child_nodes_deep_hierarchy(vr_application_id, vr_group_ids) AS h
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id and nm.node_id = h.node_id
		END
		ELSE BEGIN
			INSERT INTO vr_user_ids (Value)
			SELECT DISTINCT nm.user_id
			FROM vr_group_ids AS g
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id and nm.node_id = g.value
		END
	END

	DECLARE vr_usersCount INTEGER = (SELECT COUNT(*) FROM vr_user_ids)
	DECLARE vr_groups_count INTEGER = (SELECT COUNT(*) FROM vr_group_ids)

	SELECT	e.user_id AS user_id_hide, 
			LTRIM(RTRIM(COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N''))) AS full_name,
			un.username,
			e.title, 
			e.occupation, 
			e.issuer, 
			e.description,
			e.issue_date
	FROM usr_honors_and_awards AS e
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = e.user_id
	WHERE e.application_id = vr_application_id AND e.deleted = FALSE AND
		((vr_usersCount = 0 AND vr_groups_count = 0) OR un.user_id IN (SELECT u.value FROM vr_user_ids AS u)) AND
		(vr_usersCount > 0 OR un.is_approved = TRUE) AND
		(vr_date_from IS NULL OR e.issue_date >= vr_date_from) AND
		(vr_date_to IS NULL OR e.issue_date >= vr_date_to)
	ORDER BY e.user_id ASC, e.issue_date ASC
	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS usr_resume_languages_report;

CREATE PROCEDURE usr_resume_languages_report
	vr_application_id	UUID,
	vr_current_user_id	UUID,
	vr_strUserIDs		varchar(max),
	vr_strGroupIDs	varchar(max),
	vr_delimiter		char,
	vr_hierarchy	 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType

	INSERT INTO vr_user_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strUserIDs, vr_delimiter) AS ref

	DECLARE vr_group_ids GuidTableType

	INSERT INTO vr_group_ids (Value)
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strGroupIDs, vr_delimiter) AS ref

	IF ((SELECT COUNT(*) FROM vr_group_ids) > 0) AND ((SELECT COUNT(*) FROM vr_user_ids) = 0) BEGIN
		IF COALESCE(vr_hierarchy, 0) = 1 BEGIN
			INSERT INTO vr_user_ids (Value)
			SELECT DISTINCT nm.user_id
			FROM cn_fn_get_child_nodes_deep_hierarchy(vr_application_id, vr_group_ids) AS h
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id and nm.node_id = h.node_id
		END
		ELSE BEGIN
			INSERT INTO vr_user_ids (Value)
			SELECT DISTINCT nm.user_id
			FROM vr_group_ids AS g
				INNER JOIN cn_view_node_members AS nm
				ON nm.application_id = vr_application_id and nm.node_id = g.value
		END
	END

	DECLARE vr_usersCount INTEGER = (SELECT COUNT(*) FROM vr_user_ids)
	DECLARE vr_groups_count INTEGER = (SELECT COUNT(*) FROM vr_group_ids)

	SELECT	e.user_id AS user_id_hide, 
			LTRIM(RTRIM(COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N''))) AS full_name,
			un.username,
			l.language_name, 
			e.level AS level_dic
	FROM usr_user_languages AS e
		INNER JOIN usr_language_names AS l
		ON l.application_id = vr_application_id AND l.language_id = l.language_id
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = e.user_id
	WHERE e.application_id = vr_application_id AND e.deleted = FALSE AND
		((vr_usersCount = 0 AND vr_groups_count = 0) OR un.user_id IN (SELECT u.value FROM vr_user_ids AS u)) AND
		(vr_usersCount > 0 OR un.is_approved = TRUE)
	ORDER BY e.user_id ASC, l.language_name ASC
	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'}' +
		   '}') AS actions
END;

DROP PROCEDURE IF EXISTS wf_state_nodes_count_report;

CREATE PROCEDURE wf_state_nodes_count_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_nodeTypeID				UUID,
	vr_workflow_id				UUID,
	vr_lower_creation_date_limit TIMESTAMP,
	vr_upper_creation_date_limit TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT wfs.state_id AS state_id_hide, st.title AS state_title, 
		wfs.workflow_id AS workflow_id_hide, wf.name AS workflow_title, 
		nt.node_type_id AS node_type_id_hide, nt.name AS node_type,
		COALESCE(ref.count, 0) AS count, CAST(st.deleted AS integer) AS removed_state
	FROM (
			SELECT a.state_id, 
				CAST(MAX(CAST(nd.node_type_id AS varchar(36))) AS uuid) AS node_type_id,
				CAST(MAX(CAST(a.workflow_id AS varchar(36))) AS uuid) AS workflow_id,
				COUNT(nd.node_id) AS count
			FROM wf_history AS a
				INNER JOIN (
					SELECT OwnerID, MAX(SendDate) AS send_date
					FROM wf_history
					WHERE ApplicationID = vr_application_id AND deleted = FALSE
					GROUP BY OwnerID
				) AS b
				ON b.owner_id = a.owner_id AND b.send_date = a.send_date
				INNER JOIN cn_nodes AS nd
				ON nd.application_id = vr_application_id AND nd.node_id = a.owner_id
			WHERE a.application_id = vr_application_id AND 
				(vr_workflow_id IS NULL OR a.workflow_id = vr_workflow_id) AND
				(vr_nodeTypeID IS NULL OR nd.node_type_id = vr_nodeTypeID) AND
				(vr_lower_creation_date_limit IS NULL OR nd.creation_date >= vr_lower_creation_date_limit) AND
				(vr_upper_creation_date_limit IS NULL OR nd.creation_date <= vr_upper_creation_date_limit) AND
				 nd.deleted = FALSE
			GROUP BY a.state_id
		) AS ref
		RIGHT JOIN wf_workflow_states AS wfs
		ON wfs.application_id = vr_application_id AND 
			ref.workflow_id = wfs.workflow_id AND wfs.state_id = ref.state_id
		INNER JOIN wf_states AS st
		ON st.application_id = vr_application_id AND st.state_id = wfs.state_id
		INNER JOIN wf_workflows AS wf
		ON wf.application_id = vr_application_id AND wf.workflow_id = ref.workflow_id
		INNER JOIN cn_node_types AS nt
		ON nt.application_id = vr_application_id AND nt.node_type_id = ref.node_type_id
	WHERE wfs.application_id = vr_application_id AND (ref.state_id IS NOT NULL OR wfs.deleted = FALSE)
	
	
	SELECT ('{' +
			'"Count": {"Action": "Report",' + 
		   		'"ModuleIdentifier": "WF", "ReportName": "NodesWorkFlowStatesReport",' +
		   		'"Requires": {"StateID": {"Value": "StateID_Hide", "Title": "StateTitle"}}, ' + 
		   		'"Params": {"CurrentState": true }' + 
		   	'}' +
		   '}') AS actions
END;


DROP PROCEDURE IF EXISTS wf_nodes_workflow_states_report;

CREATE PROCEDURE wf_nodes_workflow_states_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_nodeTypeID				UUID,
	vr_workflow_id				UUID,
	vr_stateID				UUID,
	vr_tag_id					UUID,
	vr_currentState		 BOOLEAN,
	vr_lower_creation_date_limit TIMESTAMP,
	vr_upper_creation_date_limit TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_results Table (
		NodeID_Hide UUID primary key clustered, 
		Name VARCHAR(1000), 
		AdditionalID varchar(1000), 
		Classification VARCHAR(250),
		UserID_Hide UUID, 
		user VARCHAR(1000), 
		UserName VARCHAR(1000), 
		RefStateID_Hide UUID, 
		RefStateTitle VARCHAR(1000), 
		TagID_Hide UUID, 
		Tag VARCHAR(1000), 
		RefDirectorNodeID_Hide UUID, 
		RefDirectorNode VARCHAR(1000), 
		RefDirectorUserID_Hide UUID, 
		RefDirectorName VARCHAR(1000), 
		RefDirectorUserName VARCHAR(1000), 
		EntranceDate TIMESTAMP, 
		RefSenderUserID_Hide UUID, 
		RefSenderName VARCHAR(1000),
		RefSenderUserName VARCHAR(1000),
		StateID_Hide UUID, 
		StateTitle VARCHAR(1000), 
		DirectorNodeID_Hide UUID, 
		DirectorNodeName VARCHAR(1000),
		DirectorUserID_Hide UUID, 
		DirectorName VARCHAR(1000),
		DirectorUserName VARCHAR(1000),
		SendDate TIMESTAMP, 
		SenderUserID_Hide UUID, 
		SenderName VARCHAR(1000),
		SenderUserName VARCHAR(1000)
	)
	
	INSERT INTO vr_results
	SELECT	rpt.node_id AS node_id_hide, 
			nd.name, 
			nd.additional_id, 
			conf.level AS classification,
			un.user_id AS user_id_hide, 
			(un.first_name + N' ' + un.last_name) AS user, 
			un.username, 
			rpt.ref_state_id AS ref_state_id_hide, 
			rs.title AS ref_state_title, 
			rpt.tag_id AS tag_id_hide, 
			tg.tag, 
			rpt.ref_director_node_id AS ref_director_node_id_hide, 
			rdn.name AS ref_director_node, 
			rpt.ref_director_user_id AS ref_director_user_id_hide, 
			(rdu.first_name + N' ' + rdu.last_name) AS ref_director_name, 
			rdu.username AS ref_director_username, 
			rpt.entrance_date, 
			rpt.ref_sender_user_id AS ref_sender_user_id_hide, 
			(rsu.first_name + N' ' + rsu.last_name) AS ref_sender_name,
			rsu.username AS ref_sender_username,
			rpt.state_id AS state_id_hide, 
			st.title AS state_title, 
			rpt.director_node_id AS director_node_id_hide, 
			dn.name AS director_node_name,
			rpt.director_user_id AS director_user_id_hide, 
			(du.first_name + N' ' + du.last_name) AS director_name,
			du.username AS director_username,
			rpt.send_date, 
			rpt.sender_user_id AS sender_user_id_hide, 
			(su.first_name + N' ' + su.last_name) AS sender_name,
			su.username AS sender_username
	FROM (
			SELECT ref.node_id AS node_id, 
				CAST(MAX(CAST(ref.state_id AS varchar(36))) AS uuid) AS ref_state_id,
				CAST(MAX(CAST(ref.tag_id AS varchar(36))) AS uuid) AS tag_id,
				CAST(MAX(CAST(ref.director_node_id AS varchar(36))) AS uuid) AS ref_director_node_id,
				CAST(MAX(CAST(ref.director_user_id AS varchar(36))) AS uuid) AS ref_director_user_id,
				MAX(ref.send_date) AS entrance_date, 
				CAST(MAX(CAST(ref.sender_user_id AS varchar(36))) AS uuid) AS ref_sender_user_id,
				CAST(MAX(CAST(h.state_id AS varchar(36))) AS uuid) AS state_id,
				CAST(MAX(CAST(h.director_node_id AS varchar(36))) AS uuid) AS director_node_id,
				CAST(MAX(CAST(h.director_user_id AS varchar(36))) AS uuid) AS director_user_id,
				MAX(h.send_date) AS send_date,
				CAST(MAX(CAST(h.sender_user_id AS varchar(36))) AS uuid) AS sender_user_id
			FROM (
					SELECT a.owner_id AS node_id, a.workflow_id, a.state_id AS state_id, b.tag_id AS tag_id, 
						a.director_node_id, a.director_user_id, b.send_date, a.sender_user_id
					FROM wf_history AS a
						INNER JOIN (
							SELECT h.owner_id, MAX(h.send_date) AS send_date, 
								CAST(MAX(CAST(wfs.tag_id AS varchar(36))) AS uuid) AS tag_id
							FROM wf_history AS h
								INNER JOIN wf_workflow_states AS wfs
								ON wfs.application_id = vr_application_id AND 
									h.workflow_id = wfs.workflow_id AND wfs.state_id = h.state_id
							WHERE h.application_id = vr_application_id AND 
								(vr_workflow_id IS NULL OR h.workflow_id = vr_workflow_id) AND
								(vr_stateID IS NULL OR h.state_id = vr_stateID) AND
								(vr_tag_id IS NULL OR wfs.tag_id = vr_tag_id) AND h.deleted = FALSE
							GROUP BY h.owner_id
						) AS b
						ON b.owner_id = a.owner_id AND a.send_date = b.send_date
					WHERE a.application_id = vr_application_id
				) AS ref
				LEFT JOIN wf_history AS h
				ON h.application_id = vr_application_id AND h.owner_id = ref.node_id AND 
					h.workflow_id = ref.workflow_id AND h.send_date > ref.send_date
			WHERE (vr_currentState IS NULL OR (vr_currentState = 1 AND h.send_date IS NULL) OR 
				vr_currentState = 0 AND h.send_date IS NOT NULL)
			GROUP BY ref.node_id
		) AS rpt
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = rpt.node_id
		LEFT JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = nd.creator_user_id
		LEFT JOIN wf_states AS rs
		ON rs.application_id = vr_application_id AND rs.state_id = rpt.ref_state_id
		LEFT JOIN cn_tags AS tg
		ON tg.application_id = vr_application_id AND tg.tag_id = rpt.tag_id
		LEFT JOIN cn_nodes AS rdn
		ON rdn.application_id = vr_application_id AND rdn.node_id = rpt.ref_director_node_id
		LEFT JOIN users_normal AS rdu
		ON rdu.application_id = vr_application_id AND rdu.user_id = rpt.ref_director_user_id
		LEFT JOIN users_normal AS rsu
		ON rsu.application_id = vr_application_id AND rsu.user_id = rpt.ref_sender_user_id
		LEFT JOIN wf_states AS st
		ON st.application_id = vr_application_id AND st.state_id = rpt.state_id
		LEFT JOIN cn_nodes AS dn
		ON dn.application_id = vr_application_id AND dn.node_id = rpt.director_node_id
		LEFT JOIN users_normal AS du
		ON du.application_id = vr_application_id AND du.user_id = rpt.director_user_id
		LEFT JOIN users_normal AS su
		ON su.application_id = vr_application_id AND su.user_id = rpt.sender_user_id
		LEFT JOIN prvc_view_confidentialities AS conf
		ON conf.application_id = vr_application_id AND conf.object_id = nd.node_id
	WHERE (vr_nodeTypeID IS NULL OR nd.node_type_id = vr_nodeTypeID) AND
		(vr_lower_creation_date_limit IS NULL OR nd.creation_date >= vr_lower_creation_date_limit) AND
		(vr_upper_creation_date_limit IS NULL OR nd.creation_date <= vr_upper_creation_date_limit) AND
		nd.deleted = FALSE
		
	SELECT *
	FROM vr_results
		
	SELECT ('{' +
			'"Name": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'},' +
			'"User": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'},' +
			'"RefDirectorNode": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "RefDirectorNodeID_Hide"}' +
			'},' +
			'"RefDirectorName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "RefDirectorUserID_Hide"}' +
			'},' +
			'"RefSenderName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "RefSenderUserID_Hide"}' +
			'},' +
			'"DirectorNodeName": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "DirectorNodeID_Hide"}' +
			'},' +
			'"DirectorName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "DirectorUserID_Hide"}' +
			'},' +
			'"SenderName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "SenderUserID_Hide"}' +
			'}' +
		   '}') AS actions
		   
	IF vr_nodeTypeID IS NOT NULL BEGIN
		DECLARE vr_form_id UUID = (
			SELECT TOP(1) FormID
			FROM fg_form_owners
			WHERE ApplicationID = vr_application_id AND OwnerID = vr_nodeTypeID AND deleted = FALSE
		)
		
		IF vr_form_id IS NOT NULL AND EXISTS(
			SELECT TOP(1) *
			FROM cn_extensions AS ex
			WHERE ex.application_id = vr_application_id AND 
				ex.owner_id = vr_nodeTypeID AND ex.extension = N'Form' AND ex.deleted = FALSE
		) BEGIN
			-- Second Part: Describes the Third Part
			SELECT CAST(efe.element_id AS varchar(50)) AS column_name, efe.title AS translation,
				CASE
					WHEN efe.type = N'Binary' THEN N'bool'
					WHEN efe.type = N'Number' THEN N'double'
					WHEN efe.type = N'Date' THEN N'datetime'
					WHEN efe.type = N'User' THEN N'user'
					WHEN efe.type = N'Node' THEN N'node'
					ELSE N'string'
				END AS type
			FROM fg_extended_form_elements AS efe
			WHERE efe.application_id = vr_application_id AND 
				efe.form_id = vr_form_id AND efe.deleted = FALSE
			ORDER BY efe.sequence_number ASC
			
			SELECT ('{"IsDescription": "true"}') AS info
			-- end of Second Part
			
			-- Third Part: The Form Info
			DECLARE vr_node_ids GuidTableType
			
			INSERT INTO vr_node_ids (Value)
			SELECT r.node_id_hide
			FROM vr_results AS r
			
			DECLARE vr_element_ids GuidTableType
			
			DECLARE vr_fake_instances GuidTableType
			DECLARE vr_fake_filters FormFilterTableType
			
			EXEC fg_p_get_form_records vr_application_id, vr_form_id, 
				vr_element_ids, vr_fake_instances, vr_node_ids, 
				vr_fake_filters, NULL, 1000000, NULL, NULL
			
			SELECT ('{' +
				'"ColumnsMap": "NodeID_Hide:OwnerID",' +
				'"ColumnsToTransfer": "' + STUFF((
					SELECT ',' + CAST(efe.element_id AS varchar(50))
					FROM fg_extended_form_elements AS efe
					WHERE efe.application_id = vr_application_id AND 
						efe.form_id = vr_form_id AND efe.deleted = FALSE
					ORDER BY efe.sequence_number ASC
					FOR xml path('a'), type
				).value('.','nvarchar(max)'), 1, 1, '') + '"' +
			   '}') AS info
			-- End of Third Part
		END
	END
END;


DROP PROCEDURE IF EXISTS kw_knowledge_admins_report;

CREATE PROCEDURE kw_knowledge_admins_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_now				 TIMESTAMP,
    vr_knowledge_type_id		UUID,
	vr_strUserIDs				varchar(max),
	vr_delimiter				char,
	vr_member_in_node_type_id		UUID,
	vr_sendDateFrom		 TIMESTAMP,
	vr_sendDateTo			 TIMESTAMP,
	vr_actionDateFrom		 TIMESTAMP,
	vr_actionDateTo		 TIMESTAMP,
	vr_delay_from			 INTEGER,
	vr_delay_to			 INTEGER,
	vr_seen				 BOOLEAN,
	vr_done				 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType
	
	INSERT INTO vr_user_ids
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strUserIDs, vr_delimiter) AS ref
	
	IF vr_delay_from IS NOT NULL AND vr_delay_from < 0 SET vr_delay_from = NULL
	ELSE SET vr_delay_from = vr_delay_from * 24 * 60 * 60

	IF vr_delay_to IS NOT NULL AND vr_delay_to < 0 SET vr_delay_to = NULL
	ELSE SET vr_delay_to = vr_delay_to * 24 * 60 * 60

	DECLARE vr_has_target_users BOOLEAN = 0
	IF (SELECT COUNT(*) FROM vr_user_ids) > 0 OR vr_member_in_node_type_id IS NOT NULL 
		SET vr_has_target_users = 1

	DECLARE vr_target_user_ids GuidTableType

	INSERT INTO vr_target_user_ids (Value)
	SELECT DISTINCT x.user_id
	FROM (
			SELECT Value AS user_id
			FROM vr_user_ids
			
			UNION ALL
			
			SELECT nm.user_id
			FROM cn_view_node_members AS nm
			WHERE vr_member_in_node_type_id IS NOT NULL AND nm.application_id = vr_application_id AND
				nm.node_type_id = vr_member_in_node_type_id AND nm.is_pending = FALSE
		) AS x
		

	SELECT	d.user_id AS user_id_hide,
			MAX(un.first_name + N' ' + un.last_name) AS full_name,
			COUNT(d.id) AS items_count,
			SUM(CASE WHEN d.deleted = FALSE AND d.action_date IS NULL THEN 1 ELSE 0 END) AS pending_count,
			SUM(CASE WHEN d.action_date IS NULL THEN 0 ELSE 1 END) AS done_count,
			SUM(CASE WHEN d.seen = 0 THEN 1 ELSE 0 END) AS not_seen_count, 
			AVG(
				CASE
					WHEN d.action_date IS NULL THEN NULL
					ELSE COALESCE(CAST(DATEDIFF(second, d.send_date, d.action_date) AS float) / (24 * 3600), 0)
				END
			) AS done_delay_average, 
			MIN(
				CASE
					WHEN d.action_date IS NULL THEN 0
					ELSE COALESCE(CAST(DATEDIFF(second, d.send_date, d.action_date) AS float) / (24 * 3600), 0)
				END
			) AS done_delay_min, 
			MAX(
				CASE
					WHEN d.action_date IS NULL THEN 0
					ELSE COALESCE(CAST(DATEDIFF(second, d.send_date, d.action_date) AS float) / (24 * 3600), 0)
				END
			) AS done_delay_max,
			AVG(
				CASE
					WHEN d.action_date IS NOT NULL OR d.deleted = TRUE THEN NULL
					ELSE COALESCE(CAST(DATEDIFF(second, d.send_date, vr_now) AS float) / (24 * 3600), 0)
				END
			) AS not_done_delay_average, 
			MIN(
				CASE
					WHEN d.action_date IS NOT NULL OR d.deleted = TRUE THEN 0
					ELSE COALESCE(CAST(DATEDIFF(second, d.send_date, vr_now) AS float) / (24 * 3600), 0)
				END
			) AS not_done_delay_min, 
			MAX(
				CASE
					WHEN d.action_date IS NOT NULL OR d.deleted = TRUE THEN 0
					ELSE COALESCE(CAST(DATEDIFF(second, d.send_date, vr_now) AS float) / (24 * 3600), 0)
				END
			) AS not_done_delay_max
	FROM vr_target_user_ids AS t
		RIGHT JOIN ntfn_dashboards AS d
		ON d.application_id = vr_application_id AND d.user_id = t.value
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = d.node_id AND
			(vr_knowledge_type_id IS NULL OR nd.node_type_id = vr_knowledge_type_id)
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = d.user_id
	WHERE d.application_id = vr_application_id AND (vr_has_target_users = 0 OR t.value IS NOT NULL) AND
		d.type = N'Knowledge' AND d.subtype = N'Admin' AND
		(vr_sendDateFrom IS NULL OR d.send_date >= vr_sendDateFrom) AND
		(vr_sendDateTo IS NULL OR d.send_date <= vr_sendDateTo) AND
		(vr_actionDateFrom IS NULL OR d.action_date >= vr_actionDateFrom) AND
		(vr_actionDateTo IS NULL OR d.action_date <= vr_actionDateTo) AND
		(vr_delay_from IS NULL OR 
			DATEDIFF(second, d.send_date, COALESCE(d.action_date, vr_now)) >= vr_delay_from) AND
		(vr_delay_to IS NULL OR 
			DATEDIFF(second, d.send_date, COALESCE(d.action_date, vr_now)) <= vr_delay_to) AND
		(vr_done IS NULL OR ((vr_done = 1 OR d.deleted = FALSE) AND d.done = vr_done)) AND
		(vr_seen IS NULL OR d.seen = vr_seen)
	GROUP BY d.user_id

	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"ID": "UserID_Hide"}' +
			'},' +
			'"PendingCount": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "KW", "ReportName": "KnowledgeAdminsDetailReport",' +
		   		'"Requires":{"UserID":{"Value": "UserID_Hide", "Title": "FullName"}},' +
		   		'"Params": {"Done": "false"}' + 
		   	'},' +
		   	'"DoneCount": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "KW", "ReportName": "KnowledgeAdminsDetailReport",' +
		   		'"Requires":{"UserID":{"Value": "UserID_Hide", "Title": "FullName"}},' +
		   		'"Params": {"Done": "true"}' + 
		   	'},' +
		   	'"NotSeenCount": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "KW", "ReportName": "KnowledgeAdminsDetailReport",' +
		   		'"Requires":{"UserID":{"Value": "UserID_Hide", "Title": "FullName"}},' +
		   		'"Params": {"Seen": "false"}' + 
		   	'}' +
		   '}') AS actions

END;


DROP PROCEDURE IF EXISTS kw_knowledge_admins_detail_report;

CREATE PROCEDURE kw_knowledge_admins_detail_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_now				 TIMESTAMP,
	vr_knowledge_id			UUID,
    vr_knowledge_type_id		UUID,
	vr_strUserIDs				varchar(max),
	vr_delimiter				char,
	vr_member_in_node_type_id		UUID,
	vr_sendDateFrom		 TIMESTAMP,
	vr_sendDateTo			 TIMESTAMP,
	vr_actionDateFrom		 TIMESTAMP,
	vr_actionDateTo		 TIMESTAMP,
	vr_delay_from			 INTEGER,
	vr_delay_to			 INTEGER,
	vr_seen				 BOOLEAN,
	vr_done				 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType

	INSERT INTO vr_user_ids
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strUserIDs, vr_delimiter) AS ref

	IF vr_delay_from IS NOT NULL AND vr_delay_from < 0 SET vr_delay_from = NULL
	ELSE SET vr_delay_from = vr_delay_from * 24 * 60 * 60

	IF vr_delay_to IS NOT NULL AND vr_delay_to < 0 SET vr_delay_to = NULL
	ELSE SET vr_delay_to = vr_delay_to * 24 * 60 * 60

	DECLARE vr_has_target_users BOOLEAN = 0
	IF (SELECT COUNT(*) FROM vr_user_ids) > 0 OR vr_member_in_node_type_id IS NOT NULL 
		SET vr_has_target_users = 1

	DECLARE vr_target_user_ids GuidTableType

	INSERT INTO vr_target_user_ids (Value)
	SELECT DISTINCT x.user_id
	FROM (
			SELECT Value AS user_id
			FROM vr_user_ids
			
			UNION ALL
			
			SELECT nm.user_id
			FROM cn_view_node_members AS nm
			WHERE vr_member_in_node_type_id IS NOT NULL AND nm.application_id = vr_application_id AND
				nm.node_type_id = vr_member_in_node_type_id AND nm.is_pending = FALSE
		) AS x
		

	SELECT	nd.node_id AS node_id_hide,
			nd.node_name,
			nd.type_name AS node_type,
			d.user_id AS user_id_hide,
			un.first_name + N' ' + un.last_name AS full_name,
			d.send_date,
			d.action_date,
			CASE
				WHEN d.deleted = FALSE AND d.action_date IS NULL THEN N'Pending'
				WHEN d.action_date IS NOT NULL THEN N'Done'
				ELSE N''
			END AS done_status_dic,
			CASE WHEN d.seen = 0 THEN N'Seen' ELSE N'NotSeen' END AS seen_status_dic, 
			CASE
				WHEN d.deleted IS NULL THEN 0
				ELSE COALESCE(CAST(DATEDIFF(second, d.send_date, COALESCE(d.action_date, vr_now)) AS integer) / (24 * 3600), 0)
			END AS action_delay
	FROM vr_target_user_ids AS t
		RIGHT JOIN ntfn_dashboards AS d
		ON d.application_id = vr_application_id AND d.user_id = t.value
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = d.node_id AND
			(vr_knowledge_type_id IS NULL OR nd.node_type_id = vr_knowledge_type_id)
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = d.user_id
	WHERE d.application_id = vr_application_id AND (vr_has_target_users = 0 OR t.value IS NOT NULL) AND
		d.type = N'Knowledge' AND d.subtype = N'Admin' AND
		(vr_sendDateFrom IS NULL OR d.send_date >= vr_sendDateFrom) AND
		(vr_sendDateTo IS NULL OR d.send_date <= vr_sendDateTo) AND
		(vr_actionDateFrom IS NULL OR d.action_date >= vr_actionDateFrom) AND
		(vr_actionDateTo IS NULL OR d.action_date <= vr_actionDateTo) AND
		(vr_delay_from IS NULL OR (d.deleted = FALSE AND
			DATEDIFF(second, d.send_date, COALESCE(d.action_date, vr_now)) >= vr_delay_from)) AND
		(vr_delay_to IS NULL OR  (d.deleted = FALSE AND
			DATEDIFF(second, d.send_date, COALESCE(d.action_date, vr_now)) <= vr_delay_to)) AND
		(vr_done IS NULL OR ((vr_done = 1 OR d.deleted = FALSE) AND d.done = vr_done)) AND
		(vr_seen IS NULL OR d.seen = vr_seen) AND
		(vr_knowledge_id IS NULL OR nd.node_id = vr_knowledge_id)

	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"ID": "UserID_Hide"}' +
			'},' +
			'"NodeName": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'}' +
		   '}') AS actions

END;


DROP PROCEDURE IF EXISTS kw_knowledge_evaluations_report;

CREATE PROCEDURE kw_knowledge_evaluations_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_now				 TIMESTAMP,
    vr_knowledge_type_id		UUID,
	vr_strUserIDs				varchar(max),
	vr_delimiter				char,
	vr_member_in_node_type_id		UUID,
	vr_sendDateFrom		 TIMESTAMP,
	vr_sendDateTo			 TIMESTAMP,
	vr_actionDateFrom		 TIMESTAMP,
	vr_actionDateTo		 TIMESTAMP,
	vr_delay_from			 INTEGER,
	vr_delay_to			 INTEGER,
	vr_seen				 BOOLEAN,
	vr_done				 BOOLEAN,
	vr_canceled			 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType
	
	INSERT INTO vr_user_ids
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strUserIDs, vr_delimiter) AS ref
	
	IF vr_delay_from IS NOT NULL AND vr_delay_from < 0 SET vr_delay_from = NULL
	ELSE SET vr_delay_from = vr_delay_from * 24 * 60 * 60

	IF vr_delay_to IS NOT NULL AND vr_delay_to < 0 SET vr_delay_to = NULL
	ELSE SET vr_delay_to = vr_delay_to * 24 * 60 * 60

	DECLARE vr_has_target_users BOOLEAN = 0
	IF (SELECT COUNT(*) FROM vr_user_ids) > 0 OR vr_member_in_node_type_id IS NOT NULL 
		SET vr_has_target_users = 1

	DECLARE vr_target_user_ids GuidTableType

	INSERT INTO vr_target_user_ids (Value)
	SELECT DISTINCT x.user_id
	FROM (
			SELECT Value AS user_id
			FROM vr_user_ids
			
			UNION ALL
			
			SELECT nm.user_id
			FROM cn_view_node_members AS nm
			WHERE vr_member_in_node_type_id IS NOT NULL AND nm.application_id = vr_application_id AND
				nm.node_type_id = vr_member_in_node_type_id AND nm.is_pending = FALSE
		) AS x
		

	SELECT	d.user_id AS user_id_hide,
			MAX(un.first_name + N' ' + un.last_name) AS full_name,
			COUNT(d.id) AS items_count,
			SUM(CASE WHEN d.deleted = FALSE AND d.action_date IS NULL THEN 1 ELSE 0 END) AS pending_count,
			SUM(CASE WHEN d.action_date IS NULL THEN 0 ELSE 1 END) AS evaluations_count,
			SUM(CASE WHEN d.deleted = TRUE THEN 1 ELSE 0 END) AS canceled_count,
			SUM(CASE WHEN d.seen = 0 THEN 1 ELSE 0 END) AS not_seen_count, 
			AVG(
				CASE
					WHEN d.action_date IS NULL THEN NULL
					ELSE COALESCE(CAST(DATEDIFF(second, d.send_date, d.action_date) AS float) / (24 * 3600), 0)
				END
			) AS done_delay_average, 
			MIN(
				CASE
					WHEN d.action_date IS NULL THEN 0
					ELSE COALESCE(CAST(DATEDIFF(second, d.send_date, d.action_date) AS float) / (24 * 3600), 0)
				END
			) AS done_delay_min, 
			MAX(
				CASE
					WHEN d.action_date IS NULL THEN 0
					ELSE COALESCE(CAST(DATEDIFF(second, d.send_date, d.action_date) AS float) / (24 * 3600), 0)
				END
			) AS done_delay_max,
			AVG(
				CASE
					WHEN d.action_date IS NOT NULL OR d.deleted = TRUE THEN NULL
					ELSE COALESCE(CAST(DATEDIFF(second, d.send_date, vr_now) AS float) / (24 * 3600), 0)
				END
			) AS not_done_delay_average, 
			MIN(
				CASE
					WHEN d.action_date IS NOT NULL OR d.deleted = TRUE THEN 0
					ELSE COALESCE(CAST(DATEDIFF(second, d.send_date, vr_now) AS float) / (24 * 3600), 0)
				END
			) AS not_done_delay_min, 
			MAX(
				CASE
					WHEN d.action_date IS NOT NULL OR d.deleted = TRUE THEN 0
					ELSE COALESCE(CAST(DATEDIFF(second, d.send_date, vr_now) AS float) / (24 * 3600), 0)
				END
			) AS not_done_delay_max
	FROM vr_target_user_ids AS t
		RIGHT JOIN ntfn_dashboards AS d
		ON d.application_id = vr_application_id AND d.user_id = t.value
		INNER JOIN cn_nodes AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = d.node_id AND
			(vr_knowledge_type_id IS NULL OR nd.node_type_id = vr_knowledge_type_id)
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = d.user_id
	WHERE d.application_id = vr_application_id AND (vr_has_target_users = 0 OR t.value IS NOT NULL) AND
		d.type = N'Knowledge' AND d.subtype = N'Evaluator' AND
		(vr_sendDateFrom IS NULL OR d.send_date >= vr_sendDateFrom) AND
		(vr_sendDateTo IS NULL OR d.send_date <= vr_sendDateTo) AND
		(vr_actionDateFrom IS NULL OR d.action_date >= vr_actionDateFrom) AND
		(vr_actionDateTo IS NULL OR d.action_date <= vr_actionDateTo) AND
		(vr_delay_from IS NULL OR 
			DATEDIFF(second, d.send_date, COALESCE(d.action_date, vr_now)) >= vr_delay_from) AND
		(vr_delay_to IS NULL OR 
			DATEDIFF(second, d.send_date, COALESCE(d.action_date, vr_now)) <= vr_delay_to) AND
		(vr_done IS NULL OR ((vr_done = 1 OR d.deleted = FALSE) AND d.done = vr_done)) AND
		(vr_seen IS NULL OR d.seen = vr_seen) AND
		(vr_canceled IS NULL OR d.deleted = vr_canceled)
	GROUP BY d.user_id

	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"ID": "UserID_Hide"}' +
			'},' +
			'"PendingCount": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "KW", "ReportName": "KnowledgeEvaluationsDetailReport",' +
		   		'"Requires":{"UserID":{"Value": "UserID_Hide", "Title": "FullName"}},' +
		   		'"Params": {"Done": "false"}' + 
		   	'},' +
		   	'"EvaluationsCount": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "KW", "ReportName": "KnowledgeEvaluationsDetailReport",' +
		   		'"Requires":{"UserID":{"Value": "UserID_Hide", "Title": "FullName"}},' +
		   		'"Params": {"Done": "true"}' + 
		   	'},' +
		   	'"CanceledCount": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "KW", "ReportName": "KnowledgeEvaluationsDetailReport",' +
		   		'"Requires":{"UserID":{"Value": "UserID_Hide", "Title": "FullName"}},' +
		   		'"Params": {"Canceled": "true"}' + 
		   	'},' +
		   	'"NotSeenCount": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "KW", "ReportName": "KnowledgeEvaluationsDetailReport",' +
		   		'"Requires":{"UserID":{"Value": "UserID_Hide", "Title": "FullName"}},' +
		   		'"Params": {"Seen": "false"}' + 
		   	'}' +
		   '}') AS actions

END;


DROP PROCEDURE IF EXISTS kw_knowledge_evaluations_detail_report;

CREATE PROCEDURE kw_knowledge_evaluations_detail_report
	vr_application_id			UUID,
	vr_current_user_id			UUID,
	vr_now				 TIMESTAMP,
	vr_knowledge_id			UUID,
    vr_knowledge_type_id		UUID,
	vr_strUserIDs				varchar(max),
	vr_delimiter				char,
	vr_member_in_node_type_id		UUID,
	vr_sendDateFrom		 TIMESTAMP,
	vr_sendDateTo			 TIMESTAMP,
	vr_actionDateFrom		 TIMESTAMP,
	vr_actionDateTo		 TIMESTAMP,
	vr_delay_from			 INTEGER,
	vr_delay_to			 INTEGER,
	vr_seen				 BOOLEAN,
	vr_done				 BOOLEAN,
	vr_canceled			 BOOLEAN
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType

	INSERT INTO vr_user_ids
	SELECT ref.value
	FROM gfn_str_to_guid_table(vr_strUserIDs, vr_delimiter) AS ref

	IF vr_delay_from IS NOT NULL AND vr_delay_from < 0 SET vr_delay_from = NULL
	ELSE SET vr_delay_from = vr_delay_from * 24 * 60 * 60

	IF vr_delay_to IS NOT NULL AND vr_delay_to < 0 SET vr_delay_to = NULL
	ELSE SET vr_delay_to = vr_delay_to * 24 * 60 * 60

	DECLARE vr_has_target_users BOOLEAN = 0
	IF (SELECT COUNT(*) FROM vr_user_ids) > 0 OR vr_member_in_node_type_id IS NOT NULL 
		SET vr_has_target_users = 1

	DECLARE vr_target_user_ids GuidTableType

	INSERT INTO vr_target_user_ids (Value)
	SELECT DISTINCT x.user_id
	FROM (
			SELECT Value AS user_id
			FROM vr_user_ids
			
			UNION ALL
			
			SELECT nm.user_id
			FROM cn_view_node_members AS nm
			WHERE vr_member_in_node_type_id IS NOT NULL AND nm.application_id = vr_application_id AND
				nm.node_type_id = vr_member_in_node_type_id AND nm.is_pending = FALSE
		) AS x
		

	SELECT	nd.node_id AS node_id_hide,
			nd.node_name,
			nd.type_name AS node_type,
			d.user_id AS user_id_hide,
			un.first_name + N' ' + un.last_name AS full_name,
			d.send_date,
			d.action_date,
			CASE
				WHEN d.deleted = FALSE AND d.action_date IS NULL THEN N'Pending'
				WHEN d.deleted = TRUE THEN N'Canceled'
				WHEN d.action_date IS NOT NULL THEN N'Done'
				ELSE N''
			END AS evaluation_status_dic,
			CASE WHEN d.seen = 0 THEN N'Seen' ELSE N'NotSeen' END AS seen_status_dic, 
			CASE
				WHEN d.deleted IS NULL THEN 0
				ELSE COALESCE(CAST(DATEDIFF(second, d.send_date, COALESCE(d.action_date, vr_now)) AS integer) / (24 * 3600), 0)
			END AS evaluation_delay
	FROM vr_target_user_ids AS t
		RIGHT JOIN ntfn_dashboards AS d
		ON d.application_id = vr_application_id AND d.user_id = t.value
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = d.node_id AND
			(vr_knowledge_type_id IS NULL OR nd.node_type_id = vr_knowledge_type_id)
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = d.user_id
	WHERE d.application_id = vr_application_id AND (vr_has_target_users = 0 OR t.value IS NOT NULL) AND
		d.type = N'Knowledge' AND d.subtype = N'Evaluator' AND
		(vr_sendDateFrom IS NULL OR d.send_date >= vr_sendDateFrom) AND
		(vr_sendDateTo IS NULL OR d.send_date <= vr_sendDateTo) AND
		(vr_actionDateFrom IS NULL OR d.action_date >= vr_actionDateFrom) AND
		(vr_actionDateTo IS NULL OR d.action_date <= vr_actionDateTo) AND
		(vr_delay_from IS NULL OR (d.deleted = FALSE AND
			DATEDIFF(second, d.send_date, COALESCE(d.action_date, vr_now)) >= vr_delay_from)) AND
		(vr_delay_to IS NULL OR  (d.deleted = FALSE AND
			DATEDIFF(second, d.send_date, COALESCE(d.action_date, vr_now)) <= vr_delay_to)) AND
		(vr_done IS NULL OR ((vr_done = 1 OR d.deleted = FALSE) AND d.done = vr_done)) AND
		(vr_seen IS NULL OR d.seen = vr_seen) AND
		(vr_canceled IS NULL OR d.deleted = vr_canceled) AND
		(vr_knowledge_id IS NULL OR nd.node_id = vr_knowledge_id)

	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"ID": "UserID_Hide"}' +
			'},' +
			'"NodeName": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'}' +
		   '}') AS actions

END;


DROP PROCEDURE IF EXISTS kw_knowledge_evaluations_history_report;

CREATE PROCEDURE kw_knowledge_evaluations_history_report
	vr_application_id		UUID,
	vr_current_user_id		UUID,
	vr_knowledge_type_id	UUID,
	vr_knowledge_id		UUID,
	vr_strUserIDs			varchar(max),
	vr_delimiter			char,
	vr_date_from		 TIMESTAMP,
	vr_date_to			 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType
	
	INSERT INTO vr_user_ids (Value)
	SELECT DISTINCT ref.value
	FROM gfn_str_to_guid_table(vr_strUserIDs, vr_delimiter) AS ref
	
	DECLARE vr_usersIDsCount INTEGER = (SELECT COUNT(*) FROM vr_user_ids)
	
	DECLARE vr_last_versions TABLE (KnowledgeID UUID primary key clustered, LastVersionID INTEGER)

	INSERT INTO vr_last_versions (KnowledgeID, LastVersionID)
	SELECT h.knowledge_id, MAX(h.wf_version_id) AS last_version_id
	FROM kw_history AS h
	GROUP BY h.knowledge_id


	DECLARE vr_ret TABLE (
		NodeID_Hide UUID, 
		NodeName VARCHAR(1000), 
		NodeAdditionalID VARCHAR(100),
		NodeType VARCHAR(200),
		CreatorUserID_Hide UUID,
		CreatorFullName VARCHAR(200),
		CreatorUserName VARCHAR(100),
		Status_Dic VARCHAR(100),
		EvaluatorUserID_Hide UUID,
		EvaluatorFullName VARCHAR(200),
		EvaluatorUserName VARCHAR(100),
		Score float,
		EvaluationDate TIMESTAMP,
		WFVersionID INTEGER,
		description VARCHAR(max),
		Reasons VARCHAR(1000)
	)


	INSERT INTO vr_ret (NodeID_Hide, NodeName, NodeAdditionalID, NodeType, CreatorUserID_Hide, CreatorUserName, CreatorFullName, 
		Status_Dic, EvaluatorUserID_Hide, EvaluatorUserName, EvaluatorFullName, Score, EvaluationDate, WFVersionID, 
		description, Reasons)
	SELECT	nd.node_id, nd.node_name, nd.node_additional_id, nd.type_name, un.user_id, un.username, 
		LTRIM(RTRIM(COALESCE(un.first_name, N'') + N' ' + COALESCE(un.last_name, N''))),
		nd.status, x.evaluator_user_id, x.evaluator_username,
		LTRIM(RTRIM(COALESCE(x.evaluator_first_name, N'') + N' ' + COALESCE(x.evaluator_last_name, N''))),
		x.score, x.evaluation_date, x.wf_version_id, h.description, h.text_options
	FROM (
			SELECT	ref.knowledge_id,
					ref.user_id AS evaluator_user_id,
					un.username AS evaluator_username,
					un.first_name AS evaluator_first_name,
					un.last_name AS evaluator_last_name,
					ref.score,
					ref.evaluation_date,
					lv.last_version_id AS wf_version_id
			FROM (
					SELECT	a.knowledge_id, 
							a.user_id, 
							(SUM(COALESCE(COALESCE(a.admin_score, a.score), 0)) / COALESCE(COUNT(a.user_id), 1)) AS score,
							MAX(a.evaluation_date) AS evaluation_date
					FROM kw_question_answers AS a
					WHERE a.application_id = vr_application_id AND a.deleted = FALSE AND
						(vr_date_from IS NULL OR a.evaluation_date > vr_date_from) AND
						(vr_date_to IS NULL OR a.evaluation_date <= vr_date_to)
					GROUP BY a.knowledge_id, a.user_id
				) AS ref
				INNER JOIN vr_last_versions AS lv
				ON lv.knowledge_id = ref.knowledge_id
				INNER JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = ref.user_id AND
					(vr_usersIDsCount = 0 OR un.user_id IN (SELECT Value FROM vr_user_ids))

			UNION ALL

			SELECT	ref.knowledge_id,
					ref.user_id,
					un.username,
					un.first_name,
					un.last_name,
					ref.score,
					ref.evaluation_date,
					ref.wf_version_id
			FROM (
					SELECT a.knowledge_id, a.user_id, (SUM(COALESCE(COALESCE(a.admin_score, a.score), 0)) / COALESCE(COUNT(a.user_id), 1)) AS score,
						MAX(a.evaluation_date) AS evaluation_date, a.wf_version_id
					FROM kw_question_answers_history AS a
					WHERE a.application_id = vr_application_id AND a.deleted = FALSE AND
						(vr_date_from IS NULL OR a.evaluation_date > vr_date_from) AND
						(vr_date_to IS NULL OR a.evaluation_date <= vr_date_to)
					GROUP BY a.knowledge_id, a.user_id, a.wf_version_id
				) AS ref
				INNER JOIN users_normal AS un
				ON un.application_id = vr_application_id AND un.user_id = ref.user_id AND
					(vr_usersIDsCount = 0 OR un.user_id IN (SELECT Value FROM vr_user_ids))
		) AS x
		INNER JOIN cn_view_nodes_normal AS nd
		ON nd.application_id = vr_application_id AND nd.node_id = x.knowledge_id AND
			(vr_knowledge_type_id IS NULL OR nd.node_type_id = vr_knowledge_type_id) AND
			(vr_knowledge_id IS NULL OR nd.node_id = vr_knowledge_id)
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = nd.creator_user_id
		LEFT JOIN kw_history AS h
		ON h.application_id = vr_application_id AND h.knowledge_id = x.knowledge_id AND 
			h.actor_user_id = x.evaluator_user_id AND h.action_date = x.evaluation_date
	ORDER BY x.evaluation_date DESC, x.knowledge_id DESC, x.wf_version_id DESC

	SELECT *
	FROM vr_ret


	SELECT ('{' +
			'"NodeName": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'},' +
			'"CreatorFullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "CreatorUserID_Hide"}' +
			'},' +
			'"EvaluatorFullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "EvaluatorUserID_Hide"}' +
			'},' +
			'"Contributor": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "ContributorID_Hide"}' +
			'}' +
		   '}') AS actions
		   
	   
	-- Add Contributor Columns

	DECLARE vr_proc VARCHAR(max) = N''

	SELECT x.*
	INTO #Result
	FROM (
			SELECT	c.node_id, 
					CAST(c.user_id AS varchar(50)) AS unq,
					c.user_id, 
					c.collaboration_share AS share,
					ROW_NUMBER() OVER (PARTITION BY c.node_id ORDER BY c.collaboration_share DESC, c.user_id DESC) AS row_number
			FROM vr_ret AS i_ds
				INNER JOIN cn_node_creators AS c
				ON c.application_id = vr_application_id AND c.node_id = i_ds.node_id_hide AND c.deleted = FALSE
		) AS x
		
	DECLARE vr_count INTEGER = (SELECT MAX(RowNumber) FROM #Result)
	DECLARE vr_itemsList varchar(max) = N'', vr_selectList varchar(max) = N'', vr_cols_to_transfer varchar(max) = N''

	SET vr_proc = N''

	DECLARE vr_ind INTEGER = vr_count - 1
	WHILE vr_ind >= 0 BEGIN
		DECLARE vr_tmp varchar(10) = CAST((vr_count - vr_ind) AS varchar(10))
		
		SET vr_selectList = vr_selectList + '[' + vr_tmp + '] AS contributor_id_hide_' + vr_tmp + '], ' + 
			'CAST(NULL AS varchar(500)) AS contributor_' + vr_tmp + '], ' +
			'CAST(NULL AS float) AS contributor_share_' + vr_tmp + ']'
			
		SET vr_itemsList = vr_itemsList + '[' + vr_tmp + ']'
		
		SET vr_proc = vr_proc + 
			'SELECT ''ContributorID_Hide_' + vr_tmp + ''' AS column_name, null AS translation, ''string'' AS type ' +
			'UNION ALL ' +
			'SELECT ''Contributor_' + vr_tmp + ''' AS column_name, null AS translation, ''string'' AS type ' +
			'UNION ALL ' +
			'SELECT ''ContributorShare_' + vr_tmp + ''' AS column_name, null AS translation, ''double'' AS type '
			
		SET vr_cols_to_transfer = vr_cols_to_transfer + 
			'ContributorID_Hide_' + vr_tmp + ',Contributor_' + vr_tmp + ',ContributorShare_' + vr_tmp
		
		IF vr_ind > 0 BEGIN 
			SET vr_selectList = vr_selectList + ', '
			SET vr_itemsList = vr_itemsList + ', '
			SET vr_proc = vr_proc + N'UNION ALL '
			SET vr_cols_to_transfer = vr_cols_to_transfer + ','
		END
		
		SET vr_ind = vr_ind - 1
	END

	-- Second Part: Describes the Third Part
	EXEC (vr_proc)

	SELECT ('{"IsDescription": "true"}') AS info
	-- end of Second Part

	-- Third Part: The Data
	SET vr_proc = 
		'SELECT NodeID AS node_id_hide, ' + vr_selectList + 
		'INTO #Final ' +
		'FROM ( ' +
				'SELECT NodeID, unq, RowNumber ' +
				'FROM #Result ' +
			') AS p ' +
			'PIVOT (MAX(unq) FOR RowNumber IN (' + vr_itemsList + ')) AS pvt '

	SET vr_ind = vr_count - 1
	WHILE vr_ind >= 0 BEGIN
		DECLARE vr_no varchar(10) = CAST((vr_count - vr_ind) AS varchar(10))
		
		SET vr_proc = vr_proc + 
			'UPDATE F ' + 
				'SET Contributor_' + vr_no + ' = LTRIM(RTRIM(COALESCE(un.first_name, N'''') + N'' '' + COALESCE(un.last_name, N''''))) ' + 
			'FROM #Final AS f ' + 
				'INNER JOIN users_normal AS un ' + 
				'ON un.application_id = ''' + CAST(vr_application_id AS varchar(50)) + ''' AND un.user_id = f.contributor_id_hide_' + vr_no + ' '
				
		SET vr_proc = vr_proc + 
			'UPDATE F ' + 
				'SET ContributorShare_' + vr_no + ' = r.share ' + 
			'FROM #Final AS f ' + 
				'INNER JOIN #Result AS r ' + 
				'ON r.node_id = f.node_id_hide AND r.user_id = f.contributor_id_hide_' + vr_no + ' '
		
		SET vr_ind = vr_ind - 1
	END

	SET vr_proc = vr_proc + 'SELECT * FROM #Final'

	EXEC (vr_proc)

	SELECT ('{' +
			'"ColumnsMap": "NodeID_Hide:NodeID_Hide",' +
			'"ColumnsToTransfer": "' + vr_cols_to_transfer + '"' +
		   '}') AS info
	-- end of Third Part

	-- end of Add Contributor Columns
END;