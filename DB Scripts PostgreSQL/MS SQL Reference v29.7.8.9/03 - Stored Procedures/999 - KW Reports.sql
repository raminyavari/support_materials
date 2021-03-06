USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_KnowledgeAdminsReport]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_KnowledgeAdminsReport]
GO

CREATE PROCEDURE [dbo].[KW_KnowledgeAdminsReport]
	@ApplicationID			uniqueidentifier,
	@CurrentUserID			uniqueidentifier,
	@Now					datetime,
    @KnowledgeTypeID		uniqueidentifier,
	@strUserIDs				varchar(max),
	@delimiter				char,
	@MemberInNodeTypeID		uniqueidentifier,
	@SendDateFrom			datetime,
	@SendDateTo				datetime,
	@ActionDateFrom			datetime,
	@ActionDateTo			datetime,
	@DelayFrom				int,
	@DelayTo				int,
	@Seen					bit,
	@Done					bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserIDs GuidTableType
	
	INSERT INTO @UserIDs
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strUserIDs, @delimiter) AS Ref
	
	IF @DelayFrom IS NOT NULL AND @DelayFrom < 0 SET @DelayFrom = NULL
	ELSE SET @DelayFrom = @DelayFrom * 24 * 60 * 60

	IF @DelayTo IS NOT NULL AND @DelayTo < 0 SET @DelayTo = NULL
	ELSE SET @DelayTo = @DelayTo * 24 * 60 * 60

	DECLARE @HasTargetUsers bit = 0
	IF (SELECT COUNT(*) FROM @UserIDs) > 0 OR @MemberInNodeTypeID IS NOT NULL 
		SET @HasTargetUsers = 1

	DECLARE @TargetUserIDs GuidTableType

	INSERT INTO @TargetUserIDs (Value)
	SELECT DISTINCT X.UserID
	FROM (
			SELECT Value AS UserID
			FROM @UserIDs
			
			UNION ALL
			
			SELECT NM.UserID
			FROM [dbo].[CN_View_NodeMembers] AS NM
			WHERE @MemberInNodeTypeID IS NOT NULL AND NM.ApplicationID = @ApplicationID AND
				NM.NodeTypeID = @MemberInNodeTypeID AND NM.IsPending = 0
		) AS X
		

	SELECT	D.UserID AS UserID_Hide,
			MAX(UN.FirstName + N' ' + UN.LastName) AS FullName,
			COUNT(D.ID) AS ItemsCount,
			SUM(CASE WHEN D.Deleted = 0 AND D.ActionDate IS NULL THEN 1 ELSE 0 END) AS PendingCount,
			SUM(CASE WHEN D.ActionDate IS NULL THEN 0 ELSE 1 END) AS DoneCount,
			SUM(CASE WHEN D.Seen = 0 THEN 1 ELSE 0 END) AS NotSeenCount, 
			AVG(
				CASE
					WHEN D.ActionDate IS NULL THEN NULL
					ELSE ISNULL(CAST(DATEDIFF(second, D.SendDate, D.ActionDate) as float) / (24 * 3600), 0)
				END
			) AS DoneDelayAverage, 
			MIN(
				CASE
					WHEN D.ActionDate IS NULL THEN 0
					ELSE ISNULL(CAST(DATEDIFF(second, D.SendDate, D.ActionDate) as float) / (24 * 3600), 0)
				END
			) AS DoneDelayMin, 
			MAX(
				CASE
					WHEN D.ActionDate IS NULL THEN 0
					ELSE ISNULL(CAST(DATEDIFF(second, D.SendDate, D.ActionDate) as float) / (24 * 3600), 0)
				END
			) AS DoneDelayMax,
			AVG(
				CASE
					WHEN D.ActionDate IS NOT NULL OR D.Deleted = 1 THEN NULL
					ELSE ISNULL(CAST(DATEDIFF(second, D.SendDate, @Now) as float) / (24 * 3600), 0)
				END
			) AS NotDoneDelayAverage, 
			MIN(
				CASE
					WHEN D.ActionDate IS NOT NULL OR D.Deleted = 1 THEN 0
					ELSE ISNULL(CAST(DATEDIFF(second, D.SendDate, @Now) as float) / (24 * 3600), 0)
				END
			) AS NotDoneDelayMin, 
			MAX(
				CASE
					WHEN D.ActionDate IS NOT NULL OR D.Deleted = 1 THEN 0
					ELSE ISNULL(CAST(DATEDIFF(second, D.SendDate, @Now) as float) / (24 * 3600), 0)
				END
			) AS NotDoneDelayMax
	FROM @TargetUserIDs AS T
		RIGHT JOIN [dbo].[NTFN_Dashboards] AS D
		ON D.ApplicationID = @ApplicationID AND D.UserID = T.Value
		INNER JOIN [dbo].[CN_Nodes] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.NodeID = D.NodeID AND
			(@KnowledgeTypeID IS NULL OR ND.NodeTypeID = @KnowledgeTypeID)
		INNER JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND UN.UserID = D.UserID
	WHERE D.ApplicationID = @ApplicationID AND (@HasTargetUsers = 0 OR T.Value IS NOT NULL) AND
		D.[Type] = N'Knowledge' AND D.SubType = N'Admin' AND
		(@SendDateFrom IS NULL OR D.SendDate >= @SendDateFrom) AND
		(@SendDateTo IS NULL OR D.SendDate <= @SendDateTo) AND
		(@ActionDateFrom IS NULL OR D.ActionDate >= @ActionDateFrom) AND
		(@ActionDateTo IS NULL OR D.ActionDate <= @ActionDateTo) AND
		(@DelayFrom IS NULL OR 
			DATEDIFF(second, D.SendDate, ISNULL(D.ActionDate, @Now)) >= @DelayFrom) AND
		(@DelayTo IS NULL OR 
			DATEDIFF(second, D.SendDate, ISNULL(D.ActionDate, @Now)) <= @DelayTo) AND
		(@Done IS NULL OR ((@Done = 1 OR D.Deleted = 0) AND D.Done = @Done)) AND
		(@Seen IS NULL OR D.Seen = @Seen)
	GROUP BY D.UserID

	
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
		   '}') AS Actions

