USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_UsersListReport]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_UsersListReport]
GO

CREATE PROCEDURE [dbo].[USR_UsersListReport]
	@ApplicationID			uniqueidentifier,
	@CurrentUserID			uniqueidentifier,
    @EmploymentType			varchar(20),
    @SearchText				nvarchar(1000),
    @IsApproved				bit,
    @LowerBirthDateLimit	datetime,
    @UpperBirthDateLimit	datetime,
    @LowerCreationDateLimit	datetime,
    @UpperCreationDateLimit	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @SearchText = [dbo].[GFN_GetSearchText](@SearchText)
	
	DECLARE @Results Table(UserID_Hide uniqueidentifier primary key clustered,
		Name nvarchar(1000), UserName nvarchar(1000), Birthday datetime,
		JobTitle nvarchar(1000), EmploymentType_Dic varchar(50), CreationDate datetime,
		DepartmentID_Hide uniqueidentifier, Department nvarchar(1000))
	
	IF @SearchText IS NULL BEGIN
		INSERT INTO @Results(
			UserID_Hide, Name, UserName, Birthday, JobTitle, EmploymentType_Dic, CreationDate
		)
		SELECT	UN.UserID AS UserID_Hide,
				LTRIM(RTRIM((ISNULL(UN.FirstName, N'') + N' ' + ISNULL(UN.LastName, N'')))) AS Name,
				UN.UserName AS UserName,
				UN.BirthDay,
				UN.JobTitle,
				UN.EmploymentType,
				UN.CreationDate
		FROM [dbo].[Users_Normal] AS UN
		WHERE UN.ApplicationID = @ApplicationID AND
			(@EmploymentType IS NULL OR UN.EmploymentType = @EmploymentType) AND
			(@LowerBirthDateLimit IS NULL OR UN.BirthDay >= @LowerBirthDateLimit) AND
			(@UpperBirthDateLimit IS NULL OR UN.BirthDay <= @UpperBirthDateLimit) AND
			(@LowerCreationDateLimit IS NULL OR UN.CreationDate >= @LowerCreationDateLimit) AND
			(@UpperCreationDateLimit IS NULL OR UN.CreationDate <= @UpperCreationDateLimit) AND 
			UN.IsApproved = ISNULL(@IsApproved, 1)
	END
	ELSE BEGIN
		INSERT INTO @Results(
			UserID_Hide, Name, UserName, Birthday, JobTitle, EmploymentType_Dic, CreationDate
		)
		SELECT	UN.UserID AS UserID_Hide,
				LTRIM(RTRIM((ISNULL(UN.FirstName, N'') + N' ' + ISNULL(UN.LastName, N'')))) AS Name,
				UN.UserName AS UserName,
				UN.BirthDay,
				UN.JobTitle,
				UN.EmploymentType,
				UN.CreationDate
		FROM CONTAINSTABLE([dbo].[USR_View_Users], 
			([UserName], [FirstName], [LastName]), @SearchText) AS SRCH
			INNER JOIN [dbo].[Users_Normal] AS UN
			ON UN.ApplicationID = @ApplicationID AND UN.UserID = SRCH.[Key]
		WHERE (@EmploymentType IS NULL OR UN.EmploymentType = @EmploymentType) AND
			(@LowerBirthDateLimit IS NULL OR UN.BirthDay >= @LowerBirthDateLimit) AND
			(@UpperBirthDateLimit IS NULL OR UN.BirthDay <= @UpperBirthDateLimit) AND
			(@LowerCreationDateLimit IS NULL OR UN.CreationDate >= @LowerCreationDateLimit) AND
			(@UpperCreationDateLimit IS NULL OR UN.CreationDate <= @UpperCreationDateLimit) AND
			UN.IsApproved = ISNULL(@IsApproved, 1)
	END
	
	DECLARE @DepTypeIDs GuidTableType
	INSERT INTO @DepTypeIDs (Value)
	SELECT Ref.NodeTypeID
	FROM [dbo].[CN_FN_GetDepartmentNodeTypeIDs](@ApplicationID) AS Ref
	
	UPDATE R
		SET DepartmentID_Hide = Ref.DepartmentID,
			Department = Ref.Department
	FROM @Results AS R
		INNER JOIN (
			SELECT T.UserID_Hide,
				CAST(MAX(CAST(ND.NodeID AS varchar(36))) AS uniqueidentifier) 
					AS DepartmentID,
				MAX(ND.Name) AS Department
			FROM @Results AS T
				LEFT JOIN [dbo].[CN_NodeMembers] AS NM
				LEFT JOIN [dbo].[CN_Nodes] AS ND
				ON ND.ApplicationID = @ApplicationID AND 
					ND.NodeTypeID IN (SELECT Value FROM @DepTypeIDs) AND ND.Deleted = 0
				ON NM.ApplicationID = @ApplicationID AND 
					NM.NodeID = ND.NodeID AND NM.UserID = T.UserID_Hide AND NM.Deleted = 0
			GROUP BY T.UserID_Hide
		) AS Ref
		ON R.UserID_Hide = Ref.UserID_Hide
		
	
	SELECT * FROM @Results
	
	SELECT ('{' +
			'"Name": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'},' +
			'"Department": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "DepartmentID_Hide"}' +
			'}' +
		   '}') AS Actions
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_InvitationsReport]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_InvitationsReport]
GO

CREATE PROCEDURE [dbo].[USR_InvitationsReport]
	@ApplicationID	uniqueidentifier,
	@CurrentUserID	UNIQUEIDENTIFIER,
    @BeginDate		DATETIME,
    @FinishDate		DATETIME
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	;WITH X AS(
		SELECT
			i.SenderUserID,
			COUNT(i.ID) AS SentInvitationsCount,
			COUNT(tu.UserID) AS RegisteredUsersCount,
			COUNT(un.UserID) AS ActivatedUsersCount
		FROM [USR_Invitations] AS i
			LEFT JOIN [USR_TemporaryUsers] AS tu
			ON tu.EMail = i.Email
			LEFT JOIN [Users_Normal] AS un
			ON un.ApplicationID = @ApplicationID AND un.UserID = tu.UserID
		WHERE i.ApplicationID = @ApplicationID AND 
			(@BeginDate IS NULL OR i.SendDate >= @BeginDate) AND
			(@FinishDate IS NULL OR i.SendDate <= @FinishDate)
		GROUP BY i.SenderUserID
	)
	SELECT 
		X.SenderUserID AS SenderUserID_Hide,
		un.FirstName + ' ' + un.LastName AS Name,
		X.SentInvitationsCount,
		X.RegisteredUsersCount,
		X.ActivatedUsersCount
	FROM X
		INNER JOIN [Users_Normal] AS un
		ON un.ApplicationID = @ApplicationID AND un.UserID = X.SenderUserID
	ORDER BY X.SentInvitationsCount DESC
	
	SELECT (
		'{' +
			'"Name": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "SenderUserID_Hide"}' +
			'}'+
		'}') AS Actions
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_UsersMembershipFlowReport]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_UsersMembershipFlowReport]
GO

CREATE PROCEDURE [dbo].[USR_UsersMembershipFlowReport]
	@ApplicationID					uniqueidentifier,
	@CurrentUserID					UNIQUEIDENTIFIER,
	@SenderUserID					UNIQUEIDENTIFIER,
    @LowerInvitationSentDateLimit	DATETIME,
    @UpperInvitationSentDateLimit	DATETIME
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT 
		un.UserID AS UserID_Hide,
		CASE
			WHEN (un.UserID IS NOT NULL) THEN un.FirstName + ' ' + un.LastName
			WHEN (tu.UserID IS NOT NULL) THEN tu.FirstName + ' ' + tu.LastName 
			ELSE N'بی نام'
		END AS Name,
		i.Email,
		i.SendDate AS ReceivedDate,
		tu.CreationDate AS RegisterationDate,
		un.CreationDate AS ActivationDate
	FROM [USR_Invitations] AS i
		LEFT JOIN [USR_TemporaryUsers] AS tu
		ON tu.EMail = i.Email
		LEFT JOIN [Users_Normal] AS un
		ON un.ApplicationID = @ApplicationID AND un.UserID = tu.UserID
	WHERE i.ApplicationID = @ApplicationID AND 
		(@SenderUserID IS NULL OR i.SenderUserID = @SenderUserID) AND
		(@LowerInvitationSentDateLimit IS NULL OR i.SendDate >= @LowerInvitationSentDateLimit) AND
		(@UpperInvitationSentDateLimit IS NULL OR i.SendDate <= @UpperInvitationSentDateLimit)
	ORDER BY i.SendDate DESC
	
	SELECT (
		'{' +
			'"Name": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'}'+
		'}') AS Actions
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_MostVisitedItemsReport]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_MostVisitedItemsReport]
GO

