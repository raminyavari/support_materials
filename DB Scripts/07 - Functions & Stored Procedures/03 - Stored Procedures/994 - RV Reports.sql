USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_OveralReport]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_OveralReport]
GO

CREATE PROCEDURE [dbo].[RV_OveralReport]
	@ApplicationID	uniqueidentifier,
	@CurrentUserID	uniqueidentifier,
	@BeginDate		datetime,
	@FinishDate		datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT N'تعداد کاربران' AS ItemName, COUNT(Ref.UserID) AS [Count]
	FROM [dbo].[Users_Normal] AS Ref
	WHERE Ref.ApplicationID = @ApplicationID AND 
		(@BeginDate IS NULL OR Ref.CreationDate >= @BeginDate) AND
		(@FinishDate IS NULL OR Ref.CreationDate <= @FinishDate) AND Ref.IsApproved = 1
			
	UNION ALL
	
	SELECT N'تعداد کاربران با پروفایل تکمیل شده' AS ItemName, COUNT(Ref.UserID) AS [Count]
	FROM [dbo].[Users_Normal] AS Ref
	WHERE Ref.ApplicationID = @ApplicationID AND
		Ref.FirstName IS NOT NULL AND Ref.FirstName <> N'' AND
		Ref.LastName IS NOT NULL AND Ref.LastName <> N'' AND
		(@BeginDate IS NULL OR Ref.CreationDate >= @BeginDate) AND
		(@FinishDate IS NULL OR Ref.CreationDate <= @FinishDate) AND Ref.IsApproved = 1
			
	UNION ALL
	
	SELECT N'تعداد کاربران فعال' + ' (' + N'15 روزه' + N')' AS ItemName, COUNT(Ref.UserID) AS [Count]
	FROM [dbo].[Users_Normal] AS Ref
	WHERE Ref.ApplicationID = @ApplicationID AND
		Ref.LastActivityDate >= DATEADD(DAY, -15, GETDATE()) AND Ref.IsApproved = 1
			
	UNION ALL
	
	SELECT N'تعداد کاربران فعال' + ' (' + N'30 روزه' + N')' AS ItemName, COUNT(Ref.UserID) AS [Count]
	FROM [dbo].[Users_Normal] AS Ref
	WHERE Ref.ApplicationID = @ApplicationID AND
		Ref.LastActivityDate >= DATEADD(DAY, -30, GETDATE()) AND Ref.IsApproved = 1

	UNION ALL

	SELECT N'تعداد پرسش ها', COUNT(QuestionID)
	FROM [dbo].[QA_Questions]
	WHERE ApplicationID = @ApplicationID AND Deleted = 0 AND
		(@BeginDate IS NULL OR SendDate >= @BeginDate) AND
		(@FinishDate IS NULL OR SendDate <= @FinishDate)
		
	UNION ALL

	SELECT N'تعداد پرسش های دارای بهترین پاسخ', COUNT(QuestionID)
	FROM [dbo].[QA_Questions]
	WHERE ApplicationID = @ApplicationID AND [Status] = N'Accepted' AND 
		PublicationDate IS NOT NULL AND Deleted = 0 AND 
		(@BeginDate IS NULL OR SendDate >= @BeginDate) AND
		(@FinishDate IS NULL OR SendDate <= @FinishDate)
		
	UNION ALL

	SELECT N'تعداد خبره های تعریف شده' + ' (' + N'کل خبره ها' + N')', COUNT(EX.UserID) 
	FROM [dbo].[CN_Experts] AS EX
		INNER JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND UN.[UserID] = EX.[UserID]
		INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.[NodeID] = EX.[NodeID]
	WHERE EX.ApplicationID = @ApplicationID AND 
		(EX.Approved = 1 OR EX.SocialApproved = 1) AND
		UN.IsApproved = 1 AND ND.Deleted = 0
		
		
	UNION ALL

	SELECT N'تعداد کاربران خبره' + N' (' + N'کل خبره ها' + N')', COUNT(CNT)
	FROM (
			SELECT COUNT(UN.UserID) AS CNT
			FROM [dbo].[CN_Experts] AS EX
				INNER JOIN [dbo].[Users_Normal] AS UN
				ON UN.ApplicationID = @ApplicationID AND UN.[UserID] = EX.[UserID]
				INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
				ON ND.ApplicationID = @ApplicationID AND ND.[NodeID] = EX.[NodeID]
			WHERE EX.ApplicationID = @ApplicationID AND 
				(EX.Approved = 1 OR EX.SocialApproved = 1) AND
				UN.IsApproved = 1 AND ND.[Deleted] = 0
			GROUP BY UN.[UserID]
		) AS Ref
	
	UNION ALL

	SELECT N'تعداد لایک های پست ها', COUNT(SL.ShareID)
	FROM [dbo].[SH_ShareLikes] AS SL
	WHERE SL.ApplicationID = @ApplicationID AND SL.[Like] = 1 AND
		(@BeginDate IS NULL OR SL.[Date] >= @BeginDate) AND
		(@FinishDate IS NULL OR SL.[Date] <= @FinishDate)
		
	UNION ALL

	SELECT N'تعداد لایک های کامنت ها', COUNT(SL.CommentID)
	FROM [dbo].[SH_CommentLikes] AS SL
	WHERE SL.ApplicationID = @ApplicationID AND SL.[Like] = 1 AND
		(@BeginDate IS NULL OR SL.[Date] >= @BeginDate) AND
		(@FinishDate IS NULL OR SL.[Date] <= @FinishDate)
		
	UNION ALL

	SELECT N'تعداد لایک های صفحات', COUNT(NL.NodeID)
	FROM [dbo].[CN_NodeLikes] AS NL
	WHERE NL.ApplicationID = @ApplicationID AND NL.[Deleted] = 0 AND
		(@BeginDate IS NULL OR NL.[LikeDate] >= @BeginDate) AND
		(@FinishDate IS NULL OR NL.[LikeDate] <= @FinishDate)
			
	UNION ALL

	SELECT N'تعداد پست ها', COUNT(PS.ShareID)
	FROM [dbo].[SH_PostShares] AS PS
	WHERE PS.ApplicationID = @ApplicationID AND PS.[Deleted] = 0 AND
		(@BeginDate IS NULL OR PS.[SendDate] >= @BeginDate) AND
		(@FinishDate IS NULL OR PS.[SendDate] <= @FinishDate)
	
	UNION ALL

	SELECT N'تعداد کامنت ها', COUNT(C.CommentID)
	FROM [dbo].[SH_Comments] AS C
	WHERE C.ApplicationID = @ApplicationID AND C.[Deleted] = 0 AND
		(@BeginDate IS NULL OR C.[SendDate] >= @BeginDate) AND
		(@FinishDate IS NULL OR C.[SendDate] <= @FinishDate)
		
	UNION ALL

	SELECT N'تعداد دانش ها', COUNT(KnowledgeID)
	FROM [dbo].[KW_View_Knowledges]
	WHERE ApplicationID = @ApplicationID AND Deleted = 0 AND
		(@BeginDate IS NULL OR CreationDate >= @BeginDate) AND
		(@FinishDate IS NULL OR CreationDate <= @FinishDate)

	UNION ALL

	SELECT N'تعداد دانش های تایید شده', COUNT(KnowledgeID)
	FROM [dbo].[KW_View_Knowledges]
	WHERE ApplicationID = @ApplicationID AND 
		[Status] = N'Accepted' AND Deleted = 0 AND
		(@BeginDate IS NULL OR ISNULL(PublicationDate, CreationDate) >= @BeginDate) AND
		(@FinishDate IS NULL OR ISNULL(PublicationDate, CreationDate) <= @FinishDate)
			
	UNION ALL
	
	SELECT X.ItemName, X.[Count]
	FROM (
			SELECT TOP(1000000) A.ItemName, A.[Count]
			FROM (
					SELECT	(N'تعداد ' + NT.Name + (CASE WHEN Ref.[Type] = N'Count' THEN N'' ELSE N' - منتشر شده' END)) AS ItemName, 
							ISNULL(Ref.[Count], 0) AS [Count],
							ISNULL(Ref.TotalCount, 0) AS TotalCount
					FROM (
							SELECT	NodeTypeID, 
									COUNT(NodeID) AS [Count], 
									COUNT(NodeID) AS TotalCount, 
									N'Count' AS [Type]
							FROM [dbo].[CN_View_Nodes_Normal]
							WHERE ApplicationID = @ApplicationID AND Deleted = 0 AND
								(@BeginDate IS NULL OR CreationDate >= @BeginDate) AND
								(@FinishDate IS NULL OR CreationDate <= @FinishDate)
							GROUP BY NodeTypeID
							
							UNION ALL
							
							SELECT	NodeTypeID, 
									SUM(CAST((CASE WHEN ISNULL(Searchable, 1) = 1 THEN 1 ELSE 0 END) AS int)) AS [Count],
									COUNT(NodeID) AS TotalCount,
									N'Published' AS [Type]
							FROM [dbo].[CN_View_Nodes_Normal]
							WHERE ApplicationID = @ApplicationID AND Deleted = 0 AND
								(@BeginDate IS NULL OR CreationDate >= @BeginDate) AND
								(@FinishDate IS NULL OR CreationDate <= @FinishDate)
							GROUP BY NodeTypeID
						) AS Ref
						RIGHT JOIN [dbo].[CN_NodeTypes] AS NT
						ON NT.ApplicationID = @ApplicationID AND NT.NodeTypeID = Ref.NodeTypeID
					WHERE NT.ApplicationID = @ApplicationID AND NT.Deleted = 0
				) AS A
			ORDER BY A.TotalCount DESC, A.ItemName ASC
		) AS X
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_LogsReport]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_LogsReport]
GO