END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_KnowledgeAdminsDetailReport]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_KnowledgeAdminsDetailReport]
GO

CREATE PROCEDURE [dbo].[KW_KnowledgeAdminsDetailReport]
	@ApplicationID			uniqueidentifier,
	@CurrentUserID			uniqueidentifier,
	@Now					datetime,
	@KnowledgeID			uniqueidentifier,
    @KnowledgeTypeID		uniqueidentifier,
	@strUserIDs				varchar(max),
	@delimiter				char,
	@MemberInNodeTypeID		uniqueidentifier,
	@SendDateFrom			datetime,
	@SendDateTo				datetime,
	@ActionDateFrom			datetime,
	@ActionDateTo			datetime,
	@DelayFrom				int,
	@DelayTo				int,
	@Seen					bit,
	@Done					bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserIDs GuidTableType

	INSERT INTO @UserIDs
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strUserIDs, @delimiter) AS Ref

	IF @DelayFrom IS NOT NULL AND @DelayFrom < 0 SET @DelayFrom = NULL
	ELSE SET @DelayFrom = @DelayFrom * 24 * 60 * 60

	IF @DelayTo IS NOT NULL AND @DelayTo < 0 SET @DelayTo = NULL
	ELSE SET @DelayTo = @DelayTo * 24 * 60 * 60

	DECLARE @HasTargetUsers bit = 0
	IF (SELECT COUNT(*) FROM @UserIDs) > 0 OR @MemberInNodeTypeID IS NOT NULL 
		SET @HasTargetUsers = 1

	DECLARE @TargetUserIDs GuidTableType

	INSERT INTO @TargetUserIDs (Value)
	SELECT DISTINCT X.UserID
	FROM (
			SELECT Value AS UserID
			FROM @UserIDs
			
			UNION ALL
			
			SELECT NM.UserID
			FROM [dbo].[CN_View_NodeMembers] AS NM
			WHERE @MemberInNodeTypeID IS NOT NULL AND NM.ApplicationID = @ApplicationID AND
				NM.NodeTypeID = @MemberInNodeTypeID AND NM.IsPending = 0
		) AS X
		

	SELECT	ND.NodeID AS NodeID_Hide,
			ND.NodeName,
			ND.TypeName AS NodeType,
			D.UserID AS UserID_Hide,
			UN.FirstName + N' ' + UN.LastName AS FullName,
			D.SendDate,
			D.ActionDate,
			CASE
				WHEN D.Deleted = 0 AND D.ActionDate IS NULL THEN N'Pending'
				WHEN D.ActionDate IS NOT NULL THEN N'Done'
				ELSE N''
			END AS DoneStatus_Dic,
			CASE WHEN D.Seen = 0 THEN N'Seen' ELSE N'NotSeen' END AS SeenStatus_Dic, 
			CASE
				WHEN D.Deleted IS NULL THEN 0
				ELSE ISNULL(CAST(DATEDIFF(second, D.SendDate, ISNULL(D.ActionDate, @Now)) as int) / (24 * 3600), 0)
			END AS ActionDelay
	FROM @TargetUserIDs AS T
		RIGHT JOIN [dbo].[NTFN_Dashboards] AS D
		ON D.ApplicationID = @ApplicationID AND D.UserID = T.Value
		INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.NodeID = D.NodeID AND
			(@KnowledgeTypeID IS NULL OR ND.NodeTypeID = @KnowledgeTypeID)
		INNER JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND UN.UserID = D.UserID
	WHERE D.ApplicationID = @ApplicationID AND (@HasTargetUsers = 0 OR T.Value IS NOT NULL) AND
		D.[Type] = N'Knowledge' AND D.SubType = N'Admin' AND
		(@SendDateFrom IS NULL OR D.SendDate >= @SendDateFrom) AND
		(@SendDateTo IS NULL OR D.SendDate <= @SendDateTo) AND
		(@ActionDateFrom IS NULL OR D.ActionDate >= @ActionDateFrom) AND
		(@ActionDateTo IS NULL OR D.ActionDate <= @ActionDateTo) AND
		(@DelayFrom IS NULL OR (D.Deleted = 0 AND
			DATEDIFF(second, D.SendDate, ISNULL(D.ActionDate, @Now)) >= @DelayFrom)) AND
		(@DelayTo IS NULL OR  (D.Deleted = 0 AND
			DATEDIFF(second, D.SendDate, ISNULL(D.ActionDate, @Now)) <= @DelayTo)) AND
		(@Done IS NULL OR ((@Done = 1 OR D.Deleted = 0) AND D.Done = @Done)) AND
		(@Seen IS NULL OR D.Seen = @Seen) AND
		(@KnowledgeID IS NULL OR ND.NodeID = @KnowledgeID)

	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"ID": "UserID_Hide"}' +
			'},' +
			'"NodeName": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'}' +
		   '}') AS Actions