CREATE PROCEDURE [dbo].[USR_MostVisitedItemsReport]
	@ApplicationID		uniqueidentifier,
	@CurrentUserID		uniqueidentifier,
    @ItemType			varchar(20),
    @NodeTypeID			uniqueidentifier,
    @Count				int,
    @BeginDate			datetime,
    @FinishDate			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF @Count IS NULL OR @Count <= 0 SET @Count = 50
	
	DECLARE @Results Table (ItemID uniqueidentifier primary key clustered, 
		VisitsCount int, LastVisitDate datetime)
	
	IF @NodeTypeID IS NOT NULL BEGIN
		INSERT INTO @Results (ItemID, VisitsCount, LastVisitDate)
		SELECT TOP(@Count) Ref.ItemID, Ref.[Count], Ref.VisitDate
		FROM (
				SELECT IV.ItemID, COUNT(IV.ItemID) AS [Count], MAX(IV.VisitDate) AS VisitDate
				FROM [dbo].[USR_ItemVisits] AS IV
					INNER JOIN [dbo].[CN_Nodes] AS ND
					ON ND.ApplicationID = @ApplicationID AND ND.NodeID = IV.ItemID
				WHERE IV.ApplicationID = @ApplicationID AND ND.NodeTypeID = @NodeTypeID AND
					(@BeginDate IS NULL OR IV.VisitDate >= @BeginDate) AND
					(@FinishDate IS NULL OR IV.VisitDate <= @FinishDate)
				GROUP BY IV.ItemID
			) AS Ref
		ORDER BY Ref.[Count] DESC, Ref.VisitDate DESC
	END
	ELSE BEGIN
		INSERT INTO @Results (ItemID, VisitsCount, LastVisitDate)
		SELECT TOP(@Count) Ref.ItemID, Ref.[Count], Ref.VisitDate
		FROM (
				SELECT ItemID, COUNT(ItemID) AS [Count], MAX(VisitDate) AS VisitDate
				FROM [dbo].[USR_ItemVisits]
				WHERE ApplicationID = @ApplicationID AND ItemType = @ItemType AND
					(@BeginDate IS NULL OR VisitDate >= @BeginDate) AND
					(@FinishDate IS NULL OR VisitDate <= @FinishDate)
				GROUP BY ItemID
			) AS Ref
		ORDER BY Ref.[Count] DESC, Ref.VisitDate DESC
	END
	
	IF @ItemType = N'User' BEGIN
		SELECT R.ItemID AS ItemID_Hide, 
			(UN.FirstName + N' ' + UN.LastName) AS ItemName, 
			UN.UserName,
			R.VisitsCount
		FROM @Results AS R
			INNER JOIN [dbo].[Users_Normal] AS UN
			ON UN.ApplicationID = @ApplicationID AND UN.UserID = R.ItemID
		ORDER BY R.VisitsCount DESC, R.LastVisitDate DESC
	END
	ELSE BEGIN
		SELECT R.ItemID AS ItemID_Hide, ND.NodeName AS ItemName, R.VisitsCount
		FROM @Results AS R
			INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
			ON ND.ApplicationID = @ApplicationID AND ND.NodeID = R.ItemID
		ORDER BY R.VisitsCount DESC, R.LastVisitDate DESC
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_P_UsersPerformanceReport]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_P_UsersPerformanceReport]
GO