CREATE PROCEDURE [dbo].[RV_LogsReport]
	@ApplicationID		uniqueidentifier,
	@CurrentUserID		uniqueidentifier,
	@UserID				uniqueidentifier,
	@ActionsTemp		StringTableType readonly,
	@IPAddressesTemp	StringTableType readonly,
	@Level				varchar(20),
	@NotAuthorized		bit,
	@Anonymous			bit,
	@BeginDate			datetime,
	@FinishDate			datetime,
	@Count				int,
	@LowerBoundary		bigint
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Actions StringTableType
	INSERT INTO @Actions SELECT * FROM @ActionsTemp
	
	DECLARE @ActionExists bit = CASE WHEN EXISTS(SELECT TOP(1) * FROM @Actions) THEN 1 ELSE 0 END
	
	DECLARE @IPAddresses StringTableType
	INSERT INTO @IPAddresses SELECT * FROM @IPAddressesTemp
	
	DECLARE @IPExists bit = CASE WHEN EXISTS(SELECT TOP(1) * FROM @IPAddresses) THEN 1 ELSE 0 END
	
	IF @NotAuthorized IS NULL SET @NotAuthorized = 0
	IF @Level = N'' SET @Level = NULL
	
	DECLARE @Empty uniqueidentifier = N'00000000-0000-0000-0000-000000000000'
	
	SET @Anonymous = ISNULL(@Anonymous, 0)
	IF @Anonymous = 1 SET @UserID = NULL
	
	SELECT TOP(ISNULL(@Count, 2000))
		(Ref.RowNumber_Hide + Ref.RevRowNumber_Hide - 1) AS TotalCount_Hide,
		Ref.*
	FROM (
			SELECT	ROW_NUMBER() OVER (ORDER BY LG.LogID DESC) AS RowNumber_Hide,
					ROW_NUMBER() OVER (ORDER BY LG.LogID ASC) AS RevRowNumber_Hide,
					LG.LogID AS LogID_Hide,
					UN.UserID AS UserID_Hide,
					RTRIM(LTRIM(ISNULL(UN.FirstName, N'') + N' ' + 
						ISNULL(UN.LastName, N''))) AS FullName,
					LG.[Action] AS Action_Dic,
					LG.[Level] AS Level_Dic,
					CASE 
						WHEN ISNULL(LG.NotAuthorized, 0) = 0 THEN N'' 
						ELSE N'بله' 
					END AS NotAuthorized,
					LG.[Date],
					LG.HostAddress,
					LG.HostName,
					CASE 
						WHEN LG.SubjectID = @Empty THEN NULL 
						ELSE LG.SubjectID
					END AS SubjectID,
					DelFirst.ObjectType AS FirstType_Hide,
					LG.SecondSubjectID,
					DelSecond.ObjectType AS SecondType_Hide,
					LG.ThirdSubjectID,
					DelThird.ObjectType AS ThirdType_Hide,
					LG.FourthSubjectID,
					DelFourth.ObjectType AS FourthType_Hide,
					LG.Info AS Info_HideC
			FROM [dbo].[LG_Logs] AS LG
				LEFT JOIN [dbo].[Users_Normal] AS UN
				ON UN.ApplicationID = @ApplicationID AND UN.UserID = LG.UserID
				LEFT JOIN [dbo].[RV_DeletedStates] AS DelFirst
				ON DelFirst.ApplicationID = @ApplicationID AND
					DelFirst.ObjectID = LG.SubjectID
				LEFT JOIN [dbo].[RV_DeletedStates] AS DelSecond
				ON DelSecond.ApplicationID = @ApplicationID AND
					DelSecond.ObjectID = LG.SecondSubjectID
				LEFT JOIN [dbo].[RV_DeletedStates] AS DelThird
				ON DelThird.ApplicationID = @ApplicationID AND
					DelThird.ObjectID = LG.ThirdSubjectID
				LEFT JOIN [dbo].[RV_DeletedStates] AS DelFourth
				ON DelFourth.ApplicationID = @ApplicationID AND
					DelFourth.ObjectID = LG.FourthSubjectID
			WHERE LG.ApplicationID = @ApplicationID AND 
				(@UserID IS NULL OR LG.UserID = @UserID) AND
				(@Anonymous = 0 OR LG.UserID = @Empty) AND
				(@ActionExists = 0 OR LG.[Action] IN (SELECT * FROM @Actions)) AND
				(@IPExists = 0 OR LG.HostAddress IN (SELECT * FROM @IPAddresses)) AND
				(@Level IS NULL OR LG.[Level] = @Level) AND
				(@BeginDate IS NULL OR LG.[Date] >= @BeginDate) AND
				(@FinishDate IS NULL OR LG.[Date] <= @FinishDate) AND
				(@NotAuthorized = 0 OR LG.NotAuthorized = 1)
		) AS Ref
	WHERE Ref.RowNumber_Hide >= ISNULL(@LowerBoundary, 0)
	ORDER BY Ref.RowNumber_Hide ASC
	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'},' +
			'"Action_Dic": {"Action": "JSON", "Shows": "Info_HideC"},' +
			'"SubjectID": {"Action": "Link", "Type": "[[FirstType_Hide]]",' +
				'"Requires": {"ID": "SubjectID"}' +
			'},' +
			'"SecondSubjectID": {"Action": "Link", "Type": "[[SecondType_Hide]]",' +
				'"Requires": {"ID": "SecondSubjectID"}' +
			'},' +
			'"ThirdSubjectID": {"Action": "Link", "Type": "[[ThirdType_Hide]]",' +
				'"Requires": {"ID": "ThirdSubjectID"}' +
			'},' +
			'"FourthSubjectID": {"Action": "Link", "Type": "[[FourthType_Hide]]",' +
				'"Requires": {"ID": "FourthSubjectID"}' +
			'}' +
		   '}') AS Actions
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_ErrorLogsReport]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_ErrorLogsReport]
GO