END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_KnowledgeEvaluationsReport]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_KnowledgeEvaluationsReport]
GO

CREATE PROCEDURE [dbo].[KW_KnowledgeEvaluationsReport]
	@ApplicationID			uniqueidentifier,
	@CurrentUserID			uniqueidentifier,
	@Now					datetime,
    @KnowledgeTypeID		uniqueidentifier,
	@strUserIDs				varchar(max),
	@delimiter				char,
	@MemberInNodeTypeID		uniqueidentifier,
	@SendDateFrom			datetime,
	@SendDateTo				datetime,
	@ActionDateFrom			datetime,
	@ActionDateTo			datetime,
	@DelayFrom				int,
	@DelayTo				int,
	@Seen					bit,
	@Done					bit,
	@Canceled				bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserIDs GuidTableType
	
	INSERT INTO @UserIDs
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strUserIDs, @delimiter) AS Ref
	
	IF @DelayFrom IS NOT NULL AND @DelayFrom < 0 SET @DelayFrom = NULL
	ELSE SET @DelayFrom = @DelayFrom * 24 * 60 * 60

	IF @DelayTo IS NOT NULL AND @DelayTo < 0 SET @DelayTo = NULL
	ELSE SET @DelayTo = @DelayTo * 24 * 60 * 60

	DECLARE @HasTargetUsers bit = 0
	IF (SELECT COUNT(*) FROM @UserIDs) > 0 OR @MemberInNodeTypeID IS NOT NULL 
		SET @HasTargetUsers = 1

	DECLARE @TargetUserIDs GuidTableType

	INSERT INTO @TargetUserIDs (Value)
	SELECT DISTINCT X.UserID
	FROM (
			SELECT Value AS UserID
			FROM @UserIDs
			
			UNION ALL
			
			SELECT NM.UserID
			FROM [dbo].[CN_View_NodeMembers] AS NM
			WHERE @MemberInNodeTypeID IS NOT NULL AND NM.ApplicationID = @ApplicationID AND
				NM.NodeTypeID = @MemberInNodeTypeID AND NM.IsPending = 0
		) AS X
		

	SELECT	D.UserID AS UserID_Hide,
			MAX(UN.FirstName + N' ' + UN.LastName) AS FullName,
			COUNT(D.ID) AS ItemsCount,
			SUM(CASE WHEN D.Deleted = 0 AND D.ActionDate IS NULL THEN 1 ELSE 0 END) AS PendingCount,
			SUM(CASE WHEN D.ActionDate IS NULL THEN 0 ELSE 1 END) AS EvaluationsCount,
			SUM(CASE WHEN D.Deleted = 1 THEN 1 ELSE 0 END) AS CanceledCount,
			SUM(CASE WHEN D.Seen = 0 THEN 1 ELSE 0 END) AS NotSeenCount, 
			AVG(
				CASE
					WHEN D.ActionDate IS NULL THEN NULL
					ELSE ISNULL(CAST(DATEDIFF(second, D.SendDate, D.ActionDate) as float) / (24 * 3600), 0)
				END
			) AS DoneDelayAverage, 
			MIN(
				CASE
					WHEN D.ActionDate IS NULL THEN 0
					ELSE ISNULL(CAST(DATEDIFF(second, D.SendDate, D.ActionDate) as float) / (24 * 3600), 0)
				END
			) AS DoneDelayMin, 
			MAX(
				CASE
					WHEN D.ActionDate IS NULL THEN 0
					ELSE ISNULL(CAST(DATEDIFF(second, D.SendDate, D.ActionDate) as float) / (24 * 3600), 0)
				END
			) AS DoneDelayMax,
			AVG(
				CASE
					WHEN D.ActionDate IS NOT NULL OR D.Deleted = 1 THEN NULL
					ELSE ISNULL(CAST(DATEDIFF(second, D.SendDate, @Now) as float) / (24 * 3600), 0)
				END
			) AS NotDoneDelayAverage, 
			MIN(
				CASE
					WHEN D.ActionDate IS NOT NULL OR D.Deleted = 1 THEN 0
					ELSE ISNULL(CAST(DATEDIFF(second, D.SendDate, @Now) as float) / (24 * 3600), 0)
				END
			) AS NotDoneDelayMin, 
			MAX(
				CASE
					WHEN D.ActionDate IS NOT NULL OR D.Deleted = 1 THEN 0
					ELSE ISNULL(CAST(DATEDIFF(second, D.SendDate, @Now) as float) / (24 * 3600), 0)
				END
			) AS NotDoneDelayMax
	FROM @TargetUserIDs AS T
		RIGHT JOIN [dbo].[NTFN_Dashboards] AS D
		ON D.ApplicationID = @ApplicationID AND D.UserID = T.Value
		INNER JOIN [dbo].[CN_Nodes] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.NodeID = D.NodeID AND
			(@KnowledgeTypeID IS NULL OR ND.NodeTypeID = @KnowledgeTypeID)
		INNER JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND UN.UserID = D.UserID
	WHERE D.ApplicationID = @ApplicationID AND (@HasTargetUsers = 0 OR T.Value IS NOT NULL) AND
		D.[Type] = N'Knowledge' AND D.SubType = N'Evaluator' AND
		(@SendDateFrom IS NULL OR D.SendDate >= @SendDateFrom) AND
		(@SendDateTo IS NULL OR D.SendDate <= @SendDateTo) AND
		(@ActionDateFrom IS NULL OR D.ActionDate >= @ActionDateFrom) AND
		(@ActionDateTo IS NULL OR D.ActionDate <= @ActionDateTo) AND
		(@DelayFrom IS NULL OR 
			DATEDIFF(second, D.SendDate, ISNULL(D.ActionDate, @Now)) >= @DelayFrom) AND
		(@DelayTo IS NULL OR 
			DATEDIFF(second, D.SendDate, ISNULL(D.ActionDate, @Now)) <= @DelayTo) AND
		(@Done IS NULL OR ((@Done = 1 OR D.Deleted = 0) AND D.Done = @Done)) AND
		(@Seen IS NULL OR D.Seen = @Seen) AND
		(@Canceled IS NULL OR D.Deleted = @Canceled)
	GROUP BY D.UserID

	
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
		   '}') AS Actions