CREATE PROCEDURE [dbo].[USR_P_UsersPerformanceReport]
	@ApplicationID			uniqueidentifier,
    @UserGroupIDsTemp		GuidPairTableType readonly,
    @KnowledgeTypeIDsTemp	GuidTableType readonly,
    @CompensatePerScore		bit,
    @CompensationVolume		float,
    @ScoreItemsTemp			FloatStringTableType readonly,
    @BeginDate				datetime,
    @FinishDate				datetime
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Users TABLE (UserID uniqueidentifier primary key clustered, GroupID uniqueidentifier, GroupName nvarchar(500)) 
	INSERT INTO @Users (UserID, GroupID, GroupName)
	SELECT T.FirstValue, ND.NodeID, ND.Name
	FROM @UserGroupIDsTemp AS T
		LEFT JOIN [dbo].[CN_Nodes] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.NodeID = T.SecondValue
	
    DECLARE @KnowledgeTypeIDs GuidTableType
    INSERT INTO @KnowledgeTypeIDs SELECT * FROM @KnowledgeTypeIDsTemp
    
    DECLARE @ScoreItems FloatStringTableType
    INSERT INTO @ScoreItems SELECT * FROM @ScoreItemsTemp

	DECLARE @SharesOnWall bit = ISNULL((
		SELECT TOP(1) 1 
		FROM @ScoreItems AS I 
		WHERE I.SecondValue = N'AA_SharesOnWall' AND I.FirstValue > 0
	), 0)

	DECLARE @ReceivedSharesOnKnowledges bit = ISNULL((
		SELECT TOP(1) 1 
		FROM @ScoreItems AS I 
		WHERE I.SecondValue = N'AB_ReceivedSharesOnKnowledges' AND I.FirstValue > 0
	), 0)

	DECLARE @SentSharesOnKnowledges bit = ISNULL((
		SELECT TOP(1) 1 
		FROM @ScoreItems AS I 
		WHERE I.SecondValue = N'AC_SentSharesOnKnowledges' AND I.FirstValue > 0
	), 0)

	DECLARE @ReceivedTemporalFeedBacks bit = ISNULL((
		SELECT TOP(1) 1 
		FROM @ScoreItems AS I 
		WHERE I.SecondValue = N'AD_ReceivedTemporalFeedBacks' AND I.FirstValue > 0
	), 0)

	DECLARE @ReceivedFinancialFeedBacks bit = ISNULL((
		SELECT TOP(1) 1 
		FROM @ScoreItems AS I 
		WHERE I.SecondValue = N'AE_ReceivedFinancialFeedBacks' AND I.FirstValue > 0
	), 0)

	DECLARE @SentFeedBacksCount bit = ISNULL((
		SELECT TOP(1) 1 
		FROM @ScoreItems AS I 
		WHERE I.SecondValue = N'AF_SentFeedBacksCount' AND I.FirstValue > 0
	), 0)

	DECLARE @SentQuestions bit = ISNULL((
		SELECT TOP(1) 1 
		FROM @ScoreItems AS I 
		WHERE I.SecondValue = N'AG_SentQuestions' AND I.FirstValue > 0
	), 0)

	DECLARE @SentAnswers bit = ISNULL((
		SELECT TOP(1) 1 
		FROM @ScoreItems AS I 
		WHERE I.SecondValue = N'AH_SentAnswers' AND I.FirstValue > 0
	), 0)

	DECLARE @KnowledgeOverview bit = ISNULL((
		SELECT TOP(1) 1 
		FROM @ScoreItems AS I 
		WHERE I.SecondValue = N'AI_KnowledgeOverview' AND I.FirstValue > 0
	), 0)

	DECLARE @KnowledgeEvaluation bit = ISNULL((
		SELECT TOP(1) 1 
		FROM @ScoreItems AS I 
		WHERE I.SecondValue = N'AJ_KnowledgeEvaluation' AND I.FirstValue > 0
	), 0)

	DECLARE @CommunityScore bit = ISNULL((
		SELECT TOP(1) 1 
		FROM @ScoreItems AS I 
		WHERE I.SecondValue = N'AK_CommunityScore' AND I.FirstValue > 0
	), 0)

	DECLARE @AcceptedWikiChanges bit = ISNULL((
		SELECT TOP(1) 1 
		FROM @ScoreItems AS I 
		WHERE I.SecondValue = N'AL_AcceptedWikiChanges' AND I.FirstValue > 0
	), 0)

	DECLARE @WikiEvaluation bit = ISNULL((
		SELECT TOP(1) 1 
		FROM @ScoreItems AS I 
		WHERE I.SecondValue = N'AM_WikiEvaluation' AND I.FirstValue > 0
	), 0)

	DECLARE @PersonalPageVisit bit = ISNULL((
		SELECT TOP(1) 1 
		FROM @ScoreItems AS I 
		WHERE I.SecondValue = N'AN_PersonalPageVisit' AND I.FirstValue > 0
	), 0)

	SELECT Data.*
	INTO #Results
	FROM (
			-- (1) تعداد به اشتراک گذاری ها روی تخته دانش
			---- ItemName: SharesOnWall ----
			SELECT U.UserID, ISNULL(COUNT(PS.ShareID), 0) AS Score, N'AA_SharesOnWall' AS ItemName 
			FROM @Users AS U
				LEFT JOIN [dbo].[SH_PostShares] AS PS
				ON PS.ApplicationID = @ApplicationID AND PS.SenderUserID = U.UserID AND
					PS.OwnerType = N'User' AND PS.Deleted = 0 AND
					(@BeginDate IS NULL OR PS.SendDate >= @BeginDate) AND
					(@FinishDate IS NULL OR PS.SendDate <= @FinishDate)
			WHERE @SharesOnWall = 1
			GROUP BY U.UserID
			-- end of (1)

			UNION ALL

			-- (8) تعداد نظرات دریافت شده بر روی دانش ها
			---- ItemName: ReceivedSharesOnKnowledges ----
			SELECT USR.UserID, (
				(SELECT ISNULL(COUNT(PS.ShareID), 0)
				 FROM [dbo].[SH_PostShares] AS PS
					INNER JOIN [dbo].[KW_View_Knowledges] AS VK
					INNER JOIN [dbo].[CN_NodeCreators] AS NC
					ON NC.ApplicationID = @ApplicationID AND NC.NodeID = VK.KnowledgeID
					ON VK.ApplicationID = @ApplicationID AND VK.KnowledgeID = PS.OwnerID
				 WHERE NC.ApplicationID = @ApplicationID AND 
					NC.UserID = USR.UserID AND NC.Deleted = 0 AND 
					PS.SenderUserID <> USR.UserID AND PS.OwnerType = N'Knowledge' AND
					VK.Deleted = 0 AND PS.Deleted = 0 AND
					(@BeginDate IS NULL OR PS.SendDate >= @BeginDate) AND
					(@FinishDate IS NULL OR PS.SendDate <= @FinishDate))
			), N'AB_ReceivedSharesOnKnowledges'
			FROM @Users AS USR
			WHERE @ReceivedSharesOnKnowledges = 1
			-- end of (8)

			UNION ALL

			-- (9) تعداد نظرهای ارسال کرده بر روی دانش های دیگران
			---- ItemName: SentSharesOnKnowledges ----
			SELECT USR.UserID, (
				SELECT ISNULL(COUNT(PS.ShareID), 0)
				FROM [dbo].[SH_PostShares] AS PS
					INNER JOIN [dbo].[KW_View_Knowledges] VK
					ON VK.ApplicationID = @ApplicationID AND VK.KnowledgeID = PS.OwnerID
				WHERE PS.ApplicationID = @ApplicationID AND PS.SenderUserID = USR.UserID AND
					PS.OwnerType = N'Knowledge' AND PS.Deleted = 0 AND
					(@BeginDate IS NULL OR PS.SendDate >= @BeginDate) AND
					(@FinishDate IS NULL OR PS.SendDate <= @FinishDate) AND
					NOT EXISTS(SELECT TOP(1) * FROM [dbo].[CN_NodeCreators] AS NC
						WHERE NC.NodeID = VK.KnowledgeID AND NC.UserID = USR.UserID AND NC.Deleted = 0)
			), N'AC_SentSharesOnKnowledges'
			FROM @Users AS USR
			WHERE @SentSharesOnKnowledges = 1
			-- end of (9)

			UNION ALL

			-- (10) مجموع صرفه جویی های زمانی دانش های ثبت شده
			---- ItemName: ReceivedTemporalFeedBacks ----
			SELECT USR.UserID, (
				(SELECT ISNULL(SUM(FB.Value), 0)
				 FROM [dbo].[KW_FeedBacks] AS FB
					INNER JOIN [dbo].[KW_View_Knowledges] AS VK
					INNER JOIN [dbo].[CN_NodeCreators] AS NC
					ON NC.ApplicationID = @ApplicationID AND NC.NodeID = VK.KnowledgeID
					ON VK.ApplicationID = @ApplicationID AND VK.KnowledgeID = FB.KnowledgeID
				 WHERE FB.ApplicationID = @ApplicationID AND 
					NC.UserID = USR.UserID AND NC.Deleted = 0 AND 
					FB.FeedBackTypeID = 2 AND FB.UserID <> USR.UserID AND
					VK.Deleted = 0 AND FB.Deleted = 0 AND
					(@BeginDate IS NULL OR FB.SendDate >= @BeginDate) AND
					(@FinishDate IS NULL OR FB.SendDate <= @FinishDate))
			), N'AD_ReceivedTemporalFeedBacks'
			FROM @Users AS USR
			WHERE @ReceivedTemporalFeedBacks = 1
			-- end of (10)

			UNION ALL

			-- (11) مجموع صرفه جویی های ریالی دانش های ثبت شده
			---- ItemName: ReceivedFinancialFeedBacks ----
			SELECT USR.UserID, (
				(SELECT ISNULL(SUM(FB.Value), 0)
				 FROM [dbo].[KW_FeedBacks] AS FB
					INNER JOIN [dbo].[KW_View_Knowledges] AS VK
					INNER JOIN [dbo].[CN_NodeCreators] AS NC
					ON NC.ApplicationID = @ApplicationID AND NC.NodeID = VK.KnowledgeID
					ON VK.ApplicationID = @ApplicationID AND VK.KnowledgeID = FB.KnowledgeID
				 WHERE FB.ApplicationID = @ApplicationID AND 
					NC.UserID = USR.UserID AND NC.Deleted = 0 AND 
					FB.FeedBackTypeID = 1 AND FB.UserID <> USR.UserID AND
					VK.Deleted = 0 AND FB.Deleted = 0 AND
					(@BeginDate IS NULL OR FB.SendDate >= @BeginDate) AND
					(@FinishDate IS NULL OR FB.SendDate <= @FinishDate))
			), N'AE_ReceivedFinancialFeedBacks'
			FROM @Users AS USR
			WHERE @ReceivedFinancialFeedBacks = 1
			-- end of (11)

			UNION ALL

			-- (12) تعداد صرفه جویی های اعلام کرده بر روی دانش های دیگران
			---- ItemName: SentFeedBacksCount ----
			SELECT USR.UserID, (
				SELECT COUNT(FB.Value) 
				FROM [dbo].[KW_FeedBacks] AS FB
					INNER JOIN [dbo].[KW_View_Knowledges] AS VK
					ON VK.ApplicationID = @ApplicationID AND VK.KnowledgeID = FB.KnowledgeID
				WHERE FB.ApplicationID = @ApplicationID AND 
					FB.UserID = USR.UserID AND FB.Deleted = 0 AND
					(@BeginDate IS NULL OR FB.SendDate >= @BeginDate) AND
					(@FinishDate IS NULL OR FB.SendDate <= @FinishDate) AND
					NOT EXISTS(SELECT TOP(1) * FROM [dbo].[CN_NodeCreators] AS NC
						WHERE NC.NodeID = VK.KnowledgeID AND NC.UserID = USR.UserID AND NC.Deleted = 0)
			), N'AF_SentFeedBacksCount'
			FROM @Users AS USR
			WHERE @SentFeedBacksCount = 1
			-- end of (12)

			UNION ALL

			-- (13) تعداد سوالات پرسیده شده
			---- ItemName: SentQuestions ----
			SELECT USERS.UserID, ISNULL(QTN.Score, 0), N'AG_SentQuestions' 
			FROM @Users AS USERS
				LEFT JOIN (
					SELECT QU.SenderUserID, COUNT(QU.QuestionID) AS Score
					FROM [dbo].[QA_Questions] AS QU
					WHERE QU.ApplicationID = @ApplicationID AND QU.Deleted = 0 AND 
						(@BeginDate IS NULL OR QU.SendDate >= @BeginDate) AND
						(@FinishDate IS NULL OR QU.SendDate <= @FinishDate)
					GROUP BY QU.SenderUserID
				) AS QTN
				ON USERS.UserID = QTN.SenderUserID
			WHERE @SentQuestions = 1
			-- end of (13)

			UNION ALL

			-- (14) مجموع امتیاز پاسخ های ارسال شده بر روی سوالات دیگران
			---- ItemName: SentAnswers ----
			SELECT USR.UserID, (
				SELECT ISNULL(COUNT(ANS.AnswerID), 0)
				FROM [dbo].[QA_Answers] AS ANS
					INNER JOIN [dbo].[QA_Questions] AS QU
					ON QU.ApplicationID = @ApplicationID AND QU.QuestionID = ANS.QuestionID
				WHERE ANS.ApplicationID = @ApplicationID AND ANS.SenderUserID = USR.UserID AND 
					QU.SenderUserID <> USR.UserID AND ANS.Deleted = 0 AND
					(@BeginDate IS NULL OR ANS.SendDate >= @BeginDate) AND
					(@FinishDate IS NULL OR ANS.SendDate <= @FinishDate)
			), N'AH_SentAnswers'
			FROM @Users AS USR 
			WHERE @SentAnswers = 1
			-- end of (14)

			UNION ALL

			-- (15) تعداد ارزیابی اولیه دانش های دیگران
			---- ItemName: KnowledgeOverview ----
			SELECT	USR.UserID,
					SUM(
						CASE 
							WHEN H.[KnowledgeID] IS NOT NULL THEN 1
							ELSE 0
						END
					),
					N'AI_KnowledgeOverview'
			FROM @Users AS USR
				LEFT JOIN (
					SELECT ROW_NUMBER() OVER (PARTITION BY H.KnowledgeID, H.ActorUserID ORDER BY H.ID ASC) AS RowNumber,
						H.KnowledgeID,
						H.ActorUserID,
						H.ActionDate
					FROM [dbo].[KW_History] AS H
					WHERE H.ApplicationID = @ApplicationID AND H.[Action] IN (
							N'Accept', N'Reject', N'SendBackForRevision', 
							N'SendToEvaluators', N'TerminateEvaluation'
						)
				) AS H
				INNER JOIN [dbo].[CN_Nodes] AS ND
				ON ND.ApplicationID = @ApplicationID AND 
					ND.NodeID = H.KnowledgeID AND ND.Deleted = 0
				ON H.RowNumber = 1 AND H.ActorUserID = USR.UserID AND
					(@BeginDate IS NULL OR H.ActionDate >= @BeginDate) AND
					(@FinishDate IS NULL OR H.ActionDate <= @FinishDate) AND
					NOT EXISTS(
						SELECT TOP(1) * 
						FROM [dbo].[CN_NodeCreators] AS NC
						WHERE NC.ApplicationID = @ApplicationID AND 
							NC.NodeID = H.KnowledgeID AND NC.UserID = USR.UserID AND NC.Deleted = 0
					)
			WHERE @KnowledgeOverview = 1
			GROUP BY USR.UserID
			-- end of (15)

			UNION ALL

			-- (16) تعداد ارزیابی خبرگی دانش های دیگران
			---- ItemName: KnowledgeEvaluation ----
			SELECT	USR.UserID,
					SUM(
						CASE 
							WHEN H.[KnowledgeID] IS NOT NULL THEN 1
							ELSE 0
						END
					),
					N'AJ_KnowledgeEvaluation'
			FROM @Users AS USR
				LEFT JOIN (
					SELECT ROW_NUMBER() OVER (PARTITION BY H.KnowledgeID, H.ActorUserID ORDER BY H.ID ASC) AS RowNumber,
						H.KnowledgeID,
						H.ActorUserID,
						H.ActionDate
					FROM [dbo].[KW_History] AS H
					WHERE H.ApplicationID = @ApplicationID AND H.[Action] IN (N'Evaluation')
				) AS H
				INNER JOIN [dbo].[CN_Nodes] AS ND
				ON ND.ApplicationID = @ApplicationID AND 
					ND.NodeID = H.KnowledgeID AND ND.Deleted = 0
				ON H.RowNumber = 1 AND H.ActorUserID = USR.UserID AND
					(@BeginDate IS NULL OR H.ActionDate >= @BeginDate) AND
					(@FinishDate IS NULL OR H.ActionDate <= @FinishDate) AND
					NOT EXISTS(
						SELECT TOP(1) * 
						FROM [dbo].[CN_NodeCreators] AS NC
						WHERE NC.ApplicationID = @ApplicationID AND 
							NC.NodeID = H.KnowledgeID AND NC.UserID = USR.UserID AND NC.Deleted = 0
					)
			WHERE @KnowledgeEvaluation = 1
			GROUP BY USR.UserID
			-- end of (16)

			UNION ALL

			-- (17) امتیاز انجمن
			---- ItemName: CommunityScore ----
			SELECT USR.UserID, (
				(
					SELECT ISNULL(COUNT(ANS.AnswerID), 0)
					FROM [dbo].[QA_Answers] AS ANS
						INNER JOIN [dbo].[QA_Questions] AS QU
						ON QU.ApplicationID = @ApplicationID AND QU.QuestionID = ANS.QuestionID
					WHERE ANS.ApplicationID = @ApplicationID AND 
						ANS.SenderUserID = USR.UserID AND QU.SenderUserID <> USR.UserID AND 
						ANS.Deleted = 0 AND
						(@BeginDate IS NULL OR ANS.SendDate >= @BeginDate) AND
						(@FinishDate IS NULL OR ANS.SendDate <= @FinishDate)
				) + (
					SELECT CAST(ISNULL(COUNT(PS.ShareID), 0) AS float)
					FROM [dbo].[SH_PostShares] AS PS
					WHERE PS.ApplicationID = @ApplicationID AND PS.SenderUserID = USR.UserID AND
						PS.OwnerType = N'Node' AND PS.Deleted = 0 AND
						(@BeginDate IS NULL OR PS.SendDate >= @BeginDate) AND
						(@FinishDate IS NULL OR PS.SendDate <= @FinishDate)
				)
			), N'AK_CommunityScore'
			FROM @Users AS USR
			WHERE @CommunityScore = 1
			-- end of (17)

			UNION ALL

			-- (18) تعداد تغییرات ویکی تایید شده
			---- ItemName: AcceptedWikiChanges ----
			SELECT USERS.UserID, ISNULL(CNG.Score, 0), N'AL_AcceptedWikiChanges' 
			FROM @Users AS USERS
				LEFT JOIN (
					SELECT CH.UserID, COUNT(CH.ChangeID) AS Score
					FROM [dbo].[WK_Changes] AS CH
					WHERE CH.ApplicationID = @ApplicationID AND CH.[Status] = N'Accepted' AND
						(@BeginDate IS NULL OR CH.AcceptionDate >= @BeginDate) AND
						(@FinishDate IS NULL OR CH.AcceptionDate <= @FinishDate)
					GROUP BY CH.UserID
				) AS CNG
				ON USERS.UserID = CNG.UserID
			WHERE @AcceptedWikiChanges = 1
			-- end of (18)

			UNION ALL

			-- (19) تعداد ویکی های داوری کرده به عنوان خبره
			---- ItemName: WikiEvaluation ----
			SELECT USERS.UserID, ISNULL(CNG.Score, 0), N'AM_WikiEvaluation' 
			FROM @Users AS USERS
				LEFT JOIN (
					SELECT CH.EvaluatorUserID, COUNT(CH.ChangeID) AS Score
					FROM [dbo].[WK_Changes] AS CH
					WHERE CH.ApplicationID = @ApplicationID AND 
						(@BeginDate IS NULL OR CH.EvaluationDate >= @BeginDate) AND
						(@FinishDate IS NULL OR CH.EvaluationDate <= @FinishDate)
					GROUP BY CH.EvaluatorUserID
				) AS CNG
				ON USERS.UserID = CNG.EvaluatorUserID
			WHERE @WikiEvaluation = 1
			-- end of (19)

			UNION ALL

			-- (20) تعداد بازدید دیگران از صفحه شخصی
			---- ItemName: PersonalPageVisit ----
			SELECT USR.UserID, 
				(
					SELECT COUNT(IV.UserID) 
					FROM [dbo].[USR_ItemVisits] AS IV
					WHERE IV.ApplicationID = @ApplicationID AND IV.ItemID = USR.UserID AND
						(@BeginDate IS NULL OR IV.VisitDate >= @BeginDate) AND
						(@FinishDate IS NULL OR IV.VisitDate <= @FinishDate)
				), N'AN_PersonalPageVisit'
			FROM @Users AS USR
			WHERE @PersonalPageVisit = 1
			-- end of (20)
			
			UNION ALL
			
			-- (N) دانش ها
			SELECT	USERS.UserID AS UserID, ISNULL(KN.Score, 0), KN.RegisteredType
			FROM @Users AS USERS
				LEFT JOIN (
					SELECT	NC.UserID,
							N'AO_Registered_' + REPLACE(CAST(ND.NodeTypeID AS varchar(100)), '-', '') AS RegisteredType, 
							SUM(
								CASE
									WHEN (@BeginDate IS NULL OR ND.CreationDate >= @BeginDate) AND
										(@FinishDate IS NULL OR ND.CreationDate <= @FinishDate) THEN 1
									ELSE 0
								END * (NC.CollaborationShare / 100)
							) AS Score
					FROM @KnowledgeTypeIDs AS K
						INNER JOIN [dbo].[CN_Nodes] AS ND
						ON ND.ApplicationID = @ApplicationID AND ND.NodeTypeID = K.Value
						INNER JOIN [dbo].[CN_NodeCreators] AS NC
						ON NC.ApplicationID = @ApplicationID AND NC.NodeID = ND.NodeID
					WHERE ND.Deleted = 0 AND NC.Deleted = 0
					GROUP BY NC.UserID, ND.NodeTypeID
				) AS KN
				ON USERS.UserID = KN.UserID
				
			UNION ALL

			SELECT	USERS.UserID AS UserID, ISNULL(KN.Score, 0), KN.AcceptedTypeCount
			FROM @Users AS USERS
				LEFT JOIN (
					SELECT	NC.UserID,
							N'AP_AcceptedCount_' + REPLACE(CAST(ND.NodeTypeID AS varchar(100)), '-', '') AS AcceptedTypeCount,
							SUM(
								CASE
									WHEN ND.[Status] = N'Accepted' AND 
										(@BeginDate IS NULL OR ISNULL(ND.PublicationDate, ND.CreationDate) >= @BeginDate) AND
										(@FinishDate IS NULL OR ISNULL(ND.PublicationDate, ND.CreationDate) <= @FinishDate)
										THEN 1
									ELSE 0
								END * (NC.CollaborationShare / 100)
							) AS Score
					FROM @KnowledgeTypeIDs AS K
						INNER JOIN [dbo].[CN_Nodes] AS ND
						ON ND.ApplicationID = @ApplicationID AND ND.NodeTypeID = K.Value
						INNER JOIN [dbo].[CN_NodeCreators] AS NC
						ON NC.ApplicationID = @ApplicationID AND NC.NodeID = ND.NodeID
					WHERE ND.Deleted = 0 AND NC.Deleted = 0
					GROUP BY NC.UserID, ND.NodeTypeID
				) AS KN
				ON USERS.UserID = KN.UserID
				
			UNION ALL

			SELECT	USERS.UserID AS UserID, ISNULL(KN.Score, 0), KN.AcceptedTypeScore
			FROM @Users AS USERS
				LEFT JOIN (
					SELECT	NC.UserID,
							N'AQ_AcceptedScore_' + REPLACE(CAST(ND.NodeTypeID AS varchar(100)), '-', '') AS AcceptedTypeScore,
							SUM(
								CASE
									WHEN ND.[Status] = N'Accepted' AND 
										(@BeginDate IS NULL OR ISNULL(ND.PublicationDate, ND.CreationDate) >= @BeginDate) AND
										(@FinishDate IS NULL OR ISNULL(ND.PublicationDate, ND.CreationDate) <= @FinishDate)
										THEN ISNULL(ND.Score, 0)
									ELSE 0
								END * (NC.CollaborationShare / 100)
							) AS Score
					FROM @KnowledgeTypeIDs AS K
						INNER JOIN [dbo].[CN_Nodes] AS ND
						ON ND.ApplicationID = @ApplicationID AND ND.NodeTypeID = K.Value
						INNER JOIN [dbo].[CN_NodeCreators] AS NC
						ON NC.ApplicationID = @ApplicationID AND NC.NodeID = ND.NodeID
					WHERE ND.Deleted = 0 AND NC.Deleted = 0
					GROUP BY NC.UserID, ND.NodeTypeID
				) AS KN
				ON USERS.UserID = KN.UserID
			-- end of (N)
		) AS Data
		INNER JOIN @ScoreItems AS SI
		ON SI.SecondValue = Data.ItemName AND SI.FirstValue > 0
	
	
	DECLARE @ItemsList VARCHAR(MAX)   

	SELECT @ItemsList = ISNULL(@ItemsList + ', ', '') + '[' + ItemName + ']'
	FROM (SELECT DISTINCT ItemName FROM #Results) AS q
	ORDER BY q.ItemName
	
	CREATE TABLE #TMPR (UserID_Hide uniqueidentifier, GroupID_Hide uniqueidentifier, 
		Name nvarchar(1000), UserName nvarchar(256), GroupName nvarchar(500),
		Score float, Compensation float
	)
	
	INSERT INTO #TMPR (UserID_Hide)
	SELECT DISTINCT UserID
	FROM #Results AS R
	
	-- Compute Users' Scores
	UPDATE T
		SET Score = Ref.Score
	FROM #TMPR AS T
		INNER JOIN (
			SELECT R.UserID, SUM(ISNULL(S.FirstValue, 0) * ISNULL(R.Score, 0)) AS Score
			FROM #Results AS R
				INNER JOIN @ScoreItems AS S
				ON LOWER(R.ItemName) = LOWER(S.SecondValue)
			GROUP BY R.UserID
		) AS Ref
		ON T.UserID_Hide = Ref.UserID
	-- end of Compute Users' Scores
	
	-- Compute Users' Compensations
	DECLARE @ScoreReward float = @CompensationVolume
	
	IF(@CompensatePerScore IS NULL OR @CompensatePerScore = 0)
		SET @ScoreReward = @CompensationVolume / (SELECT SUM(Score) FROM #TMPR)
	
	UPDATE #TMPR
	SET Compensation = Score * ISNULL(@ScoreReward, 0)
	-- end of Compute Users' Compensations
	
	-- Determine Full Names & Groups
	UPDATE R
		SET GroupID_Hide = U.GroupID,
			Name = LTRIM(RTRIM(ISNULL(UN.FirstName, N'') + N' ' + ISNULL(UN.LastName, N''))),
			UserName = UN.UserName,
			GroupName = U.GroupName
	FROM #TMPR AS R
		INNER JOIN @Users AS U
		ON U.UserID = R.UserID_Hide
		INNER JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND UN.UserID = U.UserID
	-- end of Determine Names & Departments

	DECLARE @CommaItemsList varchar(max) = CASE WHEN ISNULL(@ItemsList, '') = '' THEN '' ELSE ', ' + @ItemsList END
	DECLARE @ItemsListOrSomething varchar(max) = CASE WHEN ISNULL(@ItemsList, '') = '' THEN 'fasdfasdfadfa' ELSE @ItemsList END
	
	EXEC (
		'SELECT ROW_NUMBER() OVER(ORDER BY T.Score DESC, T.UserID_Hide ASC) AS [Rank], T.UserID_Hide, T.GroupID_Hide, T.Name, T.UserName, ' +
			'T.GroupName, T.Score, T.Compensation' + @CommaItemsList + ' ' +
		'FROM #TMPR AS T ' +
			'INNER JOIN ( ' +
				'SELECT UserID' + @CommaItemsList + ' ' +
				'FROM ( ' +
						'SELECT UserID, Score, ItemName ' +
						'FROM #Results ' +
					') AS P ' +
					'PIVOT ' +
					'(SUM(Score) FOR ItemName IN (' + @ItemsListOrSomething + ')) AS PVT ' +
			') AS X ' +
			'ON X.UserID = T.UserID_Hide ' +
		'ORDER BY T.Score DESC, T.UserID_Hide ASC'
	)
	
	SELECT ('{' +
			'"Name": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'},' +
			'"GroupName": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "GroupID_Hide"}' +
			'}' +
		   '}') AS Actions
	
	SELECT *
	FROM (
		SELECT	'AO_Registered_' + REPLACE(CAST(NT.NodeTypeID AS varchar(100)), '-', '') AS ColumnName,
				N'تعداد ''' + NT.Name + N''' ثبت شده' AS Translation,
				'double' AS [Type]
		FROM @KnowledgeTypeIDs AS K
			INNER JOIN [dbo].[CN_NodeTypes] AS NT
			ON NT.NodeTypeID = K.Value
			
		UNION ALL
		
		SELECT	'AP_AcceptedCount_' + REPLACE(CAST(NT.NodeTypeID AS varchar(100)), '-', '') AS ColumnName,
				N'تعداد ''' + NT.Name + N''' تایید شده' AS Translation,
				'double' AS [Type]
		FROM @KnowledgeTypeIDs AS K
			INNER JOIN [dbo].[CN_NodeTypes] AS NT
			ON NT.NodeTypeID = K.Value
		
		UNION ALL
		
		SELECT	'AQ_AcceptedScore_' + REPLACE(CAST(NT.NodeTypeID AS varchar(100)), '-', '') AS ColumnName,
				N'جمع امتیازات ''' + NT.Name + N''' تایید شده' AS Translation,
				'double' AS [Type]
		FROM @KnowledgeTypeIDs AS K
			INNER JOIN [dbo].[CN_NodeTypes] AS NT
			ON NT.NodeTypeID = K.Value
	) AS X
			
	SELECT ('{"IsDescription": "true", "IsColumnsDictionary": "true"}') AS Info
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_UsersPerformanceReport]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_UsersPerformanceReport]
GO

CREATE PROCEDURE [dbo].[USR_UsersPerformanceReport]
	@ApplicationID			uniqueidentifier,
	@CurrentUserID			uniqueidentifier,
    @strUserIDs				varchar(max),
    @strNodeIDs				varchar(max),
    @strListIDs				varchar(max),
    @strKnowledgeTypeIDs	varchar(max),
    @delimiter				char,
    @BeginDate				datetime,
    @FinishDate				datetime,
    @CompensatePerScore		bit,
    @CompensationVolume		float,
    @strScoreItems			varchar(max),
    @innerDelimiter			char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeIDs GuidTableType
	
	INSERT INTO @NodeIDs (Value)
	SELECT DISTINCT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strNodeIDs, @delimiter) AS Ref
	
	DECLARE @ListIDs GuidTableType
	
	INSERT INTO @ListIDs (Value)
	SELECT DISTINCT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strListIDs, @delimiter) AS Ref
	
	DECLARE @GroupsCount int = (SELECT COUNT(*) FROM @NodeIDs) + (SELECT COUNT(*) FROM @ListIDs)
	
	DECLARE @ScoreItems FloatStringTableType
	INSERT INTO @ScoreItems (FirstValue, SecondValue)
	SELECT Ref.FirstValue, Ref.SecondValue
	FROM [dbo].[GFN_StrToFloatStringTable](@strScoreItems, @innerDelimiter, @delimiter) AS Ref
	
	DECLARE @UserIDs TABLE (UserID uniqueidentifier, GroupID uniqueidentifier)
	
	INSERT INTO @UserIDs(UserID, GroupID)
	SELECT [UID].UserID, CAST(MAX(CAST([UID].GroupID AS varchar(50))) AS uniqueidentifier) AS GroupID
	FROM (
			SELECT Ref.Value AS UserID, NULL AS GroupID
			FROM GFN_StrToGuidTable(@strUserIDs, @delimiter) AS Ref	
			
			UNION ALL
			
			SELECT NM.UserID AS UserID, NM.NodeID AS GroupID
			FROM (
					SELECT Ref.Value AS Value
					FROM @NodeIDs AS Ref
					
					UNION ALL
					 
					SELECT ND.NodeID
					FROM @ListIDs AS LIDs
						INNER JOIN [dbo].[CN_ListNodes] AS LN
						ON LN.ApplicationID = @ApplicationID AND LN.ListID = LIDs.Value
						INNER JOIN [dbo].[CN_Nodes] AS ND
						ON ND.ApplicationID = @ApplicationID AND ND.NodeID = LN.NodeID
					WHERE LN.Deleted = 0 AND ND.Deleted = 0
				) AS NID
				INNER JOIN [dbo].[CN_NodeMembers] AS NM
				ON NM.ApplicationID = @ApplicationID AND NM.NodeID = NID.Value
				INNER JOIN [dbo].[Users_Normal] AS UN
				ON UN.ApplicationID = @ApplicationID AND UN.UserID = NM.UserID
			WHERE NM.[Status] = N'Accepted' AND NM.Deleted = 0 AND UN.IsApproved = 1
		) AS [UID]
	GROUP BY [UID].UserID
	
	IF @GroupsCount = 0 BEGIN
		IF (SELECT COUNT(*) FROM @UserIDs) = 0 BEGIN
			INSERT INTO @UserIDs (UserID)
			SELECT UserID
			FROM [dbo].[Users_Normal]
			WHERE ApplicationID = @ApplicationID AND IsApproved = 1
		END
		
		DECLARE @DepTypeIDs GuidTableType
		INSERT INTO @DepTypeIDs (Value)
		SELECT Ref.NodeTypeID
		FROM [dbo].[CN_FN_GetDepartmentNodeTypeIDs](@ApplicationID) AS Ref
	
		UPDATE R
			SET GroupID = Ref.GroupID
		FROM @UserIDs AS R
			INNER JOIN (
				SELECT T.UserID,
					CAST(MAX(CAST(ND.NodeID AS varchar(36))) AS uniqueidentifier) AS GroupID
				FROM @UserIDs AS T
					INNER JOIN [dbo].[CN_NodeMembers] AS NM
					INNER JOIN [dbo].[CN_Nodes] AS ND
					ON ND.ApplicationID = @ApplicationID AND 
						ND.NodeTypeID IN (SELECT Value FROM @DepTypeIDs) AND ND.Deleted = 0
					ON NM.ApplicationID = @ApplicationID AND
						NM.NodeID = ND.NodeID AND NM.UserID = T.UserID AND NM.Deleted = 0
				GROUP BY T.UserID
			) AS Ref
			ON R.UserID = Ref.UserID
	END
	
	DECLARE @KnowledgeTypeIDs GuidTableType
	
	INSERT INTO @KnowledgeTypeIDs (Value)
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strKnowledgeTypeIDs, @delimiter) AS Ref
	
	DECLARE @UserGroupIDs GuidPairTableType
	
	INSERT INTO @UserGroupIDs (FirstValue, SecondValue)
	SELECT DISTINCT U.UserID, ISNULL(U.GroupID, NEWID())
	FROM @UserIDs AS U
	
	EXEC [dbo].[USR_P_UsersPerformanceReport] @ApplicationID, @UserGroupIDs, @KnowledgeTypeIDs,
		@CompensatePerScore, @CompensationVolume, @ScoreItems, @BeginDate, @FinishDate
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_ProfileFilledPercentageReport]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_ProfileFilledPercentageReport]
GO

CREATE PROCEDURE [dbo].[USR_ProfileFilledPercentageReport]
	@ApplicationID		uniqueidentifier,
	@CurrentUserID		uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT	X.FilledPercentage,
			COUNT(X.UserID) AS UsersCount,
			SUM(X.HasJobTitle) AS JobTitlesCount,
			SUM(X.JobsCount) AS JobsCount,
			SUM(X.SchoolsCount) AS SchoolsCount,
			SUM(X.CoursesCount) AS CoursesCount,
			SUM(X.HonorsCount) AS HonorsCount,
			SUM(X.LanguagesCount) AS LanguagesCount
	FROM (
			SELECT	R.UserID,
					(
						CASE WHEN R.HasJobTitle > 0 THEN 1 ELSE 0 END +
						CASE WHEN R.JobsCount > 0 THEN 1 ELSE 0 END +
						CASE WHEN R.SchoolsCount > 0 THEN 1 ELSE 0 END +
						CASE WHEN R.CoursesCount > 0 THEN 1 ELSE 0 END +
						CASE WHEN R.HonorsCount > 0 THEN 1 ELSE 0 END +
						CASE WHEN R.LanguagesCount > 0 THEN 1 ELSE 0 END
					) * 100 / 6 AS FilledPercentage,
					R.HasJobTitle,
					R.JobsCount,
					R.SchoolsCount,
					R.CoursesCount,
					R.HonorsCount,
					R.LanguagesCount
			FROM (
					SELECT	UN.UserID,
							CASE WHEN ISNULL(MAX(UN.JobTitle), N'') = N'' THEN 0 ELSE 1 END AS HasJobTitle,
							COUNT(DISTINCT JE.JobID) AS JobsCount,
							COUNT(DISTINCT
								CASE 
									WHEN EE.EducationID IS NOT NULL AND EE.IsSchool = 1 THEN EE.EducationID 
									ELSE NULL 
								END
							) AS SchoolsCount,
							COUNT(DISTINCT
								CASE 
									WHEN EE.EducationID IS NOT NULL AND EE.IsSchool = 0 THEN EE.EducationID 
									ELSE NULL 
								END
							) AS CoursesCount,
							COUNT(DISTINCT HA.ID) AS HonorsCount,
							COUNT(DISTINCT UL.ID) AS LanguagesCount
					FROM [dbo].[Users_Normal] AS UN
						LEFT JOIN [dbo].[USR_JobExperiences] AS JE
						ON JE.ApplicationID = @ApplicationID AND 
							JE.UserID = UN.UserID AND JE.Deleted = 0
						LEFT JOIN [dbo].[USR_EducationalExperiences] AS EE
						ON EE.ApplicationID = @ApplicationID AND
							EE.UserID = UN.UserID AND EE.Deleted = 0
						LEFT JOIN [dbo].[USR_HonorsAndAwards] AS HA
						ON HA.ApplicationID = @ApplicationID AND
							HA.UserID = UN.UserID AND HA.Deleted = 0
						LEFT JOIN [dbo].[USR_UserLanguages] AS UL
						ON UL.ApplicationID = @ApplicationID AND
							UL.UserID = UN.UserID AND UL.Deleted = 0
					WHERE UN.ApplicationID = @ApplicationID AND UN.IsApproved = 1
					GROUP BY UN.UserID
				) AS R
		) AS X
	GROUP BY X.FilledPercentage
	
	SELECT ('{' +
			'"FilledPercentage": {"Action": "Report", ' +
		   		'"ModuleIdentifier": "USR", "ReportName": "UsersWithSpecificPercentageOfFilledProfileReport",' +
		   		'"Requires": {"FilledPercentage": {"Value": "FilledPercentage"}}, ' + 
		   		'"Params": {}' + 
		   	'}' +
		   '}') AS Actions
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_UsersWithSpecificPercentageOfFilledProfileReport]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_UsersWithSpecificPercentageOfFilledProfileReport]
GO

CREATE PROCEDURE [dbo].[USR_UsersWithSpecificPercentageOfFilledProfileReport]
	@ApplicationID		uniqueidentifier,
	@CurrentUserID		uniqueidentifier,
	@Percentage			int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT	X.UserID AS UserID_Hide,
			LTRIM(RTRIM(ISNULL(UN.FirstName, N'') + N' ' + ISNULL(UN.LastName, N''))) AS FullName,
			X.FilledPercentage,
			CASE WHEN X.HasJobTitle = 1 THEN N'Yes' ELSE N'No' END AS HasJobTitle_Dic,
			X.JobsCount,
			X.SchoolsCount,
			X.CoursesCount,
			X.HonorsCount,
			X.LanguagesCount
	FROM (
			SELECT	R.UserID,
					(
						CASE WHEN R.HasJobTitle > 0 THEN 1 ELSE 0 END +
						CASE WHEN R.JobsCount > 0 THEN 1 ELSE 0 END +
						CASE WHEN R.SchoolsCount > 0 THEN 1 ELSE 0 END +
						CASE WHEN R.CoursesCount > 0 THEN 1 ELSE 0 END +
						CASE WHEN R.HonorsCount > 0 THEN 1 ELSE 0 END +
						CASE WHEN R.LanguagesCount > 0 THEN 1 ELSE 0 END
					) * 100 / 6 AS FilledPercentage,
					R.HasJobTitle,
					R.JobsCount,
					R.SchoolsCount,
					R.CoursesCount,
					R.HonorsCount,
					R.LanguagesCount
			FROM (
					SELECT	UN.UserID,
							CASE WHEN ISNULL(MAX(UN.JobTitle), N'') = N'' THEN 0 ELSE 1 END AS HasJobTitle,
							COUNT(DISTINCT JE.JobID) AS JobsCount,
							COUNT(DISTINCT
								CASE 
									WHEN EE.EducationID IS NOT NULL AND EE.IsSchool = 1 THEN EE.EducationID 
									ELSE NULL 
								END
							) AS SchoolsCount,
							COUNT(DISTINCT
								CASE 
									WHEN EE.EducationID IS NOT NULL AND EE.IsSchool = 0 THEN EE.EducationID 
									ELSE NULL 
								END
							) AS CoursesCount,
							COUNT(DISTINCT HA.ID) AS HonorsCount,
							COUNT(DISTINCT UL.ID) AS LanguagesCount
					FROM [dbo].[Users_Normal] AS UN
						LEFT JOIN [dbo].[USR_JobExperiences] AS JE
						ON JE.ApplicationID = @ApplicationID AND 
							JE.UserID = UN.UserID AND JE.Deleted = 0
						LEFT JOIN [dbo].[USR_EducationalExperiences] AS EE
						ON EE.ApplicationID = @ApplicationID AND
							EE.UserID = UN.UserID AND EE.Deleted = 0
						LEFT JOIN [dbo].[USR_HonorsAndAwards] AS HA
						ON HA.ApplicationID = @ApplicationID AND
							HA.UserID = UN.UserID AND HA.Deleted = 0
						LEFT JOIN [dbo].[USR_UserLanguages] AS UL
						ON UL.ApplicationID = @ApplicationID AND
							UL.UserID = UN.UserID AND UL.Deleted = 0
					WHERE UN.ApplicationID = @ApplicationID AND UN.IsApproved = 1
					GROUP BY UN.UserID
				) AS R
		) AS X
		INNER JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND UN.UserID = X.UserID
	WHERE (@Percentage IS NULL OR X.FilledPercentage = @Percentage)
	ORDER BY X.FilledPercentage DESC
	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'}' +
		   '}') AS Actions
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_ResumeJobExperienceReport]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_ResumeJobExperienceReport]
GO

CREATE PROCEDURE [dbo].[USR_ResumeJobExperienceReport]
	@ApplicationID	uniqueidentifier,
	@CurrentUserID	uniqueidentifier,
	@strUserIDs		varchar(max),
	@strGroupIDs	varchar(max),
	@delimiter		char,
	@Hierarchy		bit,
	@DateFrom		datetime,
	@DateTo			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserIDs GuidTableType

	INSERT INTO @UserIDs (Value)
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strUserIDs, @delimiter) AS Ref

	DECLARE @GroupIDs GuidTableType

	INSERT INTO @GroupIDs (Value)
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strGroupIDs, @delimiter) AS Ref

	IF ((SELECT COUNT(*) FROM @GroupIDs) > 0) AND ((SELECT COUNT(*) FROM @UserIDs) = 0) BEGIN
		IF ISNULL(@Hierarchy, 0) = 1 BEGIN
			INSERT INTO @UserIDs (Value)
			SELECT DISTINCT NM.UserID
			FROM [dbo].[CN_FN_GetChildNodesDeepHierarchy](@ApplicationID, @GroupIDs) AS H
				INNER JOIN [dbo].[CN_View_NodeMembers] AS NM
				ON NM.ApplicationID = @ApplicationID and NM.NodeID = H.NodeID
		END
		ELSE BEGIN
			INSERT INTO @UserIDs (Value)
			SELECT DISTINCT NM.UserID
			FROM @GroupIDs AS G
				INNER JOIN [dbo].[CN_View_NodeMembers] AS NM
				ON NM.ApplicationID = @ApplicationID and NM.NodeID = G.Value
		END
	END

	DECLARE @UsersCount int = (SELECT COUNT(*) FROM @UserIDs)
	DECLARE @GroupsCount int = (SELECT COUNT(*) FROM @GroupIDs)

	SELECT	E.UserID AS UserID_Hide, 
			LTRIM(RTRIM(ISNULL(UN.FirstName, N'') + N' ' + ISNULL(UN.LastName, N''))) AS FullName,
			UN.UserName,
			E.Title, 
			E.Employer, 
			E.StartDate,
			E.EndDate
	FROM [dbo].[USR_JobExperiences] AS E
		INNER JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND UN.UserID = E.UserID
	WHERE E.ApplicationID = @ApplicationID AND E.Deleted = 0 AND
		((@UsersCount = 0 AND @GroupsCount = 0) OR UN.UserID IN (SELECT U.Value FROM @UserIDs AS U)) AND
		(@UsersCount > 0 OR UN.IsApproved = 1) AND
		(@DateFrom IS NULL OR ISNULL(E.StartDate, E.EndDate) >= @DateFrom) AND
		(@DateTo IS NULL OR ISNULL(E.StartDate, E.EndDate) >= @DateTo)
	ORDER BY E.UserID ASC, ISNULL(E.StartDate, E.EndDate) ASC, E.EndDate ASC
	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'}' +
		   '}') AS Actions
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_ResumeEducationReport]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_ResumeEducationReport]
GO

CREATE PROCEDURE [dbo].[USR_ResumeEducationReport]
	@ApplicationID	uniqueidentifier,
	@CurrentUserID	uniqueidentifier,
	@strUserIDs		varchar(max),
	@strGroupIDs	varchar(max),
	@delimiter		char,
	@Hierarchy		bit,
	@DateFrom		datetime,
	@DateTo			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserIDs GuidTableType

	INSERT INTO @UserIDs (Value)
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strUserIDs, @delimiter) AS Ref

	DECLARE @GroupIDs GuidTableType

	INSERT INTO @GroupIDs (Value)
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strGroupIDs, @delimiter) AS Ref

	IF ((SELECT COUNT(*) FROM @GroupIDs) > 0) AND ((SELECT COUNT(*) FROM @UserIDs) = 0) BEGIN
		IF ISNULL(@Hierarchy, 0) = 1 BEGIN
			INSERT INTO @UserIDs (Value)
			SELECT DISTINCT NM.UserID
			FROM [dbo].[CN_FN_GetChildNodesDeepHierarchy](@ApplicationID, @GroupIDs) AS H
				INNER JOIN [dbo].[CN_View_NodeMembers] AS NM
				ON NM.ApplicationID = @ApplicationID and NM.NodeID = H.NodeID
		END
		ELSE BEGIN
			INSERT INTO @UserIDs (Value)
			SELECT DISTINCT NM.UserID
			FROM @GroupIDs AS G
				INNER JOIN [dbo].[CN_View_NodeMembers] AS NM
				ON NM.ApplicationID = @ApplicationID and NM.NodeID = G.Value
		END
	END

	DECLARE @UsersCount int = (SELECT COUNT(*) FROM @UserIDs)
	DECLARE @GroupsCount int = (SELECT COUNT(*) FROM @GroupIDs)

	SELECT	E.UserID AS UserID_Hide, 
			LTRIM(RTRIM(ISNULL(UN.FirstName, N'') + N' ' + ISNULL(UN.LastName, N''))) AS FullName,
			UN.UserName,
			E.School, 
			E.StudyField, 
			(CASE WHEN E.[Level] = N'None' THEN N'' ELSE E.[Level] END) AS Level_Dic,
			E.StartDate,
			E.EndDate
	FROM [dbo].[USR_EducationalExperiences] AS E
		INNER JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND UN.UserID = E.UserID
	WHERE E.ApplicationID = @ApplicationID AND E.Deleted = 0 AND E.IsSchool = 1 AND
		((@UsersCount = 0 AND @GroupsCount = 0) OR UN.UserID IN (SELECT U.Value FROM @UserIDs AS U)) AND
		(@UsersCount > 0 OR UN.IsApproved = 1) AND
		(@DateFrom IS NULL OR ISNULL(E.StartDate, E.EndDate) >= @DateFrom) AND
		(@DateTo IS NULL OR ISNULL(E.StartDate, E.EndDate) >= @DateTo)
	ORDER BY E.UserID ASC, ISNULL(E.StartDate, E.EndDate) ASC, E.EndDate ASC
	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'}' +
		   '}') AS Actions
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_ResumeCoursesReport]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_ResumeCoursesReport]
GO

CREATE PROCEDURE [dbo].[USR_ResumeCoursesReport]
	@ApplicationID	uniqueidentifier,
	@CurrentUserID	uniqueidentifier,
	@strUserIDs		varchar(max),
	@strGroupIDs	varchar(max),
	@delimiter		char,
	@Hierarchy		bit,
	@DateFrom		datetime,
	@DateTo			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserIDs GuidTableType

	INSERT INTO @UserIDs (Value)
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strUserIDs, @delimiter) AS Ref

	DECLARE @GroupIDs GuidTableType

	INSERT INTO @GroupIDs (Value)
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strGroupIDs, @delimiter) AS Ref

	IF ((SELECT COUNT(*) FROM @GroupIDs) > 0) AND ((SELECT COUNT(*) FROM @UserIDs) = 0) BEGIN
		IF ISNULL(@Hierarchy, 0) = 1 BEGIN
			INSERT INTO @UserIDs (Value)
			SELECT DISTINCT NM.UserID
			FROM [dbo].[CN_FN_GetChildNodesDeepHierarchy](@ApplicationID, @GroupIDs) AS H
				INNER JOIN [dbo].[CN_View_NodeMembers] AS NM
				ON NM.ApplicationID = @ApplicationID and NM.NodeID = H.NodeID
		END
		ELSE BEGIN
			INSERT INTO @UserIDs (Value)
			SELECT DISTINCT NM.UserID
			FROM @GroupIDs AS G
				INNER JOIN [dbo].[CN_View_NodeMembers] AS NM
				ON NM.ApplicationID = @ApplicationID and NM.NodeID = G.Value
		END
	END

	DECLARE @UsersCount int = (SELECT COUNT(*) FROM @UserIDs)
	DECLARE @GroupsCount int = (SELECT COUNT(*) FROM @GroupIDs)

	SELECT	E.UserID AS UserID_Hide, 
			LTRIM(RTRIM(ISNULL(UN.FirstName, N'') + N' ' + ISNULL(UN.LastName, N''))) AS FullName,
			UN.UserName,
			E.School, 
			E.StudyField, 
			E.StartDate,
			E.EndDate
	FROM [dbo].[USR_EducationalExperiences] AS E
		INNER JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND UN.UserID = E.UserID
	WHERE E.ApplicationID = @ApplicationID AND E.Deleted = 0 AND ISNULL(E.IsSchool, 0) = 0 AND
		((@UsersCount = 0 AND @GroupsCount = 0) OR UN.UserID IN (SELECT U.Value FROM @UserIDs AS U)) AND
		(@UsersCount > 0 OR UN.IsApproved = 1) AND
		(@DateFrom IS NULL OR ISNULL(E.StartDate, E.EndDate) >= @DateFrom) AND
		(@DateTo IS NULL OR ISNULL(E.StartDate, E.EndDate) >= @DateTo)
	ORDER BY E.UserID ASC, ISNULL(E.StartDate, E.EndDate) ASC, E.EndDate ASC
	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'}' +
		   '}') AS Actions
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_ResumeHonorsReport]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_ResumeHonorsReport]
GO

CREATE PROCEDURE [dbo].[USR_ResumeHonorsReport]
	@ApplicationID	uniqueidentifier,
	@CurrentUserID	uniqueidentifier,
	@strUserIDs		varchar(max),
	@strGroupIDs	varchar(max),
	@delimiter		char,
	@Hierarchy		bit,
	@DateFrom		datetime,
	@DateTo			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserIDs GuidTableType

	INSERT INTO @UserIDs (Value)
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strUserIDs, @delimiter) AS Ref

	DECLARE @GroupIDs GuidTableType

	INSERT INTO @GroupIDs (Value)
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strGroupIDs, @delimiter) AS Ref

	IF ((SELECT COUNT(*) FROM @GroupIDs) > 0) AND ((SELECT COUNT(*) FROM @UserIDs) = 0) BEGIN
		IF ISNULL(@Hierarchy, 0) = 1 BEGIN
			INSERT INTO @UserIDs (Value)
			SELECT DISTINCT NM.UserID
			FROM [dbo].[CN_FN_GetChildNodesDeepHierarchy](@ApplicationID, @GroupIDs) AS H
				INNER JOIN [dbo].[CN_View_NodeMembers] AS NM
				ON NM.ApplicationID = @ApplicationID and NM.NodeID = H.NodeID
		END
		ELSE BEGIN
			INSERT INTO @UserIDs (Value)
			SELECT DISTINCT NM.UserID
			FROM @GroupIDs AS G
				INNER JOIN [dbo].[CN_View_NodeMembers] AS NM
				ON NM.ApplicationID = @ApplicationID and NM.NodeID = G.Value
		END
	END

	DECLARE @UsersCount int = (SELECT COUNT(*) FROM @UserIDs)
	DECLARE @GroupsCount int = (SELECT COUNT(*) FROM @GroupIDs)

	SELECT	E.UserID AS UserID_Hide, 
			LTRIM(RTRIM(ISNULL(UN.FirstName, N'') + N' ' + ISNULL(UN.LastName, N''))) AS FullName,
			UN.UserName,
			E.Title, 
			E.Occupation, 
			E.Issuer, 
			E.[Description],
			E.IssueDate
	FROM [dbo].[USR_HonorsAndAwards] AS E
		INNER JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND UN.UserID = E.UserID
	WHERE E.ApplicationID = @ApplicationID AND E.Deleted = 0 AND
		((@UsersCount = 0 AND @GroupsCount = 0) OR UN.UserID IN (SELECT U.Value FROM @UserIDs AS U)) AND
		(@UsersCount > 0 OR UN.IsApproved = 1) AND
		(@DateFrom IS NULL OR E.IssueDate >= @DateFrom) AND
		(@DateTo IS NULL OR E.IssueDate >= @DateTo)
	ORDER BY E.UserID ASC, E.IssueDate ASC
	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'}' +
		   '}') AS Actions
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_ResumeLanguagesReport]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_ResumeLanguagesReport]
GO

CREATE PROCEDURE [dbo].[USR_ResumeLanguagesReport]
	@ApplicationID	uniqueidentifier,
	@CurrentUserID	uniqueidentifier,
	@strUserIDs		varchar(max),
	@strGroupIDs	varchar(max),
	@delimiter		char,
	@Hierarchy		bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserIDs GuidTableType

	INSERT INTO @UserIDs (Value)
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strUserIDs, @delimiter) AS Ref

	DECLARE @GroupIDs GuidTableType

	INSERT INTO @GroupIDs (Value)
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strGroupIDs, @delimiter) AS Ref

	IF ((SELECT COUNT(*) FROM @GroupIDs) > 0) AND ((SELECT COUNT(*) FROM @UserIDs) = 0) BEGIN
		IF ISNULL(@Hierarchy, 0) = 1 BEGIN
			INSERT INTO @UserIDs (Value)
			SELECT DISTINCT NM.UserID
			FROM [dbo].[CN_FN_GetChildNodesDeepHierarchy](@ApplicationID, @GroupIDs) AS H
				INNER JOIN [dbo].[CN_View_NodeMembers] AS NM
				ON NM.ApplicationID = @ApplicationID and NM.NodeID = H.NodeID
		END
		ELSE BEGIN
			INSERT INTO @UserIDs (Value)
			SELECT DISTINCT NM.UserID
			FROM @GroupIDs AS G
				INNER JOIN [dbo].[CN_View_NodeMembers] AS NM
				ON NM.ApplicationID = @ApplicationID and NM.NodeID = G.Value
		END
	END

	DECLARE @UsersCount int = (SELECT COUNT(*) FROM @UserIDs)
	DECLARE @GroupsCount int = (SELECT COUNT(*) FROM @GroupIDs)

	SELECT	E.UserID AS UserID_Hide, 
			LTRIM(RTRIM(ISNULL(UN.FirstName, N'') + N' ' + ISNULL(UN.LastName, N''))) AS FullName,
			UN.UserName,
			L.LanguageName, 
			E.[Level] AS Level_Dic
	FROM [dbo].[USR_UserLanguages] AS E
		INNER JOIN [dbo].[USR_LanguageNames] AS L
		ON L.ApplicationID = @ApplicationID AND L.LanguageID = L.LanguageID
		INNER JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND UN.UserID = E.UserID
	WHERE E.ApplicationID = @ApplicationID AND E.Deleted = 0 AND
		((@UsersCount = 0 AND @GroupsCount = 0) OR UN.UserID IN (SELECT U.Value FROM @UserIDs AS U)) AND
		(@UsersCount > 0 OR UN.IsApproved = 1)
	ORDER BY E.UserID ASC, L.LanguageName ASC
	
	SELECT ('{' +
			'"FullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'}' +
		   '}') AS Actions
END

GO