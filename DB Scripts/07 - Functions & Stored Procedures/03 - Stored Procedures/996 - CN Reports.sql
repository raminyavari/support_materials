USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_NodesListReport]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_NodesListReport]
GO

CREATE PROCEDURE [dbo].[CN_NodesListReport]
	@ApplicationID			uniqueidentifier,
	@CurrentUserID			uniqueidentifier,
    @NodeTypeID				uniqueidentifier,
    @SearchText				nvarchar(1000),
    @Status					varchar(100),
    @MinContributorsCount	int,
    @LowerCreationDateLimit	datetime,
    @UpperCreationDateLimit	datetime,
    @FormFiltersTemp		FormFilterTableType readonly,
    @delimiter				char
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @FormFilters FormFilterTableType
	INSERT INTO @FormFilters SELECT * FROM @FormFiltersTemp
	
	SET @SearchText = [dbo].[GFN_GetSearchText](@SearchText)
	
	DECLARE @Results Table (
		NodeID_Hide uniqueidentifier primary key clustered,
		Name nvarchar(1000),
		AdditionalID varchar(1000),
		NodeType nvarchar(1000),
		Classification nvarchar(250),
		Description_HTML nvarchar(max),
		CreationDate datetime,
		PublicationDate datetime,
		CreatorUserID_Hide uniqueidentifier,
		CreatorName nvarchar(1000),
		CreatorUserName nvarchar(1000),
		OwnerID_Hide uniqueidentifier,
		OwnerName nvarchar(1000),
		OwnerType nvarchar(1000),
		Score float,
		Status_Dic nvarchar(100),
		WFState nvarchar(1000),
		UsersCount int,
		Collaboration float,
		MaxCollaboration float,
		UploadSize float
	)
	
	IF @SearchText IS NULL BEGIN
		INSERT INTO @Results
		SELECT	ND.NodeID AS NodeID_Hide,
				ND.NodeName AS Name,
				ND.NodeAdditionalID AS AdditionalID,
				ND.TypeName AS NodeType,
				Conf.[Level] AS Classification,
				ND.[Description] AS Description_HTML,
				ND.CreationDate,
				ND.PublicationDate,
				ND.CreatorUserID AS CreatorUserID_Hide,
				(ISNULL(UN.FirstName, N'') + N' ' + ISNULL(UN.LastName, N'')) AS CreatorName,
				UN.UserName AS CreatorUserName,
				ND.OwnerID AS OwnerID_Hide,
				OW.NodeName AS OwnerName,
				OW.TypeName AS OwnerType,
				ND.Score * ISNULL(KT.ScoreScale, 10) / 10,
				ND.[Status],
				ND.WFState,
				Ref.UsersCount,
				Ref.Collaboration,
				Ref.MaxCollaboration,
				Ref.UploadSize
		FROM (
				SELECT	ND.NodeID, 
						ISNULL(COUNT(NC.UserID), 0) AS UsersCount, 
						CASE
							WHEN ISNULL(COUNT(NC.UserID), 1) = 0 THEN 0
							ELSE ISNULL(SUM(NC.CollaborationShare), 0) / ISNULL(COUNT(NC.UserID), 1)
						END AS Collaboration,
						ISNULL(MAX(NC.CollaborationShare), 0) AS MaxCollaboration,
						SUM(ISNULL(F.Size, 0)) / (1024.0 * 1024.0) AS UploadSize
				FROM [dbo].[CN_Nodes] AS ND
					LEFT JOIN [dbo].[CN_NodeCreators] AS NC
					ON NC.ApplicationID = @ApplicationID AND 
						NC.NodeID = ND.NodeID AND NC.Deleted = 0
					LEFT JOIN [dbo].[DCT_Files] AS F
					ON F.ApplicationID = @ApplicationID AND F.OwnerID = ND.NodeID AND 
						(F.OwnerType = N'Node') AND F.Deleted = 0
				WHERE ND.ApplicationID = @ApplicationID AND 
					(@NodeTypeID IS NULL OR ND.NodeTypeID = @NodeTypeID) AND 
					(@Status IS NULL OR ND.[Status] = @Status) AND ND.Deleted = 0 AND
					(@LowerCreationDateLimit IS NULL OR ND.CreationDate >= @LowerCreationDateLimit) AND
					(@UpperCreationDateLimit IS NULL OR ND.CreationDate <= @UpperCreationDateLimit)
				GROUP BY ND.NodeID
			) AS Ref
			INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
			ON ND.ApplicationID = @ApplicationID AND ND.NodeID = Ref.NodeID
			LEFT JOIN [dbo].[KW_KnowledgeTypes] AS KT
			ON KT.ApplicationID = @ApplicationID AND KT.KnowledgeTypeID = ND.NodeTypeID
			LEFT JOIN [dbo].[Users_Normal] AS UN
			ON UN.ApplicationID = @ApplicationID AND UN.UserID = ND.CreatorUserID
			LEFT JOIN [dbo].[CN_View_Nodes_Normal] AS OW
			ON OW.ApplicationID = @ApplicationID AND OW.NodeID = ND.OwnerID
			LEFT JOIN [dbo].[PRVC_View_Confidentialities] AS Conf
			ON Conf.ApplicationID = @ApplicationID AND Conf.ObjectID = ND.NodeID
		WHERE (@MinContributorsCount IS NULL OR Ref.UsersCount >= @MinContributorsCount)
	END
	ELSE BEGIN
		INSERT INTO @Results
		SELECT	ND.NodeID AS NodeID_Hide,
				ND.NodeName AS Name,
				ND.NodeAdditionalID AS AdditionalID,
				ND.TypeName AS NodeType,
				Conf.[Level] AS Classification,
				ND.[Description] AS Description_HTML,
				ND.CreationDate,
				ND.PublicationDate,
				ND.CreatorUserID AS CreatorUserID_Hide,
				(ISNULL(UN.FirstName, N'') + N' ' + ISNULL(UN.LastName, N'')) AS CreatorName,
				UN.UserName AS CreatorUserName,
				ND.OwnerID AS OwnerID_Hide,
				OW.NodeName AS OwnerName,
				OW.TypeName AS OwnerType,
				ND.Score * ISNULL(KT.ScoreScale, 10) / 10,
				ND.[Status],
				ND.WFState,
				Ref.UsersCount,
				Ref.Collaboration,
				Ref.MaxCollaboration,
				Ref.UploadSize
		FROM (
				SELECT	ND.NodeID, 
						ISNULL(COUNT(NC.UserID), 0) AS UsersCount, 
						CASE
							WHEN ISNULL(COUNT(NC.UserID), 1) = 0 THEN 0
							ELSE ISNULL(SUM(NC.CollaborationShare), 0) / ISNULL(COUNT(NC.UserID), 1)
						END AS Collaboration,
						ISNULL(MAX(NC.CollaborationShare), 0) AS MaxCollaboration,
						SUM(ISNULL(F.Size, 0)) / (1024.0 * 1024.0) AS UploadSize
				FROM CONTAINSTABLE([dbo].[CN_Nodes], ([Name]), @SearchText) AS SRCH
					INNER JOIN [dbo].[CN_Nodes] AS ND
					ON ND.ApplicationID = @ApplicationID AND ND.NodeID = SRCH.[Key]
					LEFT JOIN [dbo].[CN_NodeCreators] AS NC
					ON NC.ApplicationID = @ApplicationID AND 
						NC.NodeID = ND.NodeID AND NC.Deleted = 0
					LEFT JOIN [dbo].[DCT_Files] AS F
					ON F.ApplicationID = @ApplicationID AND F.OwnerID = ND.NodeID AND 
						(F.OwnerType = N'Node') AND F.Deleted = 0
				WHERE (@NodeTypeID IS NULL OR ND.NodeTypeID = @NodeTypeID) AND 
					(@Status IS NULL OR ND.[Status] = @Status) AND ND.Deleted = 0 AND
					(@LowerCreationDateLimit IS NULL OR ND.CreationDate >= @LowerCreationDateLimit) AND
					(@UpperCreationDateLimit IS NULL OR ND.CreationDate <= @UpperCreationDateLimit)
				GROUP BY ND.NodeID
			) AS Ref
			INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
			ON ND.ApplicationID = @ApplicationID AND ND.NodeID = Ref.NodeID
			LEFT JOIN [dbo].[KW_KnowledgeTypes] AS KT
			ON KT.ApplicationID = @ApplicationID AND KT.KnowledgeTypeID = ND.NodeTypeID
			LEFT JOIN [dbo].[Users_Normal] AS UN
			ON UN.ApplicationID = @ApplicationID AND UN.UserID = ND.CreatorUserID
			LEFT JOIN [dbo].[CN_View_Nodes_Normal] AS OW
			ON OW.ApplicationID = @ApplicationID AND OW.NodeID = ND.OwnerID
			LEFT JOIN [dbo].[PRVC_View_Confidentialities] AS Conf
			ON Conf.ApplicationID = @ApplicationID AND Conf.ObjectID = ND.NodeID
		WHERE (@MinContributorsCount IS NULL OR Ref.UsersCount >= @MinContributorsCount)
	END
	
	DECLARE @NodeIDs GuidTableType
	
	INSERT INTO @NodeIDs
	SELECT Ref.NodeID_Hide
	FROM @Results AS Ref
	
	DECLARE @InstanceIDs GuidTableType
	
	DECLARE @FormID uniqueidentifier = NULL
	
	IF @NodeTypeID IS NOT NULL BEGIN
		SET @FormID = (
			SELECT TOP(1) FormID
			FROM [dbo].[FG_FormOwners]
			WHERE ApplicationID = @ApplicationID AND OwnerID = @NodeTypeID AND Deleted = 0
		)
	END
	
	IF @FormID IS NOT NULL AND (SELECT COUNT(Ref.ElementID) FROM @FormFilters AS Ref) > 0 BEGIN
		DECLARE @FormInstanceOwners Table (InstanceID uniqueidentifier, OwnerID uniqueidentifier)
	
		INSERT INTO @FormInstanceOwners (InstanceID, OwnerID)
		SELECT FI.InstanceID, FI.OwnerID
		FROM @NodeIDs AS Ref 
			INNER JOIN [dbo].[FG_FormInstances] AS FI
			ON FI.ApplicationID = @ApplicationID AND FI.OwnerID = Ref.Value AND FI.Deleted = 0
		
		INSERT INTO @InstanceIDs (Value)
		SELECT DISTINCT Ref.InstanceID
		FROM @FormInstanceOwners AS Ref
		
		DELETE N
		FROM @NodeIDs AS N
			LEFT JOIN @FormInstanceOwners AS O
			ON O.OwnerID = N.Value
			LEFT JOIN [dbo].[FG_FN_FilterInstances](
				@ApplicationID, NULL, @InstanceIDs, @FormFilters, @delimiter, 1
			) AS Ref
			ON Ref.InstanceID = O.InstanceID
		WHERE Ref.InstanceID IS NULL
		
		DELETE I
		FROM @InstanceIDs AS I
			LEFT JOIN @FormInstanceOwners AS O
			LEFT JOIN @NodeIDs AS N
			ON N.Value = O.OwnerID
			ON O.InstanceID = I.Value
		WHERE O.InstanceID IS NULL OR N.Value IS NULL
	END
	
	SELECT R.*
	FROM @NodeIDs AS N
		INNER JOIN @Results AS R
		ON R.NodeID_Hide = N.Value
	
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
		   '}') AS Actions

	IF @FormID IS NOT NULL AND EXISTS(
		SELECT TOP(1) *
		FROM [dbo].[CN_Extensions] AS Ex
		WHERE Ex.ApplicationID = @ApplicationID AND 
			Ex.OwnerID = @NodeTypeID AND Ex.Extension = N'Form' AND Ex.Deleted = 0
	) BEGIN
		-- Second Part: Describes the Third Part
		SELECT CAST(EFE.ElementID AS varchar(50)) AS ColumnName, EFE.Title AS Translation,
			CASE
				WHEN EFE.[Type] = N'Binary' THEN N'bool'
				WHEN EFE.[Type] = N'Number' THEN N'double'
				WHEN EFE.[Type] = N'Date' THEN N'datetime'
				WHEN EFE.[Type] = N'User' THEN N'user'
				WHEN EFE.[Type] = N'Node' THEN N'node'
				ELSE N'string'
			END AS [Type]
		FROM [dbo].[FG_ExtendedFormElements] AS EFE
		WHERE EFE.ApplicationID = @ApplicationID AND 
			EFE.FormID = @FormID AND EFE.Deleted = 0
		ORDER BY EFE.SequenceNumber ASC
		
		SELECT ('{"IsDescription": "true"}') AS Info
		-- end of Second Part
		
		-- Third Part: The Form Info
		DECLARE @ElementIDs GuidTableType
		DECLARE @FakeOwnerIDs GuidTableType, @FakeFilters FormFilterTableType
		
		EXEC [dbo].[FG_P_GetFormRecords] @ApplicationID, @FormID, @ElementIDs, 
			@InstanceIDs, @FakeOwnerIDs, @FakeFilters, NULL, 1000000, NULL, NULL
		
		SELECT ('{' +
			'"ColumnsMap": "NodeID_Hide:OwnerID",' +
			'"ColumnsToTransfer": "' + STUFF((
				SELECT ',' + CAST(EFE.ElementID AS varchar(50))
				FROM [dbo].[FG_ExtendedFormElements] AS EFE
				WHERE EFE.ApplicationID = @ApplicationID AND 
					EFE.FormID = @FormID AND EFE.Deleted = 0
				ORDER BY EFE.SequenceNumber ASC
				FOR xml path('a'), type
			).value('.','nvarchar(max)'), 1, 1, '') + '"' +
		   '}') AS Info
		-- End of Third Part
	END
	
	
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
			FROM @NodeIDs AS IDs
				INNER JOIN [dbo].[CN_NodeCreators] AS C
				ON C.ApplicationID = @ApplicationID AND C.NodeID = IDs.Value AND C.Deleted = 0
		) AS X
		
	DECLARE @Count int = ISNULL((SELECT MAX(RowNumber) FROM #Result), 0)
	DECLARE @ItemsList varchar(max) = N'', @SelectList varchar(max) = N'', @ColsToTransfer varchar(max) = N''
	
	SET @Proc = N''
	
	IF @Count > 0 BEGIN
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
	END

	-- end of Add Contributor Columns
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_MostFavoriteNodesReport]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_MostFavoriteNodesReport]
GO