CREATE PROCEDURE [dbo].[RV_ErrorLogsReport]
	@ApplicationID	uniqueidentifier,
	@CurrentUserID	uniqueidentifier,
	@Level			varchar(20),
	@BeginDate		datetime,
	@FinishDate		datetime,
	@Count			int,
	@LowerBoundary	bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF @Level = N'' SET @Level = NULL
	
	SELECT TOP(ISNULL(@Count, 2000))
		(Ref.RowNumber_Hide + Ref.RevRowNumber_Hide - 1) AS TotalCount_Hide,
		Ref.*
	FROM (
			SELECT	ROW_NUMBER() OVER (ORDER BY LG.LogID DESC) AS RowNumber_Hide,
					ROW_NUMBER() OVER (ORDER BY LG.LogID ASC) AS RevRowNumber_Hide,
					LG.LogID AS LogID_Hide,
					LG.[Subject],
					LG.[Level] AS Level_Dic,
					LG.[Description] AS Description_HideC,
					LG.[Date]
			FROM [dbo].[LG_ErrorLogs] AS LG
			WHERE LG.ApplicationID = @ApplicationID AND 
				(@Level IS NULL OR LG.[Level] = @Level) AND
				(@BeginDate IS NULL OR LG.[Date] >= @BeginDate) AND
				(@FinishDate IS NULL OR LG.[Date] <= @FinishDate)
		) AS Ref
	WHERE Ref.RowNumber_Hide >= ISNULL(@LowerBoundary, 0)
	ORDER BY Ref.RowNumber_Hide ASC
	
	SELECT ('{' +
			'"Subject": {"Action": "Show", "Shows": "Description_HideC"}' +
		   '}') AS Actions
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_ApplicationsPerformanceReport]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_ApplicationsPerformanceReport]
GO

CREATE PROCEDURE [dbo].[RV_ApplicationsPerformanceReport]
	@ApplicationID			uniqueidentifier,
	@CurrentUserID			uniqueidentifier,
	@strTeamIDs varchar(max),
	@delimiter	char,
	@DateFrom	datetime,
	@DateMiddle datetime,
	@DateTo		datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @TeamIDs GuidTableType

	INSERT INTO @TeamIDs ([Value])
	SELECT Ref.[Value] 
	FROM [dbo].[GFN_StrToGuidTable](@strTeamIDs, @delimiter) AS Ref

	DECLARE @TeamsCount int = (SELECT COUNT(*) FROM @TeamIDs)
	DECLARE @NodeIDs GuidTableType
	DECLARE @Archive bit = 0

	DECLARE @IgnoreUserIDs GuidTableType
	INSERT INTO @IgnoreUserIDs ([Value])
	VALUES	(N'8F50DE39-814B-4A9F-AF7A-3C8E3F76E563'), -- Seyed Ali
			(N'89CCA85E-3AB5-4731-BCD6-5D39C7169EB5')  -- Sepehr

	;WITH Applications
	AS
	(
		SELECT	App.ApplicationId AS ApplicationID, 
				App.Title,
				(
					SELECT COUNT(*)
					FROM [dbo].[USR_UserApplications] AS U
					WHERE U.ApplicationID = App.ApplicationId
				) AS MembersCount,
				(
					SELECT COUNT(*)
					FROM [dbo].[CN_NodeTypes] AS NT
						LEFT JOIN [dbo].[CN_Services] AS S
						ON S.ApplicationID = App.ApplicationId AND S.NodeTypeID = NT.NodeTypeID
					WHERE NT.ApplicationID = App.ApplicationId AND NT.Deleted = 0 AND ISNULL(S.ServiceTitle, N'') <> N''
				) AS TemplatesCount
		FROM [dbo].[aspnet_Applications] AS App
		WHERE ((@TeamsCount = 0 AND ISNULL(App.Deleted, 0) = 0) OR App.ApplicationId IN (SELECT T.[Value] FROM @TeamIDs AS T))
	),
	Nodes
	AS
	(
		SELECT	App.ApplicationID,
				ND.NodeTypeID,
				ND.NodeID,
				ND.TypeName AS NodeType, 
				ND.NodeName, 
				ND.NodeAdditionalID AS AdditionalID, 
				ND.CreationDate,
				(CASE 
					WHEN ND.CreationDate >= @DateFrom AND ND.CreationDate < DATEADD(DAY, 1, @DateMiddle) THEN 1 
					WHEN ND.CreationDate >= DATEADD(DAY, 1, @DateMiddle) AND ND.CreationDate < DATEADD(DAY, 1, @DateTo) THEN 2
					ELSE 0
				END) AS [Period],
				ISNULL(Email.EmailAddress, USR.UserName) AS CreatorUserName,
				LTRIM(RTRIM(ISNULL(USR.FirstName, N'') + N' ' + ISNULL(USR.LastName, N''))) AS CreatorFullName
		FROM Applications AS App
			INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
			ON ND.ApplicationID = App.ApplicationID AND 
				(@Archive IS NULL OR ND.Deleted = @Archive)
			INNER JOIN [dbo].[USR_View_Users] AS USR
			ON USR.UserID = ND.CreatorUserID
			LEFT JOIN [dbo].[USR_EmailAddresses] AS Email
			ON Email.EmailID = USR.MainEmailID
	),
	Files
	AS
	(
		SELECT	ND.ApplicationID, 
				Files.FileID,
				Files.[FileName],
				Files.Extension,
				Files.Size,
				Files.OwnerType,
				Files.CreationDate,
				Files.CreatorUserID,
				Files.Deleted AS FileArchived,
				(CASE 
					WHEN Files.CreationDate >= @DateFrom AND Files.CreationDate < DATEADD(DAY, 1, @DateMiddle) THEN 1 
					WHEN Files.CreationDate >= DATEADD(DAY, 1, @DateMiddle) AND Files.CreationDate < DATEADD(DAY, 1, @DateTo) THEN 2
					ELSE 0
				END) AS [Period]
		FROM Nodes AS ND
			INNER JOIN [dbo].[DCT_FN_ListDeepAttachments](@TeamIDs, @NodeIDs, @Archive) AS Files
			ON Files.ApplicationID = ND.ApplicationID AND Files.NodeID = ND.NodeID
	),
	Visits
	AS
	(
		SELECT X.ApplicationID, X.[Period], COUNT(X.UniqueID) AS VisitsCount, COUNT(DISTINCT X.NodeID) AS VisitedNodesCount
		FROM (
				SELECT	ND.ApplicationID,
						V.UniqueID,
						ND.NodeID, 
						V.VisitDate, 
						(CASE 
							WHEN V.VisitDate >= @DateFrom AND V.VisitDate < DATEADD(DAY, 1, @DateMiddle) THEN 1 
							WHEN V.VisitDate >= DATEADD(DAY, 1, @DateMiddle) AND V.VisitDate < DATEADD(DAY, 1, @DateTo) THEN 2
							ELSE 0
						END) AS [Period]
				FROM Nodes AS ND
					INNER JOIN [dbo].[USR_ItemVisits] AS V
					ON V.ApplicationID = ND.ApplicationID AND V.ItemID = ND.NodeID AND
						V.UserID NOT IN (SELECT X.[Value] FROM @IgnoreUserIDs AS X)
			) AS X
		GROUP BY X.ApplicationID, X.[Period]
	),
	SearchLogs
	AS
	(
		SELECT X.ApplicationID, X.[Action], X.[Period], COUNT(X.LogID) AS [Count]
		FROM (
				SELECT	App.ApplicationID,
						LG.LogID, 
						LG.[Date], 
						LG.[Action],
						(CASE 
							WHEN LG.[Date] >= @DateFrom AND LG.[Date] < DATEADD(DAY, 1, @DateMiddle) THEN 1 
							WHEN LG.[Date] >= DATEADD(DAY, 1, @DateMiddle) AND LG.[Date] < DATEADD(DAY, 1, @DateTo) THEN 2
							ELSE 0
						END) AS [Period]
				FROM Applications AS App
					INNER JOIN [dbo].[LG_Logs] AS LG
					ON LG.ApplicationID = App.ApplicationID AND LG.[Action] = 'Search' AND
						LG.UserID NOT IN (SELECT X.[Value] FROM @IgnoreUserIDs AS X)
			) AS X
		GROUP BY X.ApplicationID, X.[Action], X.[Period]
	),
	LoginLogs
	AS
	(
		SELECT X.ApplicationID, X.[Action], X.[Period], COUNT(X.LogID) AS [Count]
		FROM (
				SELECT	App.ApplicationID,
						LG.LogID, 
						LG.[Date], 
						LG.[Action],
						(CASE 
							WHEN LG.[Date] >= @DateFrom AND LG.[Date] < DATEADD(DAY, 1, @DateMiddle) THEN 1 
							WHEN LG.[Date] >= DATEADD(DAY, 1, @DateMiddle) AND LG.[Date] < DATEADD(DAY, 1, @DateTo) THEN 2
							ELSE 0
						END) AS [Period]
				FROM Applications AS App
					INNER JOIN [dbo].[USR_UserApplications] AS UA
					ON UA.ApplicationID = App.ApplicationID AND ISNULL(UA.Deleted, 0) = 0
					INNER JOIN [dbo].[LG_Logs] AS LG
					ON LG.UserID = UA.UserID AND LG.[Action] IN ('Login') AND
						LG.UserID NOT IN (SELECT X.[Value] FROM @IgnoreUserIDs AS X)
			) AS X
		GROUP BY X.ApplicationID, X.[Action], X.[Period]
	),
	AggregatedNodes
	AS
	(
		SELECT	App.ApplicationID,
				ISNULL(COUNT(N.NodeID), 0) AS CreatedNodesCount,
				ISNULL(COUNT(CASE WHEN N.[Period] = 1 THEN N.NodeID ELSE NULL END), 0) AS CreatedNodesCount_1,
				ISNULL(COUNT(CASE WHEN N.[Period] = 2 THEN N.NodeID ELSE NULL END), 0) AS CreatedNodesCount_2,
				ISNULL(COUNT(DISTINCT N.NodeTypeID), 0) AS UsedTemplatesCount,
				ISNULL(COUNT(DISTINCT CASE WHEN N.[Period] = 1 THEN N.NodeTypeID ELSE NULL END), 0) AS UsedTemplatesCount_1,
				ISNULL(COUNT(DISTINCT CASE WHEN N.[Period] = 2 THEN N.NodeTypeID ELSE NULL END), 0) AS UsedTemplatesCount_2
		FROM Applications AS App
			INNER JOIN Nodes AS N
			ON N.ApplicationID = App.ApplicationID
		GROUP BY App.ApplicationID
	),
	AggregatedLogin
	AS 
	(
		SELECT	App.ApplicationID,
				ISNULL(SUM(L.[Count]), 0) AS LoginCount,
				ISNULL(SUM(CASE WHEN L.[Period] = 1 THEN L.[Count] ELSE 0 END), 0) AS LoginCount_1,
				ISNULL(SUM(CASE WHEN L.[Period] = 2 THEN L.[Count] ELSE 0 END), 0) AS LoginCount_2
		FROM Applications AS App
			INNER JOIN LoginLogs AS L
			ON L.ApplicationID = App.ApplicationID AND L.[Action] = N'Login'
		GROUP BY App.ApplicationID
	),
	AggregatedSearch
	AS 
	(
		SELECT	App.ApplicationID,
				ISNULL(SUM(L.[Count]), 0) AS SearchCount,
				ISNULL(SUM(CASE WHEN L.[Period] = 1 THEN L.[Count] ELSE 0 END), 0) AS SearchCount_1,
				ISNULL(SUM(CASE WHEN L.[Period] = 2 THEN L.[Count] ELSE 0 END), 0) AS SearchCount_2
		FROM Applications AS App
			INNER JOIN SearchLogs AS L
			ON L.ApplicationID = App.ApplicationID AND L.[Action] = N'Search'
		GROUP BY App.ApplicationID
	),
	AggregatedFiles
	AS
	(
		SELECT	App.ApplicationID,
				ISNULL(COUNT(F.FileID), 0) AS Attachments,
				ISNULL(COUNT(CASE WHEN F.[Period] = 1 THEN F.FileID ELSE NULL END), 0) AS Attachments_1,
				ISNULL(COUNT(CASE WHEN F.[Period] = 2 THEN F.FileID ELSE NULL END), 0) AS Attachments_2,
				ROUND(CAST(SUM(ISNULL(F.Size, 0)) AS float) / 1024 / 1024, 2) AS AttachmentSizeMB,
				ROUND(CAST(SUM(ISNULL(CASE WHEN F.[Period] = 1 THEN F.Size ELSE 0 END, 0)) AS float) / 1024 / 1024, 2) AS AttachmentSizeMB_1,
				ROUND(CAST(SUM(ISNULL(CASE WHEN F.[Period] = 2 THEN F.Size ELSE 0 END, 0)) AS float) / 1024 / 1024, 2) AS AttachmentSizeMB_2
		FROM Applications AS App
			INNER JOIN Files AS F
			ON F.ApplicationID = App.ApplicationID
		GROUP BY App.ApplicationID
	),
	Aggregated
	AS
	(
		SELECT	App.Title,
				App.MembersCount,
				App.TemplatesCount AS TotalTemplatesCount,
				ISNULL(ND.CreatedNodesCount, 0) AS CreatedNodesCount,
				ISNULL(ND.CreatedNodesCount_1, 0) AS CreatedNodesCount_1,
				ISNULL(ND.CreatedNodesCount_2, 0) AS CreatedNodesCount_2,
				ISNULL(ND.UsedTemplatesCount, 0) AS UsedTemplatesCount,
				ISNULL(ND.UsedTemplatesCount_1, 0) AS UsedTemplatesCount_1,
				ISNULL(ND.UsedTemplatesCount_2, 0) AS UsedTemplatesCount_2,
				ISNULL(LG.LoginCount, 0) AS LoginCount,
				ISNULL(LG.LoginCount_1, 0) AS LoginCount_1,
				ISNULL(LG.LoginCount_2, 0) AS LoginCount_2,
				ISNULL(SH.SearchCount, 0) AS SearchCount,
				ISNULL(SH.SearchCount_1, 0) AS SearchCount_1,
				ISNULL(SH.SearchCount_2, 0) AS SearchCount_2,
				ISNULL(F.Attachments, 0) AS Attachments,
				ISNULL(F.Attachments_1, 0) AS Attachments_1,
				ISNULL(F.Attachments_2, 0) AS Attachments_2,
				ISNULL(F.AttachmentSizeMB, 0) AS AttachmentSizeMB,
				ISNULL(F.AttachmentSizeMB_1, 0) AS AttachmentSizeMB_1,
				ISNULL(F.AttachmentSizeMB_2, 0) AS AttachmentSizeMB_2
		FROM Applications AS App
			LEFT JOIN AggregatedNodes AS ND
			ON ND.ApplicationID = App.ApplicationID
			LEFT JOIN AggregatedLogin AS LG
			ON LG.ApplicationID = App.ApplicationID
			LEFT JOIN AggregatedSearch AS SH
			ON SH.ApplicationID = App.ApplicationID
			LEFT JOIN AggregatedFiles AS F
			ON F.ApplicationID = App.ApplicationID
	)
	SELECT	A.Title AS TeamName,
			A.MembersCount,
			A.TotalTemplatesCount,
			A.CreatedNodesCount,
			A.CreatedNodesCount_1,
			A.CreatedNodesCount_2,
			CAST(ROUND((CASE 
				WHEN A.CreatedNodesCount_1 = 0 THEN 0 
				ELSE ((CAST(A.CreatedNodesCount_2 AS float) / CAST(A.CreatedNodesCount_1 AS float)) - 1) * 100
			END), 0) AS varchar(10)) + '%' AS CreatedNodesChange,
			A.UsedTemplatesCount,
			A.UsedTemplatesCount_1,
			A.UsedTemplatesCount_2,
			CAST(ROUND((CASE 
				WHEN A.UsedTemplatesCount_1 = 0 THEN 0 
				ELSE ((CAST(A.UsedTemplatesCount_2 AS float) / CAST(A.UsedTemplatesCount_1 AS float)) - 1) * 100
			END), 0) AS varchar(10)) + '%' AS UsedTemplatesChange,
			A.LoginCount,
			A.LoginCount_1,
			A.LoginCount_2,
			CAST(ROUND((CASE 
				WHEN A.LoginCount_1 = 0 THEN 0 
				ELSE ((CAST(A.LoginCount_2 AS float) / CAST(A.LoginCount_1 AS float)) - 1) * 100
			END), 0) AS varchar(10)) + '%' AS LoginCountChange,
			A.SearchCount,
			A.SearchCount_1,
			A.SearchCount_2,
			CAST(ROUND((CASE 
				WHEN A.SearchCount_1 = 0 THEN 0 
				ELSE ((CAST(A.SearchCount_2 AS float) / CAST(A.SearchCount_1 AS float)) - 1) * 100
			END), 0) AS varchar(10)) + '%' AS SearchCountChange,
			A.Attachments,
			A.Attachments_1,
			A.Attachments_2,
			CAST(ROUND((CASE 
				WHEN A.Attachments_1 = 0 THEN 0 
				ELSE ((CAST(A.Attachments_2 AS float) / CAST(A.Attachments_1 AS float)) - 1) * 100
			END), 0) AS varchar(10)) + '%' AS AttachmentsChange,
			A.AttachmentSizeMB,
			A.AttachmentSizeMB_1,
			A.AttachmentSizeMB_2,
			CAST(ROUND((CASE 
				WHEN A.AttachmentSizeMB_1 = 0 THEN 0 
				ELSE ((CAST(A.AttachmentSizeMB_2 AS float) / CAST(A.AttachmentSizeMB_1 AS float)) - 1) * 100
			END), 0) AS varchar(10)) + '%' AS AttachmentSizeMBChange
	FROM Aggregated AS A
END

GO