END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_KnowledgeEvaluationsDetailReport]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_KnowledgeEvaluationsDetailReport]
GO

CREATE PROCEDURE [dbo].[KW_KnowledgeEvaluationsDetailReport]
	@ApplicationID			uniqueidentifier,
	@CurrentUserID			uniqueidentifier,
	@Now					datetime,
	@KnowledgeID			uniqueidentifier,
    @KnowledgeTypeID		uniqueidentifier,
	@strUserIDs				varchar(max),
	@delimiter				char,
	@MemberInNodeTypeID		uniqueidentifier,
	@SendDateFrom			datetime,
	@SendDateTo				datetime,
	@ActionDateFrom			datetime,
	@ActionDateTo			datetime,
	@DelayFrom				int,
	@DelayTo				int,
	@Seen					bit,
	@Done					bit,
	@Canceled				bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserIDs GuidTableType

	INSERT INTO @UserIDs
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strUserIDs, @delimiter) AS Ref

	IF @DelayFrom IS NOT NULL AND @DelayFrom < 0 SET @DelayFrom = NULL
	ELSE SET @DelayFrom = @DelayFrom * 24 * 60 * 60

	IF @DelayTo IS NOT NULL AND @DelayTo < 0 SET @DelayTo = NULL
	ELSE SET @DelayTo = @DelayTo * 24 * 60 * 60

	DECLARE @HasTargetUsers bit = 0
	IF (SELECT COUNT(*) FROM @UserIDs) > 0 OR @MemberInNodeTypeID IS NOT NULL 
		SET @HasTargetUsers = 1

	DECLARE @TargetUserIDs GuidTableType

	INSERT INTO @TargetUserIDs (Value)
	SELECT DISTINCT X.UserID
	FROM (
			SELECT Value AS UserID
			FROM @UserIDs
			
			UNION ALL
			
			SELECT NM.UserID
			FROM [dbo].[CN_View_NodeMembers] AS NM
			WHERE @MemberInNodeTypeID IS NOT NULL AND NM.ApplicationID = @ApplicationID AND
				NM.NodeTypeID = @MemberInNodeTypeID AND NM.IsPending = 0
		) AS X
		

	SELECT	ND.NodeID AS NodeID_Hide,
			ND.NodeName,
			ND.TypeName AS NodeType,
			D.UserID AS UserID_Hide,
			UN.FirstName + N' ' + UN.LastName AS FullName,
			D.SendDate,
			D.ActionDate,
			CASE
				WHEN D.Deleted = 0 AND D.ActionDate IS NULL THEN N'Pending'
				WHEN D.Deleted = 1 THEN N'Canceled'
				WHEN D.ActionDate IS NOT NULL THEN N'Done'
				ELSE N''
			END AS EvaluationStatus_Dic,
			CASE WHEN D.Seen = 0 THEN N'Seen' ELSE N'NotSeen' END AS SeenStatus_Dic, 
			CASE
				WHEN D.Deleted IS NULL THEN 0
				ELSE ISNULL(CAST(DATEDIFF(second, D.SendDate, ISNULL(D.ActionDate, @Now)) as int) / (24 * 3600), 0)
			END AS EvaluationDelay
	FROM @TargetUserIDs AS T
		RIGHT JOIN [dbo].[NTFN_Dashboards] AS D
		ON D.ApplicationID = @ApplicationID AND D.UserID = T.Value
		INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.NodeID = D.NodeID AND
			(@KnowledgeTypeID IS NULL OR ND.NodeTypeID = @KnowledgeTypeID)
		INNER JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND UN.UserID = D.UserID
	WHERE D.ApplicationID = @ApplicationID AND (@HasTargetUsers = 0 OR T.Value IS NOT NULL) AND
		D.[Type] = N'Knowledge' AND D.SubType = N'Evaluator' AND
		(@SendDateFrom IS NULL OR D.SendDate >= @SendDateFrom) AND
		(@SendDateTo IS NULL OR D.SendDate <= @SendDateTo) AND
		(@ActionDateFrom IS NULL OR D.ActionDate >= @ActionDateFrom) AND
		(@ActionDateTo IS NULL OR D.ActionDate <= @ActionDateTo) AND
		(@DelayFrom IS NULL OR (D.Deleted = 0 AND
			DATEDIFF(second, D.SendDate, ISNULL(D.ActionDate, @Now)) >= @DelayFrom)) AND
		(@DelayTo IS NULL OR  (D.Deleted = 0 AND
			DATEDIFF(second, D.SendDate, ISNULL(D.ActionDate, @Now)) <= @DelayTo)) AND
		(@Done IS NULL OR ((@Done = 1 OR D.Deleted = 0) AND D.Done = @Done)) AND
		(@Seen IS NULL OR D.Seen = @Seen) AND
		(@Canceled IS NULL OR D.Deleted = @Canceled) AND
		(@KnowledgeID IS NULL OR ND.NodeID = @KnowledgeID)

	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"ID": "UserID_Hide"}' +
			'},' +
			'"NodeName": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'}' +
		   '}') AS Actions

END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_KnowledgeEvaluationsHistoryReport]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_KnowledgeEvaluationsHistoryReport]
GO

CREATE PROCEDURE [dbo].[KW_KnowledgeEvaluationsHistoryReport]
	@ApplicationID		uniqueidentifier,
	@CurrentUserID		uniqueidentifier,
	@KnowledgeTypeID	uniqueidentifier,
	@KnowledgeID		uniqueidentifier,
	@strUserIDs			varchar(max),
	@delimiter			char,
	@DateFrom			datetime,
	@DateTo				datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserIDs GuidTableType
	
	INSERT INTO @UserIDs (Value)
	SELECT DISTINCT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strUserIDs, @delimiter) AS Ref
	
	DECLARE @UsersIDsCount int = (SELECT COUNT(*) FROM @UserIDs)
	
	DECLARE @LastVersions TABLE (KnowledgeID uniqueidentifier primary key clustered, LastVersionID int)

	INSERT INTO @LastVersions (KnowledgeID, LastVersionID)
	SELECT H.KnowledgeID, MAX(H.WFVersionID) AS LastVersionID
	FROM [dbo].[KW_History] AS H
	GROUP BY H.KnowledgeID


	DECLARE @Ret TABLE (
		NodeID_Hide uniqueidentifier, 
		NodeName nvarchar(1000), 
		NodeAdditionalID nvarchar(100),
		NodeType nvarchar(200),
		CreatorUserID_Hide uniqueidentifier,
		CreatorFullName nvarchar(200),
		CreatorUserName nvarchar(100),
		Status_Dic nvarchar(100),
		EvaluatorUserID_Hide uniqueidentifier,
		EvaluatorFullName nvarchar(200),
		EvaluatorUserName nvarchar(100),
		Score float,
		EvaluationDate datetime,
		WFVersionID int,
		[Description] nvarchar(max),
		Reasons nvarchar(1000)
	)


	INSERT INTO @Ret (NodeID_Hide, NodeName, NodeAdditionalID, NodeType, CreatorUserID_Hide, CreatorUserName, CreatorFullName, 
		Status_Dic, EvaluatorUserID_Hide, EvaluatorUserName, EvaluatorFullName, Score, EvaluationDate, WFVersionID, 
		[Description], Reasons)
	SELECT	ND.NodeID, ND.NodeName, ND.NodeAdditionalID, ND.TypeName, UN.UserID, UN.UserName, 
		LTRIM(RTRIM(ISNULL(UN.FirstName, N'') + N' ' + ISNULL(UN.LastName, N''))),
		ND.[Status], X.EvaluatorUserID, X.EvaluatorUserName,
		LTRIM(RTRIM(ISNULL(X.EvaluatorFirstName, N'') + N' ' + ISNULL(X.EvaluatorLastName, N''))),
		X.Score, X.EvaluationDate, X.WFVersionID, H.[Description], H.TextOptions
	FROM (
			SELECT	Ref.KnowledgeID,
					Ref.UserID AS EvaluatorUserID,
					UN.UserName AS EvaluatorUserName,
					UN.FirstName AS EvaluatorFirstName,
					UN.LastName AS EvaluatorLastName,
					Ref.Score,
					Ref.EvaluationDate,
					LV.LastVersionID AS WFVersionID
			FROM (
					SELECT	A.KnowledgeID, 
							A.UserID, 
							(SUM(ISNULL(ISNULL(A.AdminScore, A.Score), 0)) / ISNULL(COUNT(A.UserID), 1)) AS Score,
							MAX(A.EvaluationDate) AS EvaluationDate
					FROM [dbo].[KW_QuestionAnswers] AS A
					WHERE A.ApplicationID = @ApplicationID AND A.Deleted = 0 AND
						(@DateFrom IS NULL OR A.EvaluationDate > @DateFrom) AND
						(@DateTo IS NULL OR A.EvaluationDate <= @DateTo)
					GROUP BY A.KnowledgeID, A.UserID
				) AS Ref
				INNER JOIN @LastVersions AS LV
				ON LV.KnowledgeID = Ref.KnowledgeID
				INNER JOIN [dbo].[Users_Normal] AS UN
				ON UN.ApplicationID = @ApplicationID AND UN.UserID = Ref.UserID AND
					(@UsersIDsCount = 0 OR UN.UserID IN (SELECT Value FROM @UserIDs))

			UNION ALL

			SELECT	Ref.KnowledgeID,
					Ref.UserID,
					UN.UserName,
					UN.FirstName,
					UN.LastName,
					Ref.Score,
					Ref.EvaluationDate,
					Ref.WFVersionID
			FROM (
					SELECT A.KnowledgeID, A.UserID, (SUM(ISNULL(ISNULL(A.AdminScore, A.Score), 0)) / ISNULL(COUNT(A.UserID), 1)) AS Score,
						MAX(A.EvaluationDate) AS EvaluationDate, A.WFVersionID
					FROM [dbo].[KW_QuestionAnswersHistory] AS A
					WHERE A.ApplicationID = @ApplicationID AND A.Deleted = 0 AND
						(@DateFrom IS NULL OR A.EvaluationDate > @DateFrom) AND
						(@DateTo IS NULL OR A.EvaluationDate <= @DateTo)
					GROUP BY A.KnowledgeID, A.UserID, A.WFVersionID
				) AS Ref
				INNER JOIN [dbo].[Users_Normal] AS UN
				ON UN.ApplicationID = @ApplicationID AND UN.UserID = Ref.UserID AND
					(@UsersIDsCount = 0 OR UN.UserID IN (SELECT Value FROM @UserIDs))
		) AS X
		INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.NodeID = X.KnowledgeID AND
			(@KnowledgeTypeID IS NULL OR ND.NodeTypeID = @KnowledgeTypeID) AND
			(@KnowledgeID IS NULL OR ND.NodeID = @KnowledgeID)
		INNER JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND UN.UserID = ND.CreatorUserID
		LEFT JOIN [dbo].[KW_History] AS H
		ON H.ApplicationID = @ApplicationID AND H.KnowledgeID = X.KnowledgeID AND 
			H.ActorUserID = X.EvaluatorUserID AND H.ActionDate = X.EvaluationDate
	ORDER BY X.EvaluationDate DESC, X.KnowledgeID DESC, X.WFVersionID DESC

	SELECT *
	FROM @Ret


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
		   '}') AS Actions
		   
	   
	-- Add Contributor Columns

	DECLARE @Proc nvarchar(max) = N''

	SELECT X.*
	INTO #Result
	FROM (
			SELECT	C.NodeID, 
					CAST(C.UserID AS varchar(50)) AS unq,
					C.UserID, 
					C.CollaborationShare AS Share,
					ROW_NUMBER() OVER (PARTITION BY C.NodeID ORDER BY C.CollaborationShare DESC, C.UserID DESC) AS RowNumber
			FROM @Ret AS IDs
				INNER JOIN [dbo].[CN_NodeCreators] AS C
				ON C.ApplicationID = @ApplicationID AND C.NodeID = IDs.NodeID_Hide AND C.Deleted = 0
		) AS X
		
	DECLARE @Count int = (SELECT MAX(RowNumber) FROM #Result)
	DECLARE @ItemsList varchar(max) = N'', @SelectList varchar(max) = N'', @ColsToTransfer varchar(max) = N''

	SET @Proc = N''

	DECLARE @Ind int = @Count - 1
	WHILE @Ind >= 0 BEGIN
		DECLARE @Tmp varchar(10) = CAST((@Count - @Ind) AS varchar(10))
		
		SET @SelectList = @SelectList + '[' + @Tmp + '] AS [ContributorID_Hide_' + @Tmp + '], ' + 
			'CAST(NULL AS nvarchar(500)) AS [Contributor_' + @Tmp + '], ' +
			'CAST(NULL AS float) AS [ContributorShare_' + @Tmp + ']'
			
		SET @ItemsList = @ItemsList + '[' + @Tmp + ']'
		
		SET @Proc = @Proc + 
			'SELECT ''ContributorID_Hide_' + @Tmp + ''' AS ColumnName, null AS Translation, ''string'' AS Type ' +
			'UNION ALL ' +
			'SELECT ''Contributor_' + @Tmp + ''' AS ColumnName, null AS Translation, ''string'' AS Type ' +
			'UNION ALL ' +
			'SELECT ''ContributorShare_' + @Tmp + ''' AS ColumnName, null AS Translation, ''double'' AS Type '
			
		SET @ColsToTransfer = @ColsToTransfer + 
			'ContributorID_Hide_' + @Tmp + ',Contributor_' + @Tmp + ',ContributorShare_' + @Tmp
		
		IF @Ind > 0 BEGIN 
			SET @SelectList = @SelectList + ', '
			SET @ItemsList = @ItemsList + ', '
			SET @Proc = @Proc + N'UNION ALL '
			SET @ColsToTransfer = @ColsToTransfer + ','
		END
		
		SET @Ind = @Ind - 1
	END

	-- Second Part: Describes the Third Part
	EXEC (@Proc)

	SELECT ('{"IsDescription": "true"}') AS Info
	-- end of Second Part

	-- Third Part: The Data
	SET @Proc = 
		'SELECT NodeID AS NodeID_Hide, ' + @SelectList + 
		'INTO #Final ' +
		'FROM ( ' +
				'SELECT NodeID, unq, RowNumber ' +
				'FROM #Result ' +
			') AS P ' +
			'PIVOT (MAX(unq) FOR RowNumber IN (' + @ItemsList + ')) AS PVT '

	SET @Ind = @Count - 1
	WHILE @Ind >= 0 BEGIN
		DECLARE @No varchar(10) = CAST((@Count - @Ind) AS varchar(10))
		
		SET @Proc = @Proc + 
			'UPDATE F ' + 
				'SET Contributor_' + @No + ' = LTRIM(RTRIM(ISNULL(UN.FirstName, N'''') + N'' '' + ISNULL(UN.LastName, N''''))) ' + 
			'FROM #Final AS F ' + 
				'INNER JOIN [dbo].[Users_Normal] AS UN ' + 
				'ON UN.ApplicationID = ''' + CAST(@ApplicationID AS varchar(50)) + ''' AND UN.UserID = F.ContributorID_Hide_' + @No + ' '
				
		SET @Proc = @Proc + 
			'UPDATE F ' + 
				'SET ContributorShare_' + @No + ' = R.Share ' + 
			'FROM #Final AS F ' + 
				'INNER JOIN #Result AS R ' + 
				'ON R.NodeID = F.NodeID_Hide AND R.UserID = F.ContributorID_Hide_' + @No + ' '
		
		SET @Ind = @Ind - 1
	END

	SET @Proc = @Proc + 'SELECT * FROM #Final'

	EXEC (@Proc)

	SELECT ('{' +
			'"ColumnsMap": "NodeID_Hide:NodeID_Hide",' +
			'"ColumnsToTransfer": "' + @ColsToTransfer + '"' +
		   '}') AS Info
	-- end of Third Part

	-- end of Add Contributor Columns
END

GO