CREATE PROCEDURE [dbo].[CN_MostFavoriteNodesReport]
	@ApplicationID	uniqueidentifier,
	@CurrentUserID	uniqueidentifier,
	@Count			int,
	@NodeTypeID		uniqueidentifier,
	@BeginDate		datetime,
	@FinishDate		datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF @Count IS NULL SET @Count = 20
	
	SELECT TOP(@Count) 
		nd.NodeID AS NodeID_Hide, 
		nd.NodeName, 
		nd.TypeName, 
		Conf.[Level] AS Classification,
		ref.cnt AS [Count]
	FROM (
			SELECT nl.NodeID, COUNT(nl.UserID) AS cnt
			FROM [dbo].[CN_NodeLikes] AS nl
			WHERE nl.ApplicationID = @ApplicationID AND 
				(@BeginDate IS NULL OR nl.LikeDate >= @BeginDate) AND
				(@FinishDate IS NULL OR nl.LikeDate <= @FinishDate) AND
				nl.Deleted = 0
			GROUP BY nl.NodeID
		) AS ref
		INNER JOIN [dbo].[CN_View_Nodes_Normal] AS nd
		ON nd.ApplicationID = @ApplicationID AND nd.NodeID = ref.NodeID
		LEFT JOIN [dbo].[PRVC_View_Confidentialities] AS Conf
		ON Conf.ApplicationID = @ApplicationID AND Conf.ObjectID = ND.NodeID
	WHERE (@NodeTypeID IS NULL OR nd.NodeTypeID = @NodeTypeID) AND nd.Deleted = 0
	ORDER BY ref.cnt DESC
	
	SELECT ('{' +
			'"NodeName": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'}' +
		   '}') AS Actions
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_CreatorUsersReport]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_CreatorUsersReport]
GO

CREATE PROCEDURE [dbo].[CN_CreatorUsersReport]
	@ApplicationID			uniqueidentifier,
	@CurrentUserID			uniqueidentifier,
	@NodeID					uniqueidentifier,
	@MembershipNodeTypeID	uniqueidentifier,
	@MembershipNodeID		uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT NC.UserID AS UserID_Hide,
		(UN.FirstName + N' ' + UN.LastName) AS Name, UN.UserName AS UserName,
		NC.CollaborationShare AS Collaboration
	FROM [dbo].[CN_NodeCreators] AS NC
		INNER JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND UN.UserID = NC.UserID
	WHERE NC.ApplicationID = @ApplicationID AND NC.NodeID = @NodeID AND NC.Deleted = 0 AND
		((@MembershipNodeID IS NULL AND @MembershipNodeTypeID IS NULL) OR EXISTS(
			SELECT TOP(1) *
			FROM [dbo].[CN_View_NodeMembers] AS NM
				INNER JOIN [dbo].[CN_Nodes] AS ND
				ON ND.ApplicationID = @ApplicationID AND ND.NodeID = NM.NodeID
			WHERE NM.ApplicationID = @ApplicationID AND 
				(
					(@MembershipNodeID IS NULL AND ND.NodeTypeID = @MembershipNodeTypeID) OR
					(@MembershipNodeID IS NOT NULL AND ND.NodeID = @MembershipNodeID)
				) AND NM.UserID = UN.UserID AND NM.IsPending = 0 AND ND.Deleted = 0
		))

	
	SELECT ('{' +
			'"Name": {"Action": "Link", "Type": "User",' +
				'"Requires": {"ID": "UserID_Hide"}' +
			'}' +
		   '}') AS Actions
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_NodeCreatorsReport]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_NodeCreatorsReport]
GO

CREATE PROCEDURE [dbo].[CN_NodeCreatorsReport]
	@ApplicationID			uniqueidentifier,
	@CurrentUserID			uniqueidentifier,
	@NodeTypeID				uniqueidentifier,
	@strUserIDs				varchar(max),
	@strNodeIDs				varchar(max),
	@delimiter				char,
	@ShowPersonalItems		bit,
	@LowerCreationDateLimit datetime,
	@UpperCreationDateLimit datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserIDs GuidTableType
	
	INSERT INTO @UserIDs
	SELECT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strUserIDs, @delimiter) AS Ref
	
	DECLARE @NodeIDs GuidTableType, @NodeUserIDs GuidTableType
	
	INSERT INTO @NodeIDs
	SELECT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strNodeIDs, @delimiter) AS Ref
	
	INSERT INTO @NodeUserIDs
	EXEC [dbo].[CN_P_GetMemberUserIDs] @ApplicationID, @NodeIDs, N'Accepted', NULL
	
	INSERT INTO @UserIDs
	SELECT Ref.Value
	FROM @NodeUserIDs AS Ref
	WHERE Ref.Value NOT IN (SELECT U.Value FROM @UserIDs AS U)
	
	IF((SELECT COUNT(*) FROM @UserIDs) = 0) BEGIN
		INSERT INTO @UserIDs
		SELECT UserID
		FROM [dbo].[Users_Normal]
		WHERE ApplicationID = @ApplicationID AND IsApproved = 1
	END

	DECLARE @DepTypeIDs GuidTableType
	INSERT INTO @DepTypeIDs (Value)
	SELECT Ref.NodeTypeID
	FROM [dbo].[CN_FN_GetDepartmentNodeTypeIDs](@ApplicationID) AS Ref

	SELECT UN.UserID AS UserID_Hide, 
		CAST(MAX(CAST(ND.NodeID AS varchar(36))) AS uniqueidentifier) AS DepartmentID_Hide,
		(MAX(UN.FirstName) + N' ' + MAX(UN.LastName)) AS Name, 
		MAX(UN.UserName) AS UserName,  
		MAX(ND.Name) AS Department, 
		MAX(Ref.[Count]) AS [Count], 
		MAX(Ref.Personal) AS PersonalCount, 
		MAX(Ref.[Group]) AS GroupCount, 
		MAX(Ref.Collaboration) AS Collaboration,
		MAX(Ref.UploadSize) AS UploadSize
	FROM
		(
			SELECT NC.UserID, 
				COUNT(NC.NodeID) AS [Count],
				SUM(
					CASE
						WHEN NC.CollaborationShare = 100 THEN 1
						ELSE 0
					END
				) AS Personal,
				SUM(
					CASE
						WHEN NC.CollaborationShare = 100 THEN 0
						ELSE 1
					END
				) AS [Group],
				CASE
					WHEN ISNULL(COUNT(NC.UserID), 1) = 0 THEN 0
					ELSE ISNULL(SUM(NC.CollaborationShare), 0) / ISNULL(COUNT(NC.UserID), 1)
				END AS Collaboration,
				SUM(ISNULL(F.Size, 0)) / (1024.0 * 1024.0) AS UploadSize
			FROM @UserIDs AS UDS
				INNER JOIN [dbo].[CN_NodeCreators] AS NC
				ON NC.ApplicationID = @ApplicationID AND NC.UserID = UDS.Value
				INNER JOIN [dbo].[CN_Nodes] AS ND
				ON ND.ApplicationID = @ApplicationID AND ND.NodeID = NC.NodeID
				LEFT JOIN [dbo].[DCT_Files] AS F
				ON F.ApplicationID = @ApplicationID AND F.OwnerID = ND.NodeID AND 
					(F.OwnerType = N'Node') AND F.Deleted = 0
			WHERE NC.Deleted = 0 AND ND.Deleted = 0 AND
				(@NodeTypeID IS NULL OR ND.NodeTypeID = @NodeTypeID) AND
				(@ShowPersonalItems IS NULL OR
					(@ShowPersonalItems = 1 AND NC.CollaborationShare = 100) OR
					(@ShowPersonalItems = 0 AND NC.CollaborationShare < 100)
				) AND
				(@LowerCreationDateLimit IS NULL OR ND.CreationDate >= @LowerCreationDateLimit) AND
				(@UpperCreationDateLimit IS NULL OR ND.CreationDate <= @UpperCreationDateLimit)
			GROUP BY NC.UserID
		) AS Ref
		INNER JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND Ref.UserID = UN.UserID
		LEFT JOIN [dbo].[CN_NodeMembers] AS NM
		LEFT JOIN [dbo].[CN_Nodes] AS ND
		ON ND.ApplicationID = @ApplicationID AND 
			ND.NodeTypeID IN (SELECT Value FROM @DepTypeIDs) AND ND.Deleted = 0
		ON NM.ApplicationID = @ApplicationID AND 
			NM.NodeID = ND.NodeID AND  NM.UserID = UN.UserID AND NM.Deleted = 0
	GROUP BY UN.UserID
	ORDER BY MAX(Ref.[Count]) DESC
	
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
		   			'"Title": "~[[Name]] (~[[UserName]])"}}, ' + 
		   		'"Params": {"ShowPersonalItems": null}' + 
		   	'},' +
		    '"PersonalCount": {"Action": "Report", 
		   		"ModuleIdentifier": "CN", "ReportName": "UserCreatedNodesReport",' +
		   		'"Requires": {"UserID": {"Value": "UserID_Hide", ' + 
		   			'"Title": "~[[Name]] (~[[UserName]])"}}, ' + 
		   		'"Params": {"ShowPersonalItems": true}' + 
		   	'},' +
		   	'"GroupCount": {"Action": "Report", 
		   		"ModuleIdentifier": "CN", "ReportName": "UserCreatedNodesReport",' +
		   		'"Requires": {"UserID": {"Value": "UserID_Hide", ' + 
		   			'"Title": "~[[Name]] (~[[UserName]])"}}, ' + 
		   		'"Params": {"ShowPersonalItems": false}' + 
		   	'}' +
		   '}') AS Actions
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_UserCreatedNodesReport]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_UserCreatedNodesReport]
GO

CREATE PROCEDURE [dbo].[CN_UserCreatedNodesReport]
	@ApplicationID			uniqueidentifier,
	@CurrentUserID			uniqueidentifier,
	@NodeTypeID				uniqueidentifier,
	@UserID					uniqueidentifier,
	@ShowPersonalItems		bit,
	@LowerCreationDateLimit datetime,
	@UpperCreationDateLimit datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserIDs GuidTableType

	SELECT	NC.NodeID AS NodeID_Hide, 
			ND.Name AS NodeName, 
			ND.AdditionalID AS AdditionalID,
			Conf.[Level] AS Classification,
			NC.CollaborationShare, ND.CreationDate AS CreationDate,
			ISNULL((
				SELECT SUM(ISNULL(F.Size, 0))
				FROM [dbo].[DCT_Files] AS F
				WHERE F.ApplicationID = @ApplicationID AND F.OwnerID = NC.NodeID AND 
					(F.OwnerType = N'Node') AND F.Deleted = 0
			), 0) / (1024.0 * 1024.0) AS UploadSize
	FROM [dbo].[CN_NodeCreators] AS NC
		INNER JOIN [dbo].[CN_Nodes] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.NodeID = NC.NodeID
		LEFT JOIN [dbo].[PRVC_View_Confidentialities] AS Conf
		ON Conf.ApplicationID = @ApplicationID AND Conf.ObjectID = ND.NodeID
	WHERE NC.ApplicationID = @ApplicationID AND 
		NC.UserID = @UserID AND NC.Deleted = 0 AND 
		(@NodeTypeID IS NULL OR ND.NodeTypeID = @NodeTypeID) AND 
		ND.Deleted = 0 AND
		(@ShowPersonalItems IS NULL OR
			(@ShowPersonalItems = 1 AND NC.CollaborationShare = 100) OR
			(@ShowPersonalItems = 0 AND NC.CollaborationShare < 100)
		) AND
		(@LowerCreationDateLimit IS NULL OR ND.CreationDate >= @LowerCreationDateLimit) AND
		(@UpperCreationDateLimit IS NULL OR ND.CreationDate <= @UpperCreationDateLimit)
	
	SELECT ('{' +
			'"NodeName": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'}' +
		   '}') AS Actions
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_NodesCreatedNodesReport]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_NodesCreatedNodesReport]
GO

CREATE PROCEDURE [dbo].[CN_NodesCreatedNodesReport]
	@ApplicationID			uniqueidentifier,
	@CurrentUserID			uniqueidentifier,
	@NodeTypeID				uniqueidentifier,
	@CreatorNodeTypeID		uniqueidentifier,
	@strNodeIDs				varchar(max),
	@delimiter				char,
	@ShowPersonalItems		bit,
	@LowerCreationDateLimit datetime, 
	@UpperCreationDateLimit datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeIDs GuidTableType
	INSERT INTO @NodeIDs
	SELECT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strNodeIDs, @delimiter) AS Ref
	
	IF @CreatorNodeTypeID IS NOT NULL AND (SELECT COUNT(*) FROM @NodeIDs) = 0 BEGIN
		INSERT INTO @NodeIDs
		SELECT NodeID
		FROM [dbo].[CN_Nodes]
		WHERE ApplicationID = @ApplicationID AND 
			NodeTypeID = @CreatorNodeTypeID AND Deleted = 0
	END
	

	SELECT	ND.NodeID AS NodeID_Hide, 
			MAX(ND.NodeName) AS [Node], 
			MAX(ND.TypeName) AS [NodeType], 
			COUNT(Ref.CreatedNodeID) AS [Count], 
			SUM(Ref.Personal) AS PersonalCount, 
			(COUNT(Ref.CreatedNodeID) - SUM(Ref.Personal)) AS GroupCount, 
			AVG(Ref.Collaboration) AS Collaboration,
			SUM(Ref.Published) AS Published,
			SUM(Ref.SentToAdmin) AS SentToAdmin,
			SUM(Ref.SentToEvaluators) AS SentToEvaluators,
			SUM(Ref.Accepted) AS Accepted,
			SUM(Ref.Rejected) AS Rejected,
			SUM(Ref.UploadSize) AS UploadSize
	FROM
		(
			SELECT NM.NodeID, NC.NodeID AS CreatedNodeID, 
				CAST(MAX(CASE WHEN NC.CollaborationShare = 100 THEN 1 ELSE 0 END) AS int) AS Personal,
				CASE
					WHEN ISNULL(COUNT(NC.UserID), 1) = 0 THEN 0
					ELSE ISNULL(SUM(NC.CollaborationShare), 0) / ISNULL(COUNT(NC.UserID), 1)
				END AS Collaboration,
				CASE WHEN MAX(CAST(ND.Searchable AS int)) = 1 THEN 1 ELSE 0 END AS Published,
				CASE WHEN MAX(ND.[Status]) = N'SentToAdmin' THEN 1 ELSE 0 END AS SentToAdmin,
				CASE WHEN MAX(ND.[Status]) = N'SentToEvaluators' THEN 1 ELSE 0 END AS SentToEvaluators,
				CASE WHEN MAX(ND.[Status]) = N'Accepted' THEN 1 ELSE 0 END AS Accepted,
				CASE WHEN MAX(ND.[Status]) = N'Rejected' THEN 1 ELSE 0 END AS Rejected,
				((SUM(ISNULL(F.Size, 0)) / (1024.0 * 1024.0)) / COUNT(DISTINCT NC.UserID)) AS UploadSize
			FROM @NodeIDs AS NDS
				INNER JOIN [dbo].[CN_NodeMembers] AS NM
				ON NM.ApplicationID = @ApplicationID AND NM.NodeID = NDS.Value AND NM.Deleted = 0
				INNER JOIN [dbo].[CN_NodeCreators] AS NC
				ON NC.ApplicationID = @ApplicationID AND NC.UserID = NM.UserID AND NC.Deleted = 0
				INNER JOIN [dbo].[CN_Nodes] AS ND
				ON ND.ApplicationID = @ApplicationID AND ND.NodeID = NC.NodeID AND ND.Deleted = 0
				LEFT JOIN [dbo].[DCT_Files] AS F
				ON F.ApplicationID = @ApplicationID AND F.OwnerID = ND.NodeID AND 
					(F.OwnerType = N'Node') AND F.Deleted = 0
			WHERE (@NodeTypeID IS NULL OR ND.NodeTypeID = @NodeTypeID) AND 
				(@ShowPersonalItems IS NULL OR
					(@ShowPersonalItems = 1 AND NC.CollaborationShare = 100) OR
					(@ShowPersonalItems = 0 AND NC.CollaborationShare < 100)
				) AND
				(@LowerCreationDateLimit IS NULL OR 
					ND.CreationDate >= @LowerCreationDateLimit) AND
				(@UpperCreationDateLimit IS NULL OR 
					ND.CreationDate <= @UpperCreationDateLimit)
			GROUP BY NM.NodeID, NC.NodeID
		) AS Ref
		INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.NodeID = Ref.NodeID
	GROUP BY ND.NodeID
	ORDER BY COUNT(Ref.CreatedNodeID) DESC

	
	SELECT ('{' +
			'"Node": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'},' +
		   	'"Count": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "CN", "ReportName": "NodeCreatedNodesReport",' +
		   		'"Requires": {"CreatorNodeID": {"Value": "NodeID_Hide", ' + 
		   		'"Title": "~[[Node]] (~[[NodeType]])"}}, ' + 
		   		'"Params": {"ShowPersonalItems": null}' + 
		   	'},' +
		   	'"PersonalCount": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "CN", "ReportName": "NodeCreatedNodesReport",' +
		   		'"Requires": {"CreatorNodeID": {"Value": "NodeID_Hide", ' + 
		   		'"Title": "~[[Node]] (~[[NodeType]])"}}, ' + 
		   		'"Params": {"ShowPersonalItems": true}' + 
		   	'},' +
		   	'"GroupCount": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "CN", "ReportName": "NodeCreatedNodesReport",' +
		   		'"Requires": {"CreatorNodeID": {"Value": "NodeID_Hide", ' + 
		   		'"Title": "~[[Node]] (~[[NodeType]])"}}, ' + 
		   		'"Params": {"ShowPersonalItems": false}' + 
		   	'},' +
		   	'"Published": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "CN", "ReportName": "NodeCreatedNodesReport",' +
		   		'"Requires": {"CreatorNodeID": {"Value": "NodeID_Hide", ' + 
		   		'"Title": "~[[Node]] (~[[NodeType]])"}}, ' + 
		   		'"Params": {"Published": true}' + 
		   	'},' +
		   	'"SentToAdmin": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "CN", "ReportName": "NodeCreatedNodesReport",' +
		   		'"Requires": {"CreatorNodeID": {"Value": "NodeID_Hide", ' + 
		   		'"Title": "~[[Node]] (~[[NodeType]])"}}, ' + 
		   		'"Params": {"Status": "SentToAdmin"}' + 
		   	'},' +
		   	'"SentToEvaluators": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "CN", "ReportName": "NodeCreatedNodesReport",' +
		   		'"Requires": {"CreatorNodeID": {"Value": "NodeID_Hide", ' + 
		   		'"Title": "~[[Node]] (~[[NodeType]])"}}, ' + 
		   		'"Params": {"Status": "SentToEvaluators"}' + 
		   	'},' +
		   	'"Accepted": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "CN", "ReportName": "NodeCreatedNodesReport",' +
		   		'"Requires": {"CreatorNodeID": {"Value": "NodeID_Hide", ' + 
		   		'"Title": "~[[Node]] (~[[NodeType]])"}}, ' + 
		   		'"Params": {"Status": "Accepted"}' + 
		   	'},' +
		   	'"Rejected": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "CN", "ReportName": "NodeCreatedNodesReport",' +
		   		'"Requires": {"CreatorNodeID": {"Value": "NodeID_Hide", ' + 
		   		'"Title": "~[[Node]] (~[[NodeType]])"}}, ' + 
		   		'"Params": {"Status": "Rejected"}' + 
		   	'}' +
		   '}') AS Actions
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_NodeCreatedNodesReport]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_NodeCreatedNodesReport]
GO

CREATE PROCEDURE [dbo].[CN_NodeCreatedNodesReport]
	@ApplicationID			uniqueidentifier,
	@CurrentUserID			uniqueidentifier,
	@NodeTypeID				uniqueidentifier,
	@CreatorNodeID			uniqueidentifier,
	@Status					varchar(50),
	@ShowPersonalItems		bit,
	@Published				bit,
	@LowerCreationDateLimit datetime, 
	@UpperCreationDateLimit datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT	NC.NodeID AS NodeID_Hide, 
			MAX(ND.NodeName) AS Node,
			MAX(ND.NodeAdditionalID) AS AdditionalID,
			MAX(ND.TypeName) AS NodeType,
			MAX(Conf.[Level]) AS Classification,
			CAST(MAX(CAST(ND.CreatorUserID AS varchar(40))) AS uniqueidentifier) AS CreatorUserID_Hide,
			MAX(ISNULL(UN.FirstName, N'') + N' ' + ISNULL(UN.LastName, N'')) AS CreatorName,
			MAX(UN.UserName) AS CreatorUserName,
			MAX(ND.CreationDate) AS CreationDate,
			ISNULL(COUNT(DISTINCT NC.UserID), 0) AS UsersCount, 
			CASE
				WHEN ISNULL(COUNT(NC.UserID), 1) = 0 THEN 0
				ELSE ISNULL(SUM(NC.CollaborationShare), 0) / ISNULL(COUNT(NC.UserID), 1)
			END AS Collaboration,
			CAST(MAX(CAST(ND.Searchable AS int)) AS bit) AS Published_Dic,
			MAX(ND.[Status]) AS Status_Dic,
			MAX(ND.WFState) AS WorkFlowState,
			((SUM(ISNULL(F.Size, 0)) / (1024.0 * 1024.0)) / ISNULL(COUNT(DISTINCT NC.UserID), 0)) AS UploadSize
	FROM [dbo].[CN_NodeMembers] AS NM
		INNER JOIN [dbo].[CN_NodeCreators] AS NC
		ON NC.ApplicationID = @ApplicationID AND NC.UserID = NM.UserID
		INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.NodeID = NC.NodeID
		LEFT JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND UN.UserID = ND.CreatorUserID
		LEFT JOIN [dbo].[DCT_Files] AS F
		ON F.ApplicationID = @ApplicationID AND F.OwnerID = ND.NodeID AND 
			(F.OwnerType = N'Node') AND F.Deleted = 0
		LEFT JOIN [dbo].[PRVC_View_Confidentialities] AS Conf
		ON Conf.ApplicationID = @ApplicationID AND Conf.ObjectID = ND.NodeID
	WHERE NM.ApplicationID = @ApplicationID AND NM.NodeID = @CreatorNodeID AND 
		(@NodeTypeID IS NULL OR ND.NodeTypeID = @NodeTypeID) AND
		NC.Deleted = 0 AND ND.Deleted = 0 AND NM.Deleted = 0 AND
		(ISNULL(@Status, N'') = N'' OR ND.[Status] = @Status) AND
		(@ShowPersonalItems IS NULL OR
			(@ShowPersonalItems = 1 AND NC.CollaborationShare = 100) OR
			(@ShowPersonalItems = 0 AND NC.CollaborationShare < 100)
		) AND
		(@Published IS NULL OR ISNULL(ND.Searchable, 1) = @Published) AND
		(@LowerCreationDateLimit IS NULL OR 
			ND.CreationDate >= @LowerCreationDateLimit) AND
		(@UpperCreationDateLimit IS NULL OR 
			ND.CreationDate <= @UpperCreationDateLimit)
	GROUP BY NC.NodeID

	
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
		   '}') AS Actions
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_NodesOwnNodesReport]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_NodesOwnNodesReport]
GO

CREATE PROCEDURE [dbo].[CN_NodesOwnNodesReport]
	@ApplicationID			uniqueidentifier,
	@CurrentUserID			uniqueidentifier,
	@NodeTypeID				uniqueidentifier,
	@CreatorNodeTypeID		uniqueidentifier,
	@strNodeIDs				varchar(max),
	@delimiter				char,
	@LowerCreationDateLimit datetime, 
	@UpperCreationDateLimit datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeIDs GuidTableType
	INSERT INTO @NodeIDs
	SELECT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strNodeIDs, @delimiter) AS Ref
	
	IF @CreatorNodeTypeID IS NOT NULL AND (SELECT COUNT(*) FROM @NodeIDs) = 0 BEGIN
		INSERT INTO @NodeIDs
		SELECT NodeID
		FROM [dbo].[CN_Nodes]
		WHERE ApplicationID = @ApplicationID AND 
			NodeTypeID = @CreatorNodeTypeID AND Deleted = 0
	END
	

	SELECT ND.NodeID AS NodeID_Hide, MAX(ND.NodeName) AS [Node], 
		MAX(ND.TypeName) AS [NodeType], MAX(Ref.[Count]) AS [Count]
	FROM
		(
			SELECT ND.OwnerID, COUNT(DISTINCT ND.NodeID) AS [Count]
			FROM @NodeIDs AS NDS
				INNER JOIN [dbo].[CN_Nodes] AS ND
				ON ND.ApplicationID = @ApplicationID AND ND.OwnerID = NDS.Value
			WHERE (@NodeTypeID IS NULL OR ND.NodeTypeID = @NodeTypeID) AND 
				ND.Deleted = 0 AND
				(@LowerCreationDateLimit IS NULL OR 
					ND.CreationDate >= @LowerCreationDateLimit) AND
				(@UpperCreationDateLimit IS NULL OR 
					ND.CreationDate <= @UpperCreationDateLimit)
			GROUP BY ND.OwnerID
		) AS Ref
		INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.NodeID = Ref.OwnerID
	GROUP BY ND.NodeID
	ORDER BY MAX(Ref.[Count]) DESC

	
	SELECT ('{' +
			'"Node": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'},' +
		   	'"Count": {"Action": "Report", 
		   		"ModuleIdentifier": "CN", "ReportName": "NodeOwnNodesReport",' +
		   		'"Requires": {"CreatorNodeID": {"Value": "NodeID_Hide", ' + 
		   		'"Title": "~[[Node]] (~[[NodeType]])"}} ' +
		   	'}' +
		   '}') AS Actions
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_NodeOwnNodesReport]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_NodeOwnNodesReport]
GO

CREATE PROCEDURE [dbo].[CN_NodeOwnNodesReport]
	@ApplicationID			uniqueidentifier,
	@CurrentUserID			uniqueidentifier,
	@NodeTypeID				uniqueidentifier,
	@CreatorNodeID			uniqueidentifier,
	@LowerCreationDateLimit datetime, 
	@UpperCreationDateLimit datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT	NC.NodeID AS NodeID_Hide, 
			MAX(ND.Name) AS Node,
			MAX(ND.AdditionalID) AS AdditionalID,
			MAX(Conf.[Level]) AS Classification,
			MAX(ND.CreationDate) AS CreationDate,
			COUNT(NC.UserID) AS UsersCount, 
			CASE
				WHEN ISNULL(COUNT(NC.UserID), 1) = 0 THEN 0
				ELSE ISNULL(SUM(NC.CollaborationShare), 0) / ISNULL(COUNT(NC.UserID), 1)
			END AS Collaboration,
			MAX(ND.WFState) AS WorkFlowState
	FROM [dbo].[CN_Nodes] AS ND
		INNER JOIN [dbo].[CN_NodeCreators] AS NC
		ON NC.ApplicationID = @ApplicationID AND NC.NodeID = ND.NodeID
		LEFT JOIN [dbo].[PRVC_View_Confidentialities] AS Conf
		ON Conf.ApplicationID = @ApplicationID AND Conf.ObjectID = ND.NodeID
	WHERE ND.ApplicationID = @ApplicationID AND ND.OwnerID = @CreatorNodeID AND 
		(@NodeTypeID IS NULL OR ND.NodeTypeID = @NodeTypeID) AND 
		NC.Deleted = 0 AND ND.Deleted = 0 AND
		(@LowerCreationDateLimit IS NULL OR 
			ND.CreationDate >= @LowerCreationDateLimit) AND
		(@UpperCreationDateLimit IS NULL OR 
			ND.CreationDate <= @UpperCreationDateLimit)
	GROUP BY NC.NodeID

	
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
		   '}') AS Actions
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_RelatedNodesCountReport]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_RelatedNodesCountReport]
GO

CREATE PROCEDURE [dbo].[CN_RelatedNodesCountReport]
	@ApplicationID		uniqueidentifier,
	@CurrentUserID		uniqueidentifier,
	@NodeTypeID			uniqueidentifier,
	@RelatedNodeTypeID	uniqueidentifier,
	@CreationDateFrom	datetime,
	@CreationDateTo		datetime,
	@In					bit,
	@Out				bit,
	@InTags				bit,
	@OutTags			bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @NodeIDs GuidTableType
	DECLARE @NodeTypeIDs GuidTableType
	DECLARE @RelatedNodeTypeIDs GuidTableType

	IF @NodeTypeID IS NULL RETURN

	INSERT INTO @NodeTypeIDs (Value)
	VALUES (@NodeTypeID)

	IF @RelatedNodeTypeID IS NOT NULL BEGIN
		INSERT INTO @RelatedNodeTypeIDs (Value)
		VALUES (@RelatedNodeTypeID)
	END

	SELECT	ND.NodeID AS NodeID_Hide,
			ND.NodeName AS Name,
			ND.NodeAdditionalID AS AdditionalID,
			X.CNT AS [Count]
	FROM (
			SELECT Ref.NodeID, COUNT(Ref.RelatedNodeID) AS CNT
			FROM [dbo].[CN_FN_GetRelatedNodeIDs](@ApplicationID, 
					@NodeIDs, @NodeTypeIDs, @RelatedNodeTypeIDs, @In, @Out, @InTags, @OutTags) AS Ref
			GROUP BY Ref.NodeID
		) AS X
		INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.NodeID = X.NodeID
	WHERE (@CreationDateFrom IS NULL OR ND.CreationDate >= @CreationDateFrom) AND
		(@CreationDateTo IS NULL OR ND.CreationDate < @CreationDateTo)
	ORDER BY X.CNT DESC, ND.CreationDate DESC
	
	SELECT ('{' +
			'"Name": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'},' +
			'"Count": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "CN", "ReportName": "RelatedNodesReport",' +
		   		'"Requires": {"NodeID": {"Value": "NodeID_Hide", "Title": "Name"}}, ' + 
		   		'"Params": {}' + 
		   	'}' +
		   '}') AS Actions
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_RelatedNodesReport]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_RelatedNodesReport]
GO

CREATE PROCEDURE [dbo].[CN_RelatedNodesReport]
	@ApplicationID		uniqueidentifier,
	@CurrentUserID		uniqueidentifier,
	@NodeID				uniqueidentifier,
	@RelatedNodeTypeID	uniqueidentifier,
	@CreationDateFrom	datetime,
	@CreationDateTo		datetime,
	@In					bit,
	@Out				bit,
	@InTags				bit,
	@OutTags			bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @NodeIDs GuidTableType
	DECLARE @NodeTypeIDs GuidTableType
	DECLARE @RelatedNodeTypeIDs GuidTableType

	IF @NodeID IS NULL RETURN

	INSERT INTO @NodeIDs (Value)
	VALUES (@NodeID)

	IF @RelatedNodeTypeID IS NOT NULL BEGIN
		INSERT INTO @RelatedNodeTypeIDs (Value)
		VALUES (@RelatedNodeTypeID)
	END

	SELECT	R.NodeID AS NodeID_Hide,
			R.NodeName AS Name,
			R.NodeAdditionalID AS AdditionalID,
			R.TypeName AS NodeType
	FROM [dbo].[CN_FN_GetRelatedNodeIDs](@ApplicationID, 
			@NodeIDs, @NodeTypeIDs, @RelatedNodeTypeIDs, @In, @Out, @InTags, @OutTags) AS Ref
		INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.NodeID = Ref.NodeID
		INNER JOIN [dbo].[CN_View_Nodes_Normal] AS R
		ON R.ApplicationID = @ApplicationID AND R.NodeID = Ref.RelatedNodeID
	WHERE (@CreationDateFrom IS NULL OR ND.CreationDate >= @CreationDateFrom) AND
		(@CreationDateTo IS NULL OR ND.CreationDate < @CreationDateTo)
	ORDER BY ND.CreationDate DESC
	
	SELECT ('{' +
			'"Name": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'}' +
		   '}') AS Actions
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_DownloadedFilesReport]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_DownloadedFilesReport]
GO

CREATE PROCEDURE [dbo].[CN_DownloadedFilesReport]
	@ApplicationID	uniqueidentifier,
	@CurrentUserID	uniqueidentifier,
	@strNodeTypeIDs	varchar(max),
	@strUserIDs		varchar(max),
	@Delimiter		char,
	@BeginDate		datetime, 
	@FinishDate		datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @NodeTypeIDs GuidTableType
	DECLARE @UserIDs GuidTableType
	
	INSERT INTO @NodeTypeIDs (Value)
	SELECT DISTINCT Ref.Value 
	FROM [dbo].[GFN_StrToGuidTable](@strNodeTypeIDs, @delimiter) AS Ref
	
	INSERT INTO @UserIDs (Value)
	SELECT DISTINCT Ref.Value 
	FROM [dbo].[GFN_StrToGuidTable](@strUserIDs, @delimiter) AS Ref

	DECLARE @HasUserID bit = CAST(ISNULL((SELECT TOP(1) 1 FROM @UserIDs), 0) AS bit)
	DECLARE @HasNodeTypeID bit = CAST(ISNULL((SELECT TOP(1) 1 FROM @NodeTypeIDs), 0) AS bit)
	
	DECLARE @Empty uniqueidentifier = N'00000000-0000-0000-0000-000000000000'
	
	DECLARE @Logs TABLE (LogID bigint, SubjectID uniqueidentifier, UserID uniqueidentifier, [Date] datetime)
	
	INSERT INTO @Logs (LogID, SubjectID, UserID, [Date])
	SELECT LG.LogID, LG.SubjectID, LG.UserID, LG.[Date]
	FROM [dbo].[LG_Logs] AS LG
	WHERE LG.ApplicationID = @ApplicationID AND LG.[Action] = N'Download' AND
		LG.SubjectID IS NOT NULL AND LG.SubjectID <> @Empty AND
		(@HasUserID = 0 OR LG.UserID IN (SELECT U.Value FROM @UserIDs AS U)) AND
		(@BeginDate IS NULL OR LG.[Date] >= @BeginDate) AND
		(@FinishDate IS NULL OR LG.[Date] <= @FinishDate)
		
	DECLARE @FileIDs GuidTableType
	
	INSERT INTO @FileIDs
	SELECT DISTINCT LG.SubjectID
	FROM @Logs AS LG
	WHERE LG.SubjectID IS NOT NULL
	
	DECLARE @Extensions StringTableType
	
	INSERT INTO @Extensions (Value)
	VALUES (N'jpg'), (N'png'), (N'gif'), (N'jpeg'), (N'bmp')
	
	SELECT TOP(2000)	
			((ROW_NUMBER() OVER (ORDER BY Ref.LogID_Hide DESC)) +
			(ROW_NUMBER() OVER (ORDER BY Ref.LogID_Hide ASC)) - 1) AS TotalCount_Hide,
			Ref.*
	FROM (
			SELECT	MAX(LG.LogID) AS LogID_Hide,
					CAST(MAX(CAST(X.NodeID AS varchar(50))) AS uniqueidentifier) AS NodeID_Hide,
					CAST(MAX(CAST(UN.UserID AS varchar(50))) AS uniqueidentifier) AS UserID_Hide,
					MAX(LTRIM(RTRIM(ISNULL(UN.FirstName, N'') + N' ' + ISNULL(UN.LastName, N'')))) AS FullName,
					MAX(UN.UserName) AS UserName,
					MAX(X.NodeName) AS NodeName,
					MAX(X.NodeType) AS NodeType,
					MAX(X.[FileName]) AS [FileName],
					MAX(X.Extension) AS Extension,
					MAX(LG.[Date]) AS LastDownloadDate,
					COUNT(DISTINCT LG.LogID) AS DownloadsCount
			FROM @Logs AS LG
				INNER JOIN [dbo].[DCT_FN_GetFileOwnerNodes](@ApplicationID, @FileIDs) AS X
				INNER JOIN [dbo].[DCT_Files] AS F
				ON F.ApplicationID = @ApplicationID AND F.FileNameGuid = X.FileID
				ON F.FileNameGuid = LG.SubjectID AND
					(@HasNodeTypeID = 0 OR X.NodeTypeID IN (SELECT A.Value FROM @NodeTypeIDs AS A))
				INNER JOIN [dbo].[Users_Normal] AS UN
				ON UN.ApplicationID = @ApplicationID AND UN.UserID = LG.UserID
			WHERE LOWER(ISNULL(X.Extension, N'')) NOT IN (SELECT A.Value FROM @Extensions AS A)
			GROUP BY LG.SubjectID, LG.UserID
		) AS Ref
	ORDER BY Ref.LogID_Hide DESC

	SELECT ('{' +
			'"NodeName": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'},' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'}' +
		   '}') AS Actions
END

GO