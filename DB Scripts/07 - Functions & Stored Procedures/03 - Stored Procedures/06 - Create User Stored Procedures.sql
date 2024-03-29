USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetUsersCount]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetUsersCount]
GO

CREATE PROCEDURE [dbo].[USR_GetUsersCount]
	@ApplicationID				uniqueidentifier,
	@CreationDateLowerThreshold datetime,
	@CreationDateUpperThreshold datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	IF @ApplicationID IS NULL BEGIN
		SELECT COUNT(Ref.UserID)
		FROM [dbo].[USR_View_Users] AS Ref
		WHERE Ref.IsApproved = 1 AND (@CreationDateLowerThreshold IS NULL OR Ref.CreationDate >= @CreationDateLowerThreshold) AND
			(@CreationDateUpperThreshold IS NULL OR  Ref.CreationDate <= @CreationDateUpperThreshold)
	END
	ELSE BEGIN
		SELECT COUNT(Ref.UserID)
		FROM [dbo].[Users_Normal] AS Ref
		WHERE ApplicationID = @ApplicationID AND Ref.IsApproved = 1 AND 
			(@CreationDateLowerThreshold IS NULL OR Ref.CreationDate >= @CreationDateLowerThreshold) AND
			(@CreationDateUpperThreshold IS NULL OR Ref.CreationDate <= @CreationDateUpperThreshold)
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetUserIDs]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetUserIDs]
GO

CREATE PROCEDURE [dbo].[USR_GetUserIDs]
	@ApplicationID	uniqueidentifier,
    @UserNamesTemp	StringTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserNames StringTableType
	INSERT INTO @UserNames SELECT * FROM @UserNamesTemp
	
	IF @ApplicationID IS NULL BEGIN
		SELECT UN.UserID AS ID
		FROM @UserNames AS Ref
			INNER JOIN [dbo].[USR_View_Users] AS UN
			ON UN.LoweredUserName = LOWER(Ref.Value)
	END
	ELSE BEGIN
		SELECT UN.UserID AS ID
		FROM @UserNames AS Ref
			INNER JOIN [dbo].[Users_Normal] AS UN
			ON UN.ApplicationID = @ApplicationID AND UN.LoweredUserName = LOWER(Ref.Value)
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_P_GetUsersByIDs]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_P_GetUsersByIDs]
GO

CREATE PROCEDURE [dbo].[USR_P_GetUsersByIDs]
	@ApplicationID	uniqueidentifier,
    @UserIDsTemp	KeyLessGuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserIDs KeyLessGuidTableType
	INSERT INTO @UserIDs (Value) SELECT Value FROM @UserIDsTemp

	IF @ApplicationID IS NULL BEGIN
		SELECT	UN.[UserID], 
				UN.[UserName],
				NULL AS NationalID,
				NULL AS PersonnelID,
				UN.[FirstName], 
				UN.[LastName],
				UN.AvatarName,
				UN.UseAvatar,
				UN.[BirthDay],
				N'' AS AboutMe,
				N'' AS City,
				N'' AS Organization,
				N'' AS Department,
				N'' AS JobTitle,
				UN.[MainPhoneID],
				PN.PhoneNumber AS MainPhoneNumber,
				UN.[MainEmailID],
				EA.EmailAddress AS MainEmailAddress,
				UN.Settings,
				UN.TwoStepAuthentication,
				UN.[IsApproved], 
				UN.[IsLockedOut],
				UN.LastActivityDate
		FROM	@UserIDs AS Ref
				INNER JOIN [dbo].[USR_View_Users] AS UN
				ON UN.[UserID] = Ref.[Value]
				LEFT JOIN [dbo].[USR_EmailAddresses] AS EA
				ON EA.EmailID = UN.MainEmailID
				LEFT JOIN [dbo].[USR_PhoneNumbers] AS PN
				ON PN.NumberID = UN.MainPhoneID
	END
	ELSE BEGIN
		SELECT	UN.[UserID], 
				UN.[UserName],
				UN.NationalID,
				UN.PersonnelID,
				UN.[FirstName], 
				UN.[LastName], 
				UN.AvatarName,
				UN.UseAvatar,
				UN.[BirthDay],
				UN.AboutMe,
				UN.City,
				UN.Organization,
				UN.Department,
				UN.JobTitle,
				UN.[MainPhoneID],
				PN.PhoneNumber AS MainPhoneNumber,
				UN.[MainEmailID],
				EA.EmailAddress AS MainEmailAddress,
				UN.Settings,
				UN.TwoStepAuthentication,
				UN.[IsApproved], 
				UN.[IsLockedOut],
				UN.LastActivityDate
		FROM	@UserIDs AS Ref
				INNER JOIN [dbo].[Users_Normal] AS UN
				ON UN.ApplicationID = @ApplicationID AND UN.[UserID] = Ref.[Value]
				LEFT JOIN [dbo].[USR_EmailAddresses] AS EA
				ON EA.EmailID = UN.MainEmailID
				LEFT JOIN [dbo].[USR_PhoneNumbers] AS PN
				ON PN.NumberID = UN.MainPhoneID
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetUsersByIDs]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetUsersByIDs]
GO

CREATE PROCEDURE [dbo].[USR_GetUsersByIDs]
	@ApplicationID	uniqueidentifier,
	@strUserIDs 	varchar(max),
    @delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserIDs KeyLessGuidTableType
	
	INSERT INTO @UserIDs (Value)
	SELECT Ref.Value FROM GFN_StrToGuidTable(@strUserIDs, @delimiter) AS Ref
	
	EXEC [dbo].[USR_P_GetUsersByIDs] @ApplicationID, @UserIDs
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetUsersByUserName]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetUsersByUserName]
GO

CREATE PROCEDURE [dbo].[USR_GetUsersByUserName]
	@ApplicationID	uniqueidentifier,
    @UserNamesTemp	StringTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserNames StringTableType
	INSERT INTO @UserNames (Value)
	SELECT DISTINCT LOWER(T.Value)
	FROM @UserNamesTemp AS T
	
	DECLARE @UserIDs KeyLessGuidTableType
	
	INSERT INTO @UserIDs (Value)
	SELECT DISTINCT UN.UserID
	FROM @UserNames AS Ref
		INNER JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND LOWER(UN.UserName) = Ref.Value
	
	EXEC [dbo].[USR_P_GetUsersByIDs] @ApplicationID, @UserIDs
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetUsers]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetUsers]
GO

CREATE PROCEDURE [dbo].[USR_GetUsers]
	@ApplicationID	uniqueidentifier,
    @SearchText 	nvarchar(1000),
    @LowerBoundary	bigint,
    @Count			int,
    @IsOnline		bit,
    @IsApproved		bit,
    @Now			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @SearchText = [dbo].[GFN_VerifyString](@SearchText)
	
	IF @Count IS NULL SET @Count = 20
	IF @IsOnline IS NULL SET @IsOnline = 0
	
	DECLARE @OnlineTimeTreshold datetime = DATEADD(MINUTE, -1, @Now)
	
	DECLARE @UserIDs KeyLessGuidTableType
	
	DECLARE @TBL Table (UserID uniqueidentifier, TotalCount bigint, RowNumber int)
	DECLARE @TotalCount bigint = 0
	
	IF @SearchText IS NULL OR @SearchText = '' BEGIN
		INSERT INTO @TBL (UserID, TotalCount, RowNumber)
		SELECT TOP(@Count) U.UserID, (U.RowNumber + U.RevRowNumber - 1) AS TotalCount, U.RowNumber
		FROM (	
				SELECT	ROW_NUMBER() OVER (ORDER BY UN.CreationDate DESC, UN.UserID DESC) AS RowNumber,
						ROW_NUMBER() OVER (ORDER BY UN.CreationDate ASC, UN.UserID ASC) AS RevRowNumber,
						UN.UserID
				FROM [dbo].[Users_Normal] AS UN
				WHERE UN.ApplicationID = @ApplicationID AND 
					(@IsApproved IS NULL OR ISNULL(UN.IsApproved, 1) = @IsApproved) AND
					(@IsOnline = 0 OR UN.LastActivityDate >= @OnlineTimeTreshold)
			) AS U
		WHERE U.RowNumber >= ISNULL(@LowerBoundary, 0)
		ORDER BY U.RowNumber ASC
	END
	ELSE BEGIN
		INSERT INTO @TBL (UserID, TotalCount, RowNumber)
		SELECT TOP(@Count) U.UserID, (U.[No] + U.[RevNo] - 1) AS TotalCount, U.RowNumber
		FROM (	
				SELECT	
						ROW_NUMBER() OVER (ORDER BY SRCH.[Rank] DESC) AS RowNumber,
						ROW_NUMBER() OVER (ORDER BY SRCH.[Rank] DESC, UN.UserID DESC) AS [No],
						ROW_NUMBER() OVER (ORDER BY SRCH.[Rank] ASC, UN.UserID ASC) AS RevNo,
						UN.UserID
				FROM CONTAINSTABLE([dbo].[USR_View_Users], 
						(FirstName, LastName, UserName), @SearchText) AS SRCH
					INNER JOIN [dbo].[Users_Normal] AS UN
					ON UN.UserID = SRCH.[Key]
				WHERE UN.ApplicationID = @ApplicationID AND 
					(@IsApproved IS NULL OR ISNULL(UN.IsApproved, 1) = @IsApproved) AND
					(@IsOnline = 0 OR UN.LastActivityDate >= @OnlineTimeTreshold)
			) AS U
		WHERE U.RowNumber >= ISNULL(@LowerBoundary, 0)
		ORDER BY U.RowNumber ASC
	END
	
	INSERT INTO @UserIDs (Value)
	SELECT T.UserID
	FROM @TBL AS T
	ORDER BY T.RowNumber ASC
	
	EXEC [dbo].[USR_P_GetUsersByIDs] @ApplicationID, @UserIDs
	
	SELECT TOP(1) T.TotalCount AS TotalCount
	FROM @TBL AS T
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetWorkspaceUsers]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetWorkspaceUsers]
GO

CREATE PROCEDURE [dbo].[USR_GetWorkspaceUsers]
	@WorkspaceID	uniqueidentifier,
    @SearchText 	nvarchar(1000),
    @LowerBoundary	bigint,
    @Count			int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @SearchText = [dbo].[GFN_VerifyString](@SearchText)
	SET @Count = ISNULL(@Count, 20)
	
	DECLARE @AllUserIDs KeyLessGuidTableType
	DECLARE @UserIDs KeyLessGuidTableType
	
	IF ISNULL(@SearchText, N'') = N'' BEGIN
		INSERT INTO @AllUserIDs ([Value])
		SELECT DISTINCT UA.UserID
		FROM [dbo].[aspnet_Applications] AS App
			INNER JOIN [dbo].[USR_UserApplications] AS UA
			ON UA.ApplicationID = App.ApplicationId AND ISNULL(UA.Deleted, 0) = 0
			INNER JOIN [dbo].[USR_View_Users] AS U
			ON U.UserID = UA.UserID AND U.LoweredUserName <> N'system'
		WHERE App.WorkspaceID = @WorkspaceID AND ISNULL(App.Deleted, 0) = 0
	END
	ELSE BEGIN
		INSERT INTO @AllUserIDs ([Value])
		SELECT X.UserID
		FROM CONTAINSTABLE([dbo].[USR_View_Users], (FirstName, LastName, UserName), @SearchText) AS SRCH
			INNER JOIN (
				SELECT DISTINCT UA.UserID
				FROM [dbo].[aspnet_Applications] AS App
					INNER JOIN [dbo].[USR_UserApplications] AS UA
					ON UA.ApplicationID = App.ApplicationId AND ISNULL(UA.Deleted, 0) = 0
					INNER JOIN [dbo].[USR_View_Users] AS U
					ON U.UserID = UA.UserID AND U.LoweredUserName <> N'system'
				WHERE App.WorkspaceID = @WorkspaceID AND ISNULL(App.Deleted, 0) = 0
			) AS X
			ON X.UserID = SRCH.[Key]
		ORDER BY SRCH.[Rank] DESC, X.UserID ASC
	END

	INSERT INTO @UserIDs ([Value])
	SELECT TOP(@Count) A.[Value]
	FROM @AllUserIDs AS A
	WHERE A.SequenceNumber >= ISNULL(@LowerBoundary, 0)
	ORDER BY A.SequenceNumber ASC
	
	EXEC [dbo].[USR_P_GetUsersByIDs] NULL, @UserIDs
	
	SELECT COUNT(*) AS TotalCount 
	FROM @AllUserIDs
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetApplicationUsersPartitioned]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetApplicationUsersPartitioned]
GO

CREATE PROCEDURE [dbo].[USR_GetApplicationUsersPartitioned]
	@strApplicationIDs	varchar(max),
	@delimiter			char,
	@Count				int
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @ApplicationIDs GuidTableType
	
	INSERT INTO @ApplicationIDs (Value)
	SELECT DISTINCT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strApplicationIDs, @delimiter) AS Ref
	
	SELECT	X.ApplicationId AS ApplicationID,
			X.UserID,
			X.UserName,
			X.FirstName,
			X.LastName,
			X.AvatarName,
			X.UseAvatar,
			(X.RowNumber + X.RevRowNumber - 1) AS TotalCount
	FROM (
			SELECT	ROW_NUMBER() OVER(PARTITION BY Ref.ApplicationID ORDER BY Ref.RandomID ASC) AS RowNumber,
					ROW_NUMBER() OVER(PARTITION BY Ref.ApplicationID ORDER BY Ref.RandomID DESC) AS RevRowNumber,
					Ref.*
			FROM (
					SELECT	App.ApplicationId,
							USR.*,
							NEWID() AS RandomID
					FROM @ApplicationIDs AS IDs
						INNER JOIN [dbo].[aspnet_Applications] AS App
						ON App.ApplicationId = IDs.Value
						INNER JOIN [dbo].[USR_UserApplications] AS UA
						ON UA.ApplicationID = App.ApplicationId
						INNER JOIN [dbo].[USR_View_Users] AS USR
						ON USR.UserID = UA.UserID AND USR.IsApproved = 1 AND USR.LoweredUserName <> N'system'
				) AS Ref
		) AS X
	WHERE X.RowNumber <= @Count
	ORDER BY X.ApplicationId ASC, X.RowNumber ASC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_AdvancedUserSearch]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_AdvancedUserSearch]
GO

CREATE PROCEDURE [dbo].[USR_AdvancedUserSearch]
	@ApplicationID	uniqueidentifier,
	@RawSearchText	nvarchar(1000),
	@SearchText 	nvarchar(1000),
	@strNodeTypeIDs varchar(max),
	@strNodeIDs		varchar(max),
	@delimiter		char,
	@Members		bit,
	@Experts		bit,
	@Contributors	bit,
	@PropertyOwners	bit,
	@Resume			bit,
    @LowerBoundary	bigint,
    @Count			int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @SearchText = [dbo].[GFN_VerifyString](@SearchText)
	
	DECLARE @NodeIDs GuidTableType
	DECLARE @NodeTypeIDs GuidTableType
	
	INSERT INTO @NodeIDs (Value)
	SELECT DISTINCT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strNodeIDs, @delimiter) AS Ref
	
	DECLARE @NCount int = (SELECT COUNT(*) FROM @NodeIDs)
	
	IF @NCount = 0 BEGIN
		INSERT INTO @NodeTypeIDs (Value)
		SELECT DISTINCT Ref.Value
		FROM [dbo].[GFN_StrToGuidTable](@strNodeTypeIDs, @delimiter) AS Ref
	END
	ELSE SET @SearchText = NULL
	
	DECLARE @NTCount int = (SELECT COUNT(*) FROM @NodeTypeIDs)

	DECLARE @Nodes TABLE (NodeID uniqueidentifier, [Rank] float)
	
	DECLARE @Users TABLE (
		UserID uniqueidentifier, 
		[Rank] float,
		IsMemberCount int,
		IsExpertCount int,
		IsContributorCount int,
		HasPropertyCount int,
		[Resume] int
	)
	
	IF @NCount > 0 BEGIN
		INSERT INTO @Nodes (NodeID, [Rank])
		SELECT Ref.Value, 1
		FROM @NodeIDs AS Ref
	END
	ELSE BEGIN
		INSERT INTO @Nodes (NodeID, [Rank])
		SELECT	ND.NodeID,
				ROW_NUMBER() OVER (ORDER BY SRCH.[Rank] DESC, ND.NodeID ASC)
		FROM CONTAINSTABLE([dbo].[CN_Nodes], ([Name]), @SearchText) AS SRCH
			INNER JOIN [dbo].[CN_Nodes] AS ND
			ON ND.ApplicationID = @ApplicationID AND ND.NodeID = SRCH.[Key] AND
				ND.Deleted = 0 AND ISNULL(ND.Searchable, 1) = 1 AND 
				(@NTCount = 0 OR ND.NodeTypeID IN (SELECT Value FROM @NodeTypeIDs))
	END
	
	DECLARE @SearchedUserIDs TABLE (UserID uniqueidentifier, [Rank] float)
	DECLARE @SearchedResume TABLE (UserID uniqueidentifier, ResumeRank int)
	
	IF @NCount = 0 AND ISNULL(@SearchText, N'') <> N'' BEGIN
		INSERT INTO @SearchedUserIDs (UserID, [Rank])
		SELECT	UN.UserID,
				(ROW_NUMBER() OVER (ORDER BY SRCH.[Rank] ASC, UN.UserID ASC)) AS [Rank]
		FROM CONTAINSTABLE([dbo].[USR_View_Users] , 
				(FirstName, LastName, UserName), @SearchText) AS SRCH
			INNER JOIN [dbo].[Users_Normal] AS UN
			ON UN.ApplicationID = @ApplicationID AND UN.UserID = SRCH.[Key]
			
			
		INSERT INTO @SearchedResume (UserID, ResumeRank)
		SELECT X.UserID, SUM(X.[Rank])
		FROM (
				SELECT	EA.UserID,
						CAST(1 AS int) AS [Rank]
				FROM [dbo].[USR_EmailAddresses] AS EA
					INNER JOIN [dbo].[Users_Normal] AS UN
					ON UN.ApplicationID = @ApplicationID AND UN.UserID = EA.UserID
				WHERE LOWER(EA.EmailAddress) LIKE (N'%' + LOWER(@RawSearchText) + '%') AND EA.Deleted = 0
					
				UNION ALL
				
				SELECT	PN.UserID,
						CAST(1 AS int) AS [Rank]
				FROM [dbo].[USR_PhoneNumbers] AS PN
					INNER JOIN [dbo].[Users_Normal] AS UN
					ON UN.ApplicationID = @ApplicationID AND UN.UserID = PN.UserID
				WHERE PN.PhoneNumber LIKE (N'%' + LOWER(@RawSearchText) + '%') AND PN.Deleted = 0
		
				UNION ALL
		
				SELECT	E.UserID,
						CAST(1 AS int) AS [Rank]
				FROM CONTAINSTABLE([dbo].[USR_EducationalExperiences], 
						(School, StudyField), @SearchText) AS SRCH
					INNER JOIN [dbo].[USR_EducationalExperiences] AS E
					ON E.ApplicationID = @ApplicationID AND E.EducationID = SRCH.[Key]
					
				UNION ALL
				
				SELECT	H.UserID,
						CAST(1 AS int) AS [Rank]
				FROM CONTAINSTABLE([dbo].[USR_HonorsAndAwards], 
						(Title, Issuer, Occupation, [Description]), @SearchText) AS SRCH
					INNER JOIN [dbo].[USR_HonorsAndAwards] AS H
					ON H.ApplicationID = @ApplicationID AND H.ID = SRCH.[Key]
				
				UNION ALL
				
				SELECT	J.UserID,
						CAST(1 AS int) AS [Rank]
				FROM CONTAINSTABLE([dbo].[USR_JobExperiences], 
						(Title, Employer), @SearchText) AS SRCH
					INNER JOIN [dbo].[USR_JobExperiences] AS J
					ON J.ApplicationID = @ApplicationID AND J.JobID = SRCH.[Key]
					
				UNION ALL
				
				SELECT	U.UserID,
						CAST(1 AS int) AS [Rank]
				FROM CONTAINSTABLE([dbo].[USR_LanguageNames], 
						(LanguageName), @SearchText) AS SRCH
					INNER JOIN [dbo].[USR_LanguageNames] AS L
					ON L.ApplicationID = @ApplicationID AND L.LanguageID = SRCH.[Key]
					INNER JOIN [dbo].[USR_UserLanguages] AS U
					ON U.ApplicationID = @ApplicationID AND U.LanguageID = L.LanguageID
			) AS X
		GROUP BY X.UserID
	END

	INSERT INTO @Users (
		UserID, 
		[Rank], 
		IsMemberCount, 
		IsExpertCount, 
		IsContributorCount,
		HasPropertyCount,
		[Resume]
	)
	SELECT	Users.UserID,
			(SUM(Users.[Rank]) + SUM(Users.IsMember) + 
			SUM(Users.IsExpert) + SUM(Users.IsContributor) + 
			SUM(Users.HasProperty) + SUM(Users.[Resume])) AS [Rank],
			SUM(Users.IsMember) AS IsMemberCount,
			SUM(Users.IsExpert) AS IsExpertCount,
			SUM(Users.IsContributor) AS IsContributosCount,
			SUM(Users.HasProperty) AS HasPropertyCount,
			SUM(Users.[Resume]) AS [Resume]
	FROM (
			SELECT	U.UserID,
					2 * U.[Rank] AS [Rank],
					CAST(0 AS int) AS IsMember,
					CAST(0 AS int) AS IsExpert,
					CAST(0 AS int) AS IsContributor,
					CAST(0 AS int) AS HasProperty,
					CAST(0 AS int) AS [Resume]
			FROM @SearchedUserIDs AS U
			
			UNION ALL
			
			SELECT	M.UserID,
					Nodes.[Rank],
					CAST(1 AS int) AS IsMember,
					CAST(0 AS int) AS IsExpert,
					CAST(0 AS int) AS IsContributor,
					CAST(0 AS int) AS HasProperty,
					CAST(0 AS int) AS [Resume]
			FROM @Nodes AS Nodes 
				INNER JOIN [dbo].[CN_View_NodeMembers] AS M
				ON M.ApplicationID = @ApplicationID AND 
					M.NodeID = Nodes.NodeID AND M.IsPending = 0
			WHERE @Members = 1
			
			UNION ALL
			
			SELECT	E.UserID,
					Nodes.[Rank],
					CAST(0 AS int) AS IsMember,
					CAST(1 AS int) AS IsExpert,
					CAST(0 AS int) AS IsContributor,
					CAST(0 AS int) AS HasProperty,
					CAST(0 AS int) AS [Resume]
			FROM @Nodes AS Nodes 
				INNER JOIN [dbo].[CN_View_Experts] AS E
				ON E.ApplicationID = @ApplicationID AND E.NodeID = Nodes.NodeID
			WHERE @Experts = 1
				
			UNION ALL
			
			SELECT	C.UserID,
					Nodes.[Rank],
					CAST(0 AS int) AS IsMember,
					CAST(0 AS int) AS IsExpert,
					CAST(1 AS int) AS IsContributor,
					CAST(0 AS int) AS HasProperty,
					CAST(0 AS int) AS [Resume]
			FROM @Nodes AS Nodes 
				INNER JOIN [dbo].[CN_NodeCreators] AS C
				ON C.ApplicationID = @ApplicationID AND 
					C.NodeID = Nodes.NodeID AND C.Deleted = 0
			WHERE @Contributors = 1
				
			UNION ALL
			
			SELECT	C.UserID,
					Nodes.SeqNo AS [Rank],
					CAST(0 AS int) AS IsMember,
					CAST(0 AS int) AS IsExpert,
					CAST(0 AS int) AS IsContributor,
					CAST(1 AS int) AS HasProperty,
					CAST(0 AS int) AS [Resume]
			FROM (
					SELECT N.NodeID, MAX(N.[Rank]) AS SeqNo
					FROM (
							SELECT I.RelatedNodeID AS NodeID, Nodes.[Rank]
							FROM @Nodes AS Nodes 
								INNER JOIN [dbo].[CN_View_InRelatedNodes] AS I
								ON I.ApplicationID = @ApplicationID AND 
									I.NodeID = Nodes.NodeID
								
							UNION ALL
							
							SELECT O.RelatedNodeID AS NodeID, Nodes.[Rank]
							FROM @Nodes AS Nodes 
								INNER JOIN [dbo].[CN_View_OutRelatedNodes] AS O
								ON O.ApplicationID = @ApplicationID AND 
									O.NodeID = Nodes.NodeID
						) AS N
					GROUP BY N.NodeID
				) AS Nodes
				INNER JOIN [dbo].[CN_NodeCreators] AS C
				ON C.ApplicationID = @ApplicationID AND 
					C.NodeID = Nodes.NodeID AND C.Deleted = 0
			WHERE @PropertyOwners = 1
			
			UNION ALL
			
			SELECT	R.UserID,
					1 AS [Rank],
					CAST(0 AS int) AS IsMember,
					CAST(0 AS int) AS IsExpert,
					CAST(0 AS int) AS IsContributor,
					CAST(0 AS int) AS HasProperty,
					R.ResumeRank AS [Resume]
			FROM @SearchedResume AS R
			WHERE @Resume = 1
		) AS Users
	GROUP BY Users.UserID

	SELECT TOP(ISNULL(@Count, 20)) 
		X.UserID, 
		(X.RowNumber + X.RevRowNumber - 1) AS TotalCount,
		X.[Rank],
		X.IsMemberCount,
		X.IsExpertCount,
		X.IsContributorCount,
		X.HasPropertyCount,
		X.[Resume]
	FROM (
			SELECT	ROW_NUMBER() OVER (ORDER BY U.[Rank] DESC, U.UserID ASC) AS RowNumber,
					ROW_NUMBER() OVER (ORDER BY U.[Rank] ASC, U.UserID DESC) AS RevRowNumber,
					U.*
			FROM @Users AS U
				INNER JOIN [dbo].[Users_Normal] AS UN
				ON UN.ApplicationID = @ApplicationID AND 
					UN.UserID = U.UserID AND UN.IsApproved = 1
		) AS X
	WHERE X.RowNumber >= ISNULL(@LowerBoundary, 0)
	ORDER BY X.RowNumber ASC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_AdvancedUserSearchMeta]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_AdvancedUserSearchMeta]
GO

CREATE PROCEDURE [dbo].[USR_AdvancedUserSearchMeta]
	@ApplicationID	uniqueidentifier,
	@UserID			uniqueidentifier,
	@SearchText 	nvarchar(1000),
	@strNodeTypeIDs varchar(max),
	@strNodeIDs		varchar(max),
	@delimiter		char,
	@Members		bit,
	@Experts		bit,
	@Contributors	bit,
	@PropertyOwners	bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @SearchText = [dbo].[GFN_VerifyString](@SearchText)
	
	DECLARE @NodeIDs GuidTableType
	DECLARE @NodeTypeIDs GuidTableType
	
	INSERT INTO @NodeIDs (Value)
	SELECT DISTINCT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strNodeIDs, @delimiter) AS Ref
	
	DECLARE @NCount int = (SELECT COUNT(*) FROM @NodeIDs)
	
	IF @NCount = 0 BEGIN
		INSERT INTO @NodeTypeIDs (Value)
		SELECT DISTINCT Ref.Value
		FROM [dbo].[GFN_StrToGuidTable](@strNodeTypeIDs, @delimiter) AS Ref
	END
	ELSE SET @SearchText = NULL
	
	DECLARE @NTCount int = (SELECT COUNT(*) FROM @NodeTypeIDs)

	DECLARE @Nodes TABLE (NodeID uniqueidentifier, [Rank] float)

	IF @NCount > 0 BEGIN
		INSERT INTO @Nodes (NodeID, [Rank])
		SELECT Ref.Value, 1
		FROM @NodeIDs AS Ref
	END
	ELSE BEGIN
		INSERT INTO @Nodes (NodeID, [Rank])
		SELECT	ND.NodeID,
				ROW_NUMBER() OVER (ORDER BY SRCH.[Rank] DESC, ND.NodeID ASC)
		FROM CONTAINSTABLE([dbo].[CN_Nodes], ([Name]), @SearchText) AS SRCH
			INNER JOIN [dbo].[CN_Nodes] AS ND
			ON ND.ApplicationID = @ApplicationID AND ND.NodeID = SRCH.[Key] AND
				ND.Deleted = 0 AND ISNULL(ND.Searchable, 1) = 1 AND 
				(@NTCount = 0 OR ND.NodeTypeID IN (SELECT Value FROM @NodeTypeIDs))
	END

	SELECT	Nodes.NodeID,
			SUM(Nodes.[Rank]) AS [Rank],
			CAST(MAX(Nodes.IsMember) AS bit) AS IsMember,
			CAST(MAX(Nodes.IsExpert) AS bit) AS IsExpert,
			CAST(MAX(Nodes.IsContributor) AS bit) AS IsContributor,
			CAST(MAX(Nodes.HasProperty) AS bit) AS HasProperty
	FROM (	
			SELECT	M.NodeID,
					Nodes.[Rank],
					CAST(1 AS int) AS IsMember,
					CAST(0 AS int) AS IsExpert,
					CAST(0 AS int) AS IsContributor,
					CAST(0 AS int) AS HasProperty
			FROM @Nodes AS Nodes 
				INNER JOIN [dbo].[CN_View_NodeMembers] AS M
				ON M.ApplicationID = @ApplicationID AND 
					M.NodeID = Nodes.NodeID AND M.IsPending = 0
			WHERE @Members = 1 AND M.UserID = @UserID
			
			UNION ALL
			
			SELECT	E.NodeID,
					Nodes.[Rank],
					CAST(0 AS int) AS IsMember,
					CAST(1 AS int) AS IsExpert,
					CAST(0 AS int) AS IsContributor,
					CAST(0 AS int) AS HasProperty
			FROM @Nodes AS Nodes 
				INNER JOIN [dbo].[CN_View_Experts] AS E
				ON E.ApplicationID = @ApplicationID AND E.NodeID = Nodes.NodeID
			WHERE @Experts = 1 AND E.UserID = @UserID
				
			UNION ALL
			
			SELECT	C.NodeID,
					Nodes.[Rank],
					CAST(0 AS int) AS IsMember,
					CAST(0 AS int) AS IsExpert,
					CAST(1 AS int) AS IsContributor,
					CAST(0 AS int) AS HasProperty
			FROM @Nodes AS Nodes 
				INNER JOIN [dbo].[CN_NodeCreators] AS C
				ON C.ApplicationID = @ApplicationID AND 
					C.NodeID = Nodes.NodeID AND C.Deleted = 0
			WHERE @Contributors = 1 AND C.UserID = @UserID
				
			UNION ALL
			
			SELECT	Nodes.BaseNodeID AS NodeID,
					MAX(Nodes.SeqNo) AS [Rank],
					CAST(0 AS int) AS IsMember,
					CAST(0 AS int) AS IsExpert,
					CAST(0 AS int) AS IsContributor,
					CAST(1 AS int) AS HasProperty
			FROM (
					SELECT	N.NodeID, 
							CAST(MAX(CAST(N.BaseNodeID AS varchar(50))) AS uniqueidentifier) AS BaseNodeID, 
							MAX(N.[Rank]) AS SeqNo
					FROM (
							SELECT	I.NodeID AS BaseNodeID, 
									I.RelatedNodeID AS NodeID, 
									Nodes.[Rank]
							FROM @Nodes AS Nodes 
								INNER JOIN [dbo].[CN_View_InRelatedNodes] AS I
								ON I.ApplicationID = @ApplicationID AND 
									I.NodeID = Nodes.NodeID
								
							UNION ALL
							
							SELECT	O.NodeID AS BaseNodeID,
									O.RelatedNodeID AS NodeID, 
									Nodes.[Rank]
							FROM @Nodes AS Nodes 
								INNER JOIN [dbo].[CN_View_OutRelatedNodes] AS O
								ON O.ApplicationID = @ApplicationID AND 
									O.NodeID = Nodes.NodeID
						) AS N
					GROUP BY N.NodeID
				) AS Nodes
				INNER JOIN [dbo].[CN_NodeCreators] AS C
				ON C.ApplicationID = @ApplicationID AND 
					C.NodeID = Nodes.NodeID AND C.Deleted = 0
			WHERE @PropertyOwners = 1 AND C.UserID = @UserID
			GROUP BY Nodes.BaseNodeID
		) AS Nodes
	GROUP BY Nodes.NodeID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_P_CreateSystemUser]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_P_CreateSystemUser]
GO

CREATE PROCEDURE [dbo].[USR_P_CreateSystemUser]
	@ApplicationID	uniqueidentifier,
	@UserID			uniqueidentifier,
	@_Result		int output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF NOT EXISTS(
		SELECT TOP(1) * 
		FROM [dbo].[Users_Normal]
		WHERE (@ApplicationID IS NULL OR ApplicationId = @ApplicationID) AND LoweredUserName = N'system'
	) BEGIN
		INSERT INTO [dbo].[aspnet_Users] ([UserId], [UserName], 
			[LoweredUserName], [MobileAlias], [IsAnonymous], [LastActivityDate]) 
		VALUES (@UserID, N'system', N'system', NULL, 0, CAST(0x0000A1A900C898BC AS DateTime))
		
		INSERT INTO [dbo].[USR_Profile] ( 
			[UserId], 
			[FirstName],
			[Lastname], 
			[BirthDay]
		) 
		VALUES (@UserID, N'رای', N'ون', NULL)
			
		INSERT INTO [dbo].[aspnet_Membership] ([UserId], [Password], 
			[PasswordFormat], [PasswordSalt], [MobilePIN], [Email], [LoweredEmail], 
			[PasswordQuestion], [PasswordAnswer], [IsApproved], [IsLockedOut], [CreateDate], 
			[LastLoginDate], [LastPasswordChangedDate], [LastLockoutDate], 
			[FailedPasswordAttemptCount], [FailedPasswordAttemptWindowStart], 
			[FailedPasswordAnswerAttemptCount], [FailedPasswordAnswerAttemptWindowStart], 
			[Comment]) 
		VALUES (@UserID, N'saS+wizpq8cetvwnCAdCAHek3Ls=', 1, N'0QnG9cGvuzB99qo+ycdaow==', NULL, NULL, NULL, NULL, 
			NULL, 1, 0, CAST(0x0000A1A900C898BC AS DateTime), CAST(0x0000A1A900C898BC AS DateTime), 
			CAST(0x0000A1A900C898BC AS DateTime), CAST(0xFFFF2FB300000000 AS DateTime), 0, 
			CAST(0xFFFF2FB300000000 AS DateTime), 0, CAST(0xFFFF2FB300000000 AS DateTime), NULL)
			
		IF @ApplicationID IS NOT NULL BEGIN
			INSERT INTO [dbo].[USR_UserApplications] (ApplicationID, UserID)
			VALUES (@ApplicationID, @UserID)
		END
	END
	
	SET @_Result = 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetSystemUser]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetSystemUser]
GO

CREATE PROCEDURE [dbo].[USR_GetSystemUser]
	@ApplicationID	uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserIDs KeyLessGuidTableType
	
	IF NOT EXISTS(
		SELECT TOP(1) * 
		FROM [dbo].[Users_Normal]
		WHERE (@ApplicationID IS NULL OR ApplicationId = @ApplicationID) AND LoweredUserName = N'system'
	) BEGIN
		DECLARE @UserID uniqueidentifier = NEWID()
		DECLARE @_Result int
		
		INSERT INTO @UserIDs (Value) 
		VALUES (@UserID)
		
		EXEC [dbo].[USR_P_CreateSystemUser] @ApplicationID, @UserID, @_Result output
	END
	ELSE BEGIN
		IF @ApplicationID IS NULL BEGIN
			INSERT INTO @UserIDs (Value)
			SELECT UserId
			FROM [dbo].[USR_View_Users]
			WHERE LoweredUserName = N'system'
		END
		ELSE BEGIN
			INSERT INTO @UserIDs (Value)
			SELECT UserId
			FROM [dbo].[Users_Normal]
			WHERE ApplicationID = @ApplicationID AND LoweredUserName = N'system'
		END
	END
	
	EXEC [dbo].[USR_P_GetUsersByIDs] @ApplicationID, @UserIDs
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_CreateAdminUser]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_CreateAdminUser]
GO

CREATE PROCEDURE [dbo].[USR_CreateAdminUser]
	@ApplicationID	uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF NOT EXISTS(
		SELECT TOP(1) * 
		FROM [dbo].[Users_Normal]
		WHERE ApplicationId = @ApplicationID AND LoweredUserName = N'admin'
	) BEGIN
		DECLARE @AdminRoleID uniqueidentifier = (
			SELECT TOP(1) RoleID
			FROM [dbo].[aspnet_Roles]
			WHERE ApplicationID = @ApplicationID AND LoweredRoleName = N'admins'
		)
	
		IF @AdminRoleID IS NULL BEGIN
			SET @AdminRoleID = NEWID()
		
			INSERT INTO [dbo].[aspnet_Roles] (
				ApplicationID,
				RoleID,
				RoleName,
				LoweredRoleName
			)
			VALUES (
				@ApplicationID,
				@AdminRoleID,
				N'Admins',
				N'admins'
			)
		END
	
		DECLARE @UserID uniqueidentifier = NEWID()
	
		INSERT INTO [dbo].[aspnet_Users] ([UserId], [UserName], 
			[LoweredUserName], [MobileAlias], [IsAnonymous], [LastActivityDate]) 
		VALUES (@UserID, N'admin', N'admin', NULL, 0, CAST(0x0000A1A900C898BC AS DateTime))
			
		INSERT INTO [dbo].[aspnet_UsersInRoles] (UserID, RoleID)
		VALUES (@UserID, @AdminRoleID)
		
		INSERT INTO [dbo].[USR_Profile] (
			[UserId], 
			[FirstName],
			[Lastname], 
			[BirthDay]
		) 
		VALUES (@UserID, N'مدیر', N'سیستم', NULL)
			
		INSERT INTO [dbo].[aspnet_Membership] ([UserId], [Password], 
			[PasswordFormat], [PasswordSalt], [MobilePIN], [Email], [LoweredEmail], 
			[PasswordQuestion], [PasswordAnswer], [IsApproved], [IsLockedOut], [CreateDate], 
			[LastLoginDate], [LastPasswordChangedDate], [LastLockoutDate], 
			[FailedPasswordAttemptCount], [FailedPasswordAttemptWindowStart], 
			[FailedPasswordAnswerAttemptCount], [FailedPasswordAnswerAttemptWindowStart], 
			[Comment]) 
		VALUES (@UserID, N'hzpljiwy35CCLSmxIuTk49mhDI4=', 1, N'6rG7hIBmkJ6cfestS4Ycow==', NULL, NULL, NULL, NULL, 
			NULL, 1, 0, CAST(0x0000A1A900C898BC AS DateTime), CAST(0x0000A1A900C898BC AS DateTime), 
			CAST(0x0000A1A900C898BC AS DateTime), CAST(0xFFFF2FB300000000 AS DateTime), 0, 
			CAST(0xFFFF2FB300000000 AS DateTime), 0, CAST(0xFFFF2FB300000000 AS DateTime), NULL)
			
		INSERT INTO [dbo].[USR_UserApplications] (ApplicationID, UserID)
		VALUES (@ApplicationID, @UserID)
	END
	
	SELECT 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetNotExistingUsers]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetNotExistingUsers]
GO

CREATE PROCEDURE [dbo].[USR_GetNotExistingUsers]
	@ApplicationID	uniqueidentifier,
    @UserNamesTemp	StringTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserNames StringTableType
	INSERT INTO @UserNames SELECT * FROM @UserNamesTemp
	
	SELECT DISTINCT Ref.Value AS Value
	FROM @UserNames AS Ref
	WHERE NOT EXISTS(
			SELECT TOP(1) * 
			FROM [dbo].[Users_Normal]
			WHERE ApplicationID = @ApplicationID AND 
				UserName = Ref.Value OR LoweredUserName = LOWER(Ref.Value)
		)
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_RegisterItemVisit]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_RegisterItemVisit]
GO

CREATE PROCEDURE [dbo].[USR_RegisterItemVisit]
	@ApplicationID	uniqueidentifier,
    @ItemID			uniqueidentifier,
    @UserID			uniqueidentifier,
    @VisitDate		datetime,
    @ItemType		varchar(20)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	INSERT INTO [dbo].[USR_ItemVisits](
		ApplicationID,
		ItemID,
		VisitDate,
		UserID,
		ItemType,
		UniqueID
	)
	VALUES(
		@ApplicationID,
		@ItemID,
		@VisitDate,
		@UserID,
		@ItemType,
		NEWID()
	)
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetItemsVisitsCount]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetItemsVisitsCount]
GO

CREATE PROCEDURE [dbo].[USR_GetItemsVisitsCount]
	@ApplicationID	uniqueidentifier,
    @strItemIDs		uniqueidentifier,
    @delimiter		char,
    @lowerDateLimit	datetime,
    @upperDateLimit	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @ItemIDs GuidTableType
	INSERT INTO @ItemIDs
	SELECT DISTINCT Ref.Value FROM GFN_StrToGuidTable(@strItemIDs, @delimiter) AS Ref
	
	SELECT ExternalIDs.Value AS ItemID,
		   (
				SELECT COUNT(*) 
				FROM [dbo].[USR_ItemVisits]
				WHERE ApplicationID = @ApplicationID AND ItemID = ExternalIDs.Value AND
					(@lowerDateLimit IS NULL OR VisitDate >= @lowerDateLimit) AND
					(@upperDateLimit IS NULL OR VisitDate <= @upperDateLimit)
			) AS VisitsCount
	FROM @ItemIDs AS ExternalIDs
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_SendFriendshipRequest]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_SendFriendshipRequest]
GO

CREATE PROCEDURE [dbo].[USR_SendFriendshipRequest]
	@ApplicationID	uniqueidentifier,
    @UserID			uniqueidentifier,
    @ReceiverUserID	uniqueidentifier,
    @RequestDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF NOT EXISTS(
		SELECT TOP(1) * 
		FROM [dbo].[USR_Friends]
		WHERE ApplicationID = @ApplicationID AND 
			((SenderUserID = @UserID AND ReceiverUserID = @ReceiverUserID) OR
			(SenderUserID = @ReceiverUserID AND ReceiverUserID = @UserID))
	) BEGIN
		INSERT INTO [dbo].[USR_Friends](
			ApplicationID,
			SenderUserID,
			ReceiverUserID,
			RequestDate,
			AreFriends,
			Deleted,
			UniqueID
		)
		VALUES(
			@ApplicationID,
			@UserID,
			@ReceiverUserID,
			@RequestDate,
			0,
			0,
			NEWID()
		)
	END
	ELSE BEGIN
		UPDATE [dbo].[USR_Friends]
			SET SenderUserID = @UserID,
				ReceiverUserID = @ReceiverUserID,
				RequestDate = @RequestDate,
				AcceptionDate = NULL,
				AreFriends = 0,
				Deleted = 0
		WHERE ApplicationID = @ApplicationID AND
			(SenderUserID = @UserID AND ReceiverUserID = @ReceiverUserID) OR
			(SenderUserID = @ReceiverUserID AND ReceiverUserID = @UserID)
	END
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_AcceptFriendship]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_AcceptFriendship]
GO

CREATE PROCEDURE [dbo].[USR_AcceptFriendship]
	@ApplicationID	uniqueidentifier,
    @UserID			uniqueidentifier,
    @SenderUserID	uniqueidentifier,
    @AcceptionDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[USR_Friends]
		SET AreFriends = 1,
			AcceptionDate = @AcceptionDate
	WHERE ApplicationID = @ApplicationID AND 
		SenderUserID = @SenderUserID AND ReceiverUserID = @UserID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_RejectFriendship]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_RejectFriendship]
GO

CREATE PROCEDURE [dbo].[USR_RejectFriendship]
	@ApplicationID	uniqueidentifier,
    @UserID			uniqueidentifier,
    @FriendUserID	uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[USR_Friends]
		SET AreFriends = 0,
			Deleted = 1
	WHERE ApplicationID = @ApplicationID AND 
		(SenderUserID = @UserID AND ReceiverUserID = @FriendUserID) OR
		(SenderUserID = @FriendUserID AND ReceiverUserID = @UserID)
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetFriendshipStatus]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetFriendshipStatus]
GO

CREATE PROCEDURE [dbo].[USR_GetFriendshipStatus]
	@ApplicationID		uniqueidentifier,
    @UserID				uniqueidentifier,
    @strOtherUserIDs	varchar(max),
    @delimiter			char,
    @MutualsCount		bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @OtherUserIDs GuidTableType
	INSERT INTO @OtherUserIDs
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strOtherUserIDs, @delimiter) AS Ref
	
	DECLARE @RetTbl TABLE (
		UserID				uniqueidentifier,
		IsFriend			bit,
		IsSender			bit,
		MutualFriendsCount	int
	)
	
	INSERT INTO @RetTbl (UserID, IsFriend, IsSender)
	SELECT	O.Value AS UserID,
			ISNULL(F.AreFriends, 0) AS IsFriend,
			ISNULL(F.IsSender, 0) AS IsSender
	FROM @OtherUserIDs AS O
		INNER JOIN [dbo].[USR_View_Friends] AS F
		ON F.UserID = @UserID AND F.FriendID = O.Value
	WHERE F.ApplicationID = @ApplicationID
		
	IF @MutualsCount = 1 BEGIN
		UPDATE Ref
			SET MutualFriendsCount = M.MutualFriendsCount
		FROM @RetTbl AS Ref
			LEFT JOIN [dbo].[USR_FN_GetMutualFriendsCount](@ApplicationID, @UserID, @OtherUserIDs) AS M
			ON Ref.UserID = M.UserID
	END
	
	SELECT *
	FROM @RetTbl
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_P_UpdateFriendSuggestions]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_P_UpdateFriendSuggestions]
GO

CREATE PROCEDURE [dbo].[USR_P_UpdateFriendSuggestions]
	@ApplicationID	uniqueidentifier,
    @UserIDsTemp	GuidTableType readonly,
    @_Result		int output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserIDs GuidTableType
	INSERT INTO @UserIDs SELECT * FROM @UserIDsTemp
	
	DECLARE @Suggestions TABLE (
		UserID UNIQUEIDENTIFIER, 
		OtherUserID UNIQUEIDENTIFIER, 
		Score FLOAT
	)
	
	
	-- Fetch All of the Selected Data and Calculate Score for Each Suggestion
	
	INSERT INTO @Suggestions (UserID, OtherUserID, Score)
	SELECT	D.UserID, 
			D.OtherUserID,
			(
				(20 * MAX(D.GroupsCount)) + 
				(50 * MAX(D.HasInvitation)) + 
				(10 * MAX(D.MutualsCount))
			) AS Score
	FROM (
			-- Select FriendsOfFriends With Mutual Friends Count
			
			SELECT	F.UserID, 
					F2.FriendID AS OtherUserID, 
					COUNT(F.FriendID) AS MutualsCount,
					CAST(0 AS int) AS HasInvitation, 
					CAST(0 AS int) AS GroupsCount
			FROM @UserIDs AS Ref
				INNER JOIN [dbo].[USR_View_Friends] AS F
				ON F.UserID = Ref.Value
				INNER JOIN [dbo].[USR_View_Friends] AS F2
				ON F2.ApplicationID = @ApplicationID AND 
					F2.UserID = F.FriendID AND F2.FriendID <> F.UserID
				LEFT JOIN [dbo].[USR_View_Friends] AS L1
				ON L1.ApplicationID = @ApplicationID AND 
					L1.UserID = F.UserID AND L1.FriendID = F2.FriendID
			WHERE F.ApplicationID = @ApplicationID AND 
				F.AreFriends = 1 AND F2.AreFriends = 1 AND L1.UserID IS NULL
			GROUP BY F.UserID, F2.FriendID
			
			-- end of Select FriendsOfFriends With Mutual Friends Count
			
			UNION ALL
			
			-- Calculate Mutual Friends Count for 'Invitations' and 'Groupmates'

			SELECT	Y.UserID, 
					Y.OtherUserID, 
					SUM(
						CASE 
							WHEN F.UserID IS NOT NULL AND F2.UserID IS NOT NULL AND
								F.AreFriends = 1 AND F2.AreFriends = 1 AND 
								F2.FriendID <> Y.UserID AND F.FriendID <> Y.OtherUserID
							THEN 1
							ELSE 0
						END
					) AS MutualsCount,
					MAX(Y.HasInvitation) AS HasInvitation, 
					MAX(Y.GroupsCount) AS GroupsCount
			FROM (
					-- Fetch 'Invitations' and 'Groupmates' and Remove Pairs Who Are Already Friends
					
					SELECT	Ref.UserID, 
							Ref.OtherUserID, 
							SUM(Ref.HasInvitation) AS HasInvitation,
							SUM(Ref.GroupsCount) AS GroupsCount
					FROM (
							-- Suggest Friends Based on Invitations
							
							SELECT DISTINCT
									Ref.Value AS UserID,
									(
										CASE 
											WHEN I.SenderUserID = Ref.Value THEN I.CreatedUserID 
											ELSE I.SenderUserID END
									) AS OtherUserID,
									CAST(1 AS int) AS HasInvitation,
									0 AS GroupsCount
							FROM @UserIDs AS Ref
								INNER JOIN [dbo].[USR_Invitations] AS I
								ON I.ApplicationID = @ApplicationID AND
									I.SenderUserID = Ref.Value OR I.CreatedUserID = Ref.Value
								INNER JOIN [dbo].[Users_Normal] AS UN
								ON UN.ApplicationID = @ApplicationID AND 
									UN.UserID = I.CreatedUserID
								
							-- end of Suggest Friends Based on Invitations
								
							UNION ALL
							
							-- Suggest Friends Based on Being Groupmate
							
							SELECT	NM.UserID, 
									NM2.UserID AS OtherUserID, 
									0 AS HasInvitation,
									COUNT(NM.NodeID) AS GroupsCount
							FROM @UserIDs AS Ref
								INNER JOIN [dbo].[CN_View_NodeMembers] AS NM
								ON NM.ApplicationID = @ApplicationID AND 
									NM.UserID = Ref.Value AND NM.IsPending = 0
								INNER JOIN [dbo].[CN_View_NodeMembers] AS NM2
								ON NM2.ApplicationID = @ApplicationID AND 
									NM2.NodeID = NM.NodeID AND NM2.UserID <> NM.UserID AND
									NM2.IsPending = 0
							GROUP BY NM.UserID, NM2.UserID
							
							-- end of Suggest Friends Based on Being Groupmate
						) AS Ref
						LEFT JOIN [dbo].[USR_View_Friends] AS F
						ON F.ApplicationID = @ApplicationID AND 
							F.UserID = Ref.UserID AND F.FriendID = Ref.OtherUserID
					WHERE F.UserID IS NULL
					GROUP BY Ref.UserID, Ref.OtherUserID
					
					-- end of Fetch 'Invitations' and 'Groupmates' and Remove Pairs Who Are Already Friends
				) AS Y
				LEFT JOIN [dbo].[USR_View_Friends] AS F
				ON F.ApplicationID = @ApplicationID AND F.UserID = Y.UserID
				LEFT JOIN [dbo].[USR_View_Friends] AS F2
				ON F2.ApplicationID = @ApplicationID AND 
					F2.UserID = Y.OtherUserID AND F2.FriendID = F.FriendID
			GROUP BY Y.UserID, Y.OtherUserID
			
			-- end of Calculate Mutual Friends Count for 'Invitations' and 'Groupmates'
		) AS D
	GROUP BY D.UserID, D.OtherUserID
	
	-- end of Fetch All of the Selected Data and Calculate Score for Each Suggestion
	
	
	-- Remove Suggestions Collected for Target Users
	
	DELETE FS
	FROM @UserIDs AS Ref
		INNER JOIN [dbo].[USR_FriendSuggestions] AS FS
		ON FS.ApplicationID = @ApplicationID AND FS.UserID = Ref.Value
		
	-- end of Remove Suggestions Collected for Target Users	
	
	
	-- Insert Collected Suggestions Into USR_FriendSuggestions Table

	INSERT INTO [dbo].[USR_FriendSuggestions] (
		ApplicationID,
		UserID, 
		SuggestedUserID, 
		Score
	)
	SELECT DISTINCT
		@ApplicationID,
		FS.UserID,
		FS.OtherUserID,
		FS.Score
	FROM @Suggestions AS FS
	WHERE FS.UserID <> FS.OtherUserID
	
	-- end of Insert Collected Suggestions Into USR_FriendSuggestions Table
	

	SET @_Result = 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_UpdateFriendSuggestions]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_UpdateFriendSuggestions]
GO

CREATE PROCEDURE [dbo].[USR_UpdateFriendSuggestions]
	@ApplicationID	uniqueidentifier,
    @UserID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @IDs TABLE (ID bigint IDENTITY(1, 1) primary key clustered, UserID uniqueidentifier)
	
	IF @UserID IS NULL BEGIN
		INSERT INTO @IDs (UserID)
		SELECT DISTINCT F.UserID
		FROM [dbo].[USR_View_Friends] AS F
		WHERE F.ApplicationID = @ApplicationID
	END
	ELSE INSERT INTO @IDs (UserID) VALUES(@UserID)
	
	DECLARE @_Result int = 0
	
	DECLARE @UserIDs GuidTableType
	DECLARE @Count bigint = (SELECT MAX(ID) FROM @IDs)
	DECLARE @BatchSize bigint = 50, @Lower bigint = 0
	
	WHILE @Count > 0 BEGIN
		DELETE @UserIDs
		
		INSERT INTO @UserIDs(Value)
		SELECT Ref.UserID
		FROM @IDs AS Ref
		WHERE Ref.ID > @Lower AND Ref.ID <= @Lower + @BatchSize
	
		EXEC [dbo].[USR_P_UpdateFriendSuggestions] @ApplicationID, @UserIDs, @_Result output
		
		SET @Lower = @Lower + @BatchSize
		SET @Count = @Count - @BatchSize
	END
	
	SELECT @_Result
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetFriendSuggestions]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetFriendSuggestions]
GO

CREATE PROCEDURE [dbo].[USR_GetFriendSuggestions]
	@ApplicationID	uniqueidentifier,
    @UserID			UNIQUEIDENTIFIER,
    @Count			INT,
    @LowerBoundary	int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @RetTbl Table (
		UserID uniqueidentifier, 
		UserName nvarchar(200), 
		FirstName nvarchar(500), 
		LastName nvarchar(500), 
		AvatarName varchar(50),
		UseAvatar bit,
		MutualFriendsCount int, 
		[Order] bigint, 
		TotalCount bigint
	)
	
	INSERT INTO @RetTbl (UserID, UserName, FirstName, LastName, AvatarName, UseAvatar, [Order], TotalCount)
	SELECT TOP(ISNULL(@Count, 100000))
		F.SuggestedUserID,
		F.UserName,
		F.FirstName,
		F.LastName,
		F.AvatarName,
		F.UseAvatar,
		F.RowNumber AS [Order],
		(F.RowNumber + F.RevRowNumber - 1) AS TotalCount
	FROM (
			SELECT
				S.SuggestedUserID,
				UN.UserName,
				UN.FirstName,
				UN.LastName,
				UN.AvatarName,
				UN.UseAvatar,
				ROW_NUMBER() OVER (ORDER BY S.Score DESC, S.SuggestedUserID DESC) AS RowNumber,
				ROW_NUMBER() OVER (ORDER BY S.Score ASC, S.SuggestedUserID ASC) AS RevRowNumber
			FROM [dbo].[USR_FriendSuggestions] AS S
				LEFT JOIN [dbo].[USR_View_Friends] AS F
				ON F.ApplicationID = @ApplicationID AND 
					F.UserID = S.UserID AND F.FriendID = S.SuggestedUserID
				INNER JOIN [dbo].[Users_Normal] AS UN
				ON UN.ApplicationID = @ApplicationID AND UN.UserID = S.SuggestedUserID
			WHERE S.ApplicationID = @ApplicationID AND S.UserID = @UserID AND UN.IsApproved = 1 AND F.UserID IS NULL
		) AS F
	WHERE F.RowNumber >= ISNULL(@LowerBoundary, 0)
	ORDER BY F.RowNumber ASC
	
	DECLARE @OtherUserIDs GuidTableType
	INSERT INTO @OtherUserIDs
	SELECT Ref.UserID
	FROM @RetTbl AS Ref
	
	UPDATE Ref
		SET MutualFriendsCount = O.MutualFriendsCount
	FROM @RetTbl AS Ref
		INNER JOIN [dbo].[USR_FN_GetMutualFriendsCount](@ApplicationID, @UserID, @OtherUserIDs) AS O
		ON Ref.UserID = O.UserID
		
	SELECT *
	FROM @RetTbl AS Ref
	ORDER BY Ref.[Order] DESC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetFriendIDs]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetFriendIDs]
GO

CREATE PROCEDURE [dbo].[USR_GetFriendIDs]
	@ApplicationID	uniqueidentifier,
    @UserID			uniqueidentifier,
    @AreFriends		bit,
    @Sent			bit,
    @Received		bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT Ref.UserID AS ID
	FROM [dbo].[USR_FN_GetFriendIDs](@ApplicationID, @UserID, @AreFriends, @Sent, @Received) AS Ref
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetFriends]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetFriends]
GO

CREATE PROCEDURE [dbo].[USR_GetFriends]
	@ApplicationID	uniqueidentifier,
    @UserID			uniqueidentifier,
    @strFriendIDs	varchar(max),
    @delimiter		char,
    @MutualsCount	bit,
    @AreFriends		bit,
    @IsSender		bit,
    @SearchText		nvarchar(1000),
    @Count			int,
    @LowerBoundary	bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF @SearchText = N'' SET @SearchText = NULL
	
	DECLARE @FriendIDs GuidTableType
	INSERT INTO @FriendIDs
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strFriendIDs, @delimiter) AS Ref
	
	DECLARE @FIDsCount int = (SELECT COUNT(*) FROM @FriendIDs)
	
	IF @FIDsCount > 0 SET @Count = 1000000
	
	DECLARE @x Table (FriendID uniqueidentifier primary key clustered,
		UserName nvarchar(1000), FirstName nvarchar(1000), LastName nvarchar(1000),
		AvatarName varchar(50), UseAvatar bit,
		RequestDate datetime, AcceptionDate datetime, AreFriends bit,
		IsSender bit, RowNumber bigint, RevRowNumber bigint)
	
	IF @SearchText IS NULL BEGIN
		INSERT INTO @x (
			FriendID, UserName, FirstName, LastName, AvatarName, UseAvatar, RequestDate, 
			AcceptionDate, AreFriends, IsSender, RowNumber, RevRowNumber
		)
		SELECT f.FriendID, f.UserName, f.FirstName, f.LastName, f.AvatarName, f.UseAvatar,
			f.RequestDate, f.AcceptionDate, f.AreFriends, f.IsSender,
			ROW_NUMBER() OVER (ORDER BY f.LastActivityDate DESC, f.FriendID DESC) AS RowNumber,
			ROW_NUMBER() OVER (ORDER BY f.LastActivityDate ASC, f.FriendID ASC) AS RevRowNumber
		FROM (
			SELECT UN.UserID AS FriendID,
				   UN.UserName AS UserName,
				   UN.FirstName AS FirstName,
				   UN.LastName AS LastName,
				   UN.AvatarName,
				   UN.UseAvatar,
				   FR.RequestDate AS RequestDate,
				   FR.AcceptionDate AS AcceptionDate,
				   FR.AreFriends AS AreFriends,
				   FR.IsSender AS IsSender,
				   UN.LastActivityDate
			FROM [dbo].[USR_View_Friends] AS FR
				LEFT JOIN [dbo].[Users_Normal] AS UN
				ON UN.ApplicationID = @ApplicationID AND UN.UserID = FR.FriendID
			WHERE FR.ApplicationID = @ApplicationID AND 
				@SearchText IS NULL AND FR.UserID = @UserID AND
				(@IsSender IS NULL OR FR.IsSender = @IsSender) AND
				(@FIDsCount = 0 OR FR.FriendID IN (SELECT * FROM @FriendIDs)) AND
				(@AreFriends IS NULL OR FR.AreFriends = @AreFriends)
		) AS f	
	END
	ELSE BEGIN
		INSERT INTO @x (
			FriendID, UserName, FirstName, LastName, AvatarName, UseAvatar, RequestDate, 
			AcceptionDate, AreFriends, IsSender, RowNumber, RevRowNumber
		)
		SELECT f.FriendID, f.UserName, f.FirstName, f.LastName, f.AvatarName, f.UseAvatar, 
			f.RequestDate, f.AcceptionDate, f.AreFriends, f.IsSender,
			ROW_NUMBER() OVER (ORDER BY f.[Rank] DESC, f.LastActivityDate DESC, f.FriendID DESC) AS RowNumber,
			ROW_NUMBER() OVER (ORDER BY f.[Rank] ASC, f.LastActivityDate ASC, f.FriendID ASC) AS RevRowNumber
		FROM (
			SELECT UN.UserID AS FriendID,
				   UN.UserName AS UserName,
				   UN.FirstName AS FirstName,
				   UN.LastName AS LastName,
				   UN.AvatarName,
				   UN.UseAvatar,
				   FR.RequestDate AS RequestDate,
				   FR.AcceptionDate AS AcceptionDate,
				   FR.AreFriends AS AreFriends,
				   FR.IsSender AS IsSender,
				   UN.LastActivityDate,
				   SRCH.[Rank] AS [Rank]
			FROM CONTAINSTABLE([dbo].[USR_View_Users], 
					(FirstName, LastName, UserName), @SearchText) AS SRCH
				INNER JOIN [dbo].[USR_View_Friends] AS FR
				ON FR.FriendID = SRCH.[Key]
				LEFT JOIN [dbo].[Users_Normal] AS UN
				ON UN.ApplicationID = @ApplicationID AND UN.UserID = FR.FriendID
			WHERE FR.ApplicationID = @ApplicationID AND 
				@SearchText IS NOT NULL AND FR.UserID = @UserID AND
				(@IsSender IS NULL OR FR.IsSender = @IsSender) AND
				(@FIDsCount = 0 OR FR.FriendID IN (SELECT * FROM @FriendIDs)) AND
				(@AreFriends IS NULL OR FR.AreFriends = @AreFriends)
		) AS f
	END

	SELECT TOP(ISNULL(@Count, 1000000)) *
	FROM (
			SELECT
				MyFriends.FriendID AS UserID,
				MAX(MyFriends.UserName) AS UserName,
				MAX(MyFriends.FirstName) AS FirstName,
				MAX(MyFriends.LastName) AS LastName,
				MAX(MyFriends.AvatarName) AS AvatarName,
				CAST(MAX(CAST(MyFriends.UseAvatar AS int)) AS bit) AS UseAvatar,
				MAX(MyFriends.RequestDate) AS RequestDate,
				MAX(MyFriends.AcceptionDate) AS AcceptionDate,
				CAST(MAX(CAST(MyFriends.AreFriends AS int)) AS bit) AS AreFriends,
				CAST(MAX(CAST(MyFriends.IsSender AS int)) AS bit) AS IsSender,
				COUNT(FriendsOfFriends.FriendOfFriend) AS MutualFriendsCount,
				MAX(MyFriends.RowNumber) AS [Order],
				(MAX(MyFriends.RowNumber) + MAX(MyFriends.RevRowNumber) - 1) AS TotalCount
			FROM @x AS MyFriends
				LEFT JOIN (
					SELECT x.FriendID AS Friend, 
						CASE 
							WHEN UC.SenderUserID = x.FriendID THEN UC.ReceiverUserID
							ELSE UC.SenderUserID
						END AS FriendOfFriend
					FROM @x AS x
						INNER JOIN [dbo].[USR_Friends] AS UC
						ON UC.ApplicationID = @ApplicationID AND 
							UC.AreFriends = 1 AND UC.Deleted = 0 AND (
								UC.ReceiverUserID = x.FriendID OR UC.SenderUserID = x.FriendID
							)
				) FriendsOfFriends
				ON @MutualsCount = 1 AND MyFriends.FriendID = FriendsOfFriends.FriendOfFriend
			GROUP BY MyFriends.FriendID
		) AS F
	WHERE F.[Order] >= ISNULL(@LowerBoundary, 0)
	ORDER BY F.[Order] ASC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetFriendsCount]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetFriendsCount]
GO

CREATE PROCEDURE [dbo].[USR_GetFriendsCount]
	@ApplicationID	uniqueidentifier,
    @UserID			uniqueidentifier,
    @AreFriends		bit,
    @Sent			bit,
    @Received		bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT COUNT(FriendID)
	FROM [dbo].[USR_View_Friends]
	WHERE ApplicationID = @ApplicationID AND 
		UserID = @UserID AND (@AreFriends IS NULL OR AreFriends = @AreFriends) AND
		((@Sent = 1 AND IsSender = 1) OR (@Received = 1 AND IsSender = 0))
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_P_SaveEmailContacts]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_P_SaveEmailContacts]
GO

CREATE PROCEDURE [dbo].[USR_P_SaveEmailContacts]	
	@ApplicationID	uniqueidentifier,
    @UserID			uniqueidentifier,
    @EmailsTemp		StringTableType readonly,
    @Now			datetime,
    @_Result		int output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Emails StringTableType
	INSERT INTO @Emails SELECT * FROM @EmailsTemp
	
	UPDATE C
		SET Deleted = 0
	FROM @Emails AS E
		INNER JOIN [dbo].[USR_EmailContacts] AS C
		ON C.Email = LOWER(E.Value)
	WHERE C.UserID = @UserID
	
	SET @_Result = @@ROWCOUNT
	
	INSERT INTO [dbo].[USR_EmailContacts](
		UserID,
		Email, 
		CreationDate, 
		Deleted, 
		UniqueID
	)
	SELECT Ref.UserID, Ref.Email, Ref.[Now], Ref.Deleted, NEWID()
	FROM (
			SELECT DISTINCT @UserID AS UserID, LOWER(E.Value) AS Email, 
				@Now AS [Now], 0 AS Deleted
			FROM @Emails AS E
				LEFT JOIN [dbo].[USR_EmailContacts] AS C
				ON C.UserID = @UserID AND C.Email = LOWER(E.Value)
			WHERE C.UserID IS NULL
		) AS Ref
	
	SET @_Result = @_Result + @@ROWCOUNT
	
	IF @_Result <= 0 AND (SELECT TOP (1) * FROM @Emails) IS NULL SET @_Result = 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetEmailContactsStatus]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetEmailContactsStatus]
GO

CREATE PROCEDURE [dbo].[USR_GetEmailContactsStatus]
	@ApplicationID	uniqueidentifier,
    @UserID			uniqueidentifier,
    @EmailsTemp		StringTableType readonly,
    @SaveEmails		bit,
    @Now			datetime
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Emails StringTableType
	INSERT INTO @Emails SELECT * FROM @EmailsTemp
	
	IF @SaveEmails = 1 BEGIN
		DECLARE @_Result int = 0
	
		EXEC [dbo].[USR_P_SaveEmailContacts] @ApplicationID, 
			@UserID, @Emails, @Now, @_Result output
	END
	
	SELECT	Emails.Email,
			Emails.UserID,
			CAST((CASE WHEN Fr.IsSender IS NULL THEN 0 ELSE 1 END) AS bit) AS FriendRequestReceived
	FROM (
			SELECT DISTINCT
					EA.UserID,
					LOWER(E.Value) AS Email
			FROM @Emails AS E
				LEFT JOIN [dbo].[USR_EmailAddresses] AS EA
				ON EA.Deleted = 0 AND LOWER(EA.EmailAddress) = LOWER(E.Value)
			WHERE EA.UserID IS NULL OR EA.UserID <> @UserID
		) AS Emails
		LEFT JOIN [dbo].[USR_View_Friends] AS Fr
		ON Fr.ApplicationID = @ApplicationID AND 
			Fr.UserID = @UserID AND Fr.FriendID = Emails.UserID
	WHERE Fr.AreFriends IS NULL OR (Fr.AreFriends = 0 AND Fr.IsSender = 0)
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_SetTheme]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_SetTheme]
GO

CREATE PROCEDURE [dbo].[USR_SetTheme]
	@UserID			uniqueidentifier,
    @Theme			varchar(50)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[USR_Profile]
		SET Theme = @Theme
	WHERE UserID = @UserID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetTheme]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetTheme]
GO

CREATE PROCEDURE [dbo].[USR_GetTheme]
	@UserID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT Theme
	FROM [dbo].[USR_Profile]
	WHERE UserID = @UserID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_SetVerificationCodeMedia]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_SetVerificationCodeMedia]
GO

CREATE PROCEDURE [dbo].[USR_SetVerificationCodeMedia]
	@UserID		uniqueidentifier,
	@Media		varchar(50)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[USR_Profile]
		SET TwoStepAuthentication = @Media
	WHERE UserID = @UserID

	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_SaveUserSettings]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_SaveUserSettings]
GO

CREATE PROCEDURE [dbo].[USR_SaveUserSettings]
	@UserID		uniqueidentifier,
	@Settings	nvarchar(max)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[USR_Profile]
		SET Settings = @Settings
	WHERE UserID = @UserID

	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetApprovedUserIDs]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetApprovedUserIDs]
GO

CREATE PROCEDURE [dbo].[USR_GetApprovedUserIDs]
	@ApplicationID	uniqueidentifier,
    @strUserIDs		varchar(max),
    @delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserIDs GuidTableType
	
	INSERT INTO @UserIDs
	SELECT DISTINCT Ref.Value 
	FROM [dbo].[GFN_StrToGuidTable](@strUserIDs, @delimiter) AS Ref
	
	SELECT UN.UserID AS ID
	FROM @UserIDs AS U
		INNER JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND UN.UserID = U.Value
	WHERE UN.IsApproved = 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_SetLastActivityDate]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_SetLastActivityDate]
GO

CREATE PROCEDURE [dbo].[USR_SetLastActivityDate]
    @UserID			uniqueidentifier,
    @Now			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[aspnet_Users]
		SET LastActivityDate = @Now
	WHERE UserId = @UserID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_AddOrModifyRemoteServer]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_AddOrModifyRemoteServer]
GO

CREATE PROCEDURE [dbo].[USR_AddOrModifyRemoteServer]
	@ApplicationID	uniqueidentifier,
	@ServerID		uniqueidentifier,
	@UserID			uniqueidentifier,
	@Name			nvarchar(255),
	@URL			nvarchar(100),
	@UserName		nvarchar(100),
	@Password		varbinary(100),
	@Now			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) ServerID
		FROM [dbo].[USR_RemoteServers]
		WHERE ApplicationID = @ApplicationID AND ServerID = @ServerID AND UserID = @UserID
	) BEGIN
		UPDATE [dbo].[USR_RemoteServers]
			Set Name = @Name,
				URL = @URL,
				UserName = @UserName,
				[Password] = @Password,
				LastModificationDate = @Now
		WHERE ApplicationID = @ApplicationID AND ServerID = @ServerID AND UserID = @UserID
	END
	ELSE BEGIN
		INSERT INTO [dbo].[USR_RemoteServers] (
			ApplicationID, ServerID, UserID, Name, URL, UserName, [Password], CreationDate
		)
		VALUES (@ApplicationID, @ServerID, @UserID, @Name, @URL, @UserName, @Password, @Now)
	END
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_RemoveRemoteServer]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_RemoveRemoteServer]
GO

CREATE PROCEDURE [dbo].[USR_RemoveRemoteServer]
	@ApplicationID	uniqueidentifier,
	@ServerID		uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DELETE [dbo].[USR_RemoteServers]
	WHERE ApplicationID = @ApplicationID AND ServerID = @ServerID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetRemoteServers]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetRemoteServers]
GO

CREATE PROCEDURE [dbo].[USR_GetRemoteServers]
	@ApplicationID	uniqueidentifier,
	@ServerID		uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT S.ServerID, S.UserID, S.Name, S.URL, S.UserName, S.[Password]
	FROM [dbo].[USR_RemoteServers] AS S
	WHERE S.ApplicationID = @ApplicationID AND 
		(@ServerID IS NULL OR ServerID = @ServerID)
	ORDER BY S.CreationDate DESC
END

GO


-- Profile

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_P_SavePasswordHistoryBulk]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_P_SavePasswordHistoryBulk]
GO

CREATE PROCEDURE [dbo].[USR_P_SavePasswordHistoryBulk]
    @ItemsTemp		GuidStringTableType readonly,
    @AutoGenerated	bit,
    @Now			datetime,
    @_Result		int output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Items GuidStringTableType
	INSERT INTO @Items SELECT * FROM @ItemsTemp
	
	INSERT INTO [dbo].[USR_PasswordsHistory](
		UserID,
		[Password],
		[SetDate],
		AutoGenerated
	)
	SELECT	I.FirstValue,
			I.SecondValue,
			@Now,
			ISNULL(@AutoGenerated, 0)
	FROM @Items AS I

	SET @_Result = @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_P_SavePasswordHistory]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_P_SavePasswordHistory]
GO

CREATE PROCEDURE [dbo].[USR_P_SavePasswordHistory]
    @UserID 		uniqueidentifier,
    @Password		nvarchar(255),
    @AutoGenerated	bit,
    @Now			datetime,
    @_Result		int output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	INSERT INTO [dbo].[USR_PasswordsHistory](
		UserID,
		[Password],
		[SetDate],
		AutoGenerated
	)
	VALUES(
		@UserID,
		@Password,
		@Now,
		ISNULL(@AutoGenerated, 0)
	)

	SET @_Result = @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetLastPasswords]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetLastPasswords]
GO

CREATE PROCEDURE [dbo].[USR_GetLastPasswords]
    @UserID 		uniqueidentifier,
    @AutoGenerated	bit,
    @Count			int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(ISNULL(@Count, 1000)) [Password], AutoGenerated
	FROM [dbo].[USR_PasswordsHistory]
	WHERE UserID = @UserID AND (@AutoGenerated IS NULL OR ISNULL(AutoGenerated, 0) = @AutoGenerated)
	ORDER BY ID DESC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetLastPasswordDate]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetLastPasswordDate]
GO

CREATE PROCEDURE [dbo].[USR_GetLastPasswordDate]
    @UserID 		uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(1) SetDate
	FROM [dbo].[USR_PasswordsHistory]
	WHERE UserID = @UserID
	ORDER BY ID DESC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetCurrentPassword]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetCurrentPassword]
GO

CREATE PROCEDURE [dbo].[USR_GetCurrentPassword]
	@UserID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(1) M.[Password], M.PasswordSalt
	FROM [dbo].[aspnet_Membership] AS M
	WHERE M.UserId = @UserID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_P_CreateUsers]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_P_CreateUsers]
GO

CREATE PROCEDURE [dbo].[USR_P_CreateUsers]
	@ApplicationID	uniqueidentifier,
	@UsersTemp		ExchangeUserTableType readonly,
    @Now			datetime,
    @_Result		int output,
    @_ErrorMessage	nvarchar(255) output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Users ExchangeUserTableType
	INSERT INTO @Users SELECT * FROM @UsersTemp
	
	
	IF @ApplicationID IS NOT NULL AND EXISTS(
		SELECT TOP(1) 1 
		FROM @Users AS Ref
			INNER JOIN [dbo].[Users_Normal] AS U
			ON (@ApplicationID IS NULL OR U.ApplicationID = @ApplicationID) AND 
				(
					U.LoweredUserName = LOWER(Ref.UserName) OR
					(U.NationalID IS NOT NULL AND Ref.NationalID IS NOT NULL AND LOWER(U.NationalID) = LOWER(Ref.NationalID)) OR
					(U.PersonnelID IS NOT NULL AND Ref.PersonnelID IS NOT NULL AND LOWER(U.PersonnelID) = LOWER(Ref.PersonnelID))
				)
	) BEGIN
		SET @_Result = -1
		SET @_ErrorMessage = N'UserNameAlreadyExists'
		RETURN
	END
	ELSE IF @ApplicationID IS NULL AND EXISTS(
		SELECT TOP(1) 1 
		FROM @Users AS Ref
			INNER JOIN [dbo].[aspnet_Users] AS U
			ON U.LoweredUserName = LOWER(Ref.UserName)
	) BEGIN
		SET @_Result = -1
		SET @_ErrorMessage = N'UserNameAlreadyExists'
		RETURN
	END
	
	IF EXISTS(
		SELECT TOP(1) 1 
		FROM @Users AS Ref
			INNER JOIN [dbo].[USR_EmailAddresses] AS E
			ON LOWER(EmailAddress) = LOWER(Ref.Email) AND E.Deleted = 0
			INNER JOIN [dbo].[USR_Profile] AS P
			ON P.UserID = E.UserID AND P.MainEmailID = E.EmailID
		WHERE ISNULL(Ref.Email, N'') <> N''
	) BEGIN
		SELECT @_Result = -1, @_ErrorMessage = N'EmailAddressAlreadyExists'
		RETURN
	END
	
	IF EXISTS(
		SELECT TOP(1) 1 
		FROM @Users AS Ref
			INNER JOIN [dbo].[USR_PhoneNumbers] AS E
			ON E.PhoneNumber = LOWER(Ref.PhoneNumber) AND E.Deleted = 0
			INNER JOIN [dbo].[USR_Profile] AS P
			ON P.UserID = E.UserID AND P.MainPhoneID = E.NumberID
		WHERE ISNULL(Ref.PhoneNumber, N'') <> N''
	) BEGIN
		SELECT @_Result = -1, @_ErrorMessage = N'PhoneNumberAlreadyExists'
		RETURN
	END
	
	INSERT INTO [dbo].[aspnet_Users](
		UserId,
		UserName,
		LoweredUserName,
		IsAnonymous,
		LastActivityDate
	)
	SELECT	Ref.UserID, 
			Ref.UserName, 
			LOWER(Ref.UserName), 
			0, 
			N'1754-01-01 00:00:00.000'
	FROM @Users AS Ref
	WHERE Ref.UserID IS NOT NULL AND ISNULL(Ref.UserName, N'') <> N'' AND
		ISNULL(Ref.[Password], N'') <> N'' AND ISNULL(Ref.PasswordSalt, N'') <> N''

	INSERT INTO [dbo].[aspnet_Membership](
		UserId,
		[Password],
		PasswordFormat,
		PasswordSalt,
		IsApproved,
		IsLockedOut,
		CreateDate,
		LastLoginDate,
		LastPasswordChangedDate,
		LastLockoutDate,
		FailedPasswordAttemptCount,
		FailedPasswordAttemptWindowStart,
		FailedPasswordAnswerAttemptCount,
		FailedPasswordAnswerAttemptWindowStart
	)
	SELECT	Ref.UserID,
			Ref.[Password],
			N'1',
			Ref.PasswordSalt,
			1,
			0,
			@Now,
			N'1754-01-01 00:00:00.000',
			N'1754-01-01 00:00:00.000',
			N'1754-01-01 00:00:00.000',
			0,
			N'1754-01-01 00:00:00.000',
			0,
			N'1754-01-01 00:00:00.000'
	FROM @Users AS Ref
	WHERE Ref.UserID IS NOT NULL AND ISNULL(Ref.UserName, N'') <> N'' AND
		ISNULL(Ref.[Password], N'') <> N'' AND ISNULL(Ref.PasswordSalt, N'') <> N''
	
	INSERT INTO [dbo].[USR_Profile](
		UserID, 
		FirstName, 
		LastName,
		NationalID,
		PersonnelID
	)
	SELECT	Ref.UserID,
			Ref.FirstName,
			Ref.LastName,
			CASE 
				WHEN @ApplicationID IS NULL OR LTRIM(RTRIM(ISNULL(Ref.NationalID, N''))) = N'' 
					THEN NULL 
				ELSE LTRIM(RTRIM(Ref.NationalID)) 
			END,
			CASE 
				WHEN @ApplicationID IS NULL OR LTRIM(RTRIM(ISNULL(Ref.PersonnelID, N''))) = N'' 
					THEN NULL 
				ELSE LTRIM(RTRIM(Ref.PersonnelID)) 
			END
	FROM @Users AS Ref
	WHERE Ref.UserID IS NOT NULL AND ISNULL(Ref.UserName, N'') <> N'' AND
		ISNULL(Ref.[Password], N'') <> N'' AND ISNULL(Ref.PasswordSalt, N'') <> N''
	
	IF @ApplicationID IS NOT NULL BEGIN
		INSERT INTO [dbo].[USR_UserApplications](
			ApplicationID,
			UserID
		)
		SELECT	@ApplicationID,
				Ref.UserID
		FROM @Users AS Ref
		WHERE Ref.UserID IS NOT NULL AND ISNULL(Ref.UserName, N'') <> N'' AND
			ISNULL(Ref.[Password], N'') <> N'' AND ISNULL(Ref.PasswordSalt, N'') <> N''
	END
	
	
	-- Update Email Addresses
	DECLARE @Emails TABLE (UserID uniqueidentifier, EmailID uniqueidentifier, Email varchar(100))
	
	INSERT INTO @Emails (UserID, EmailID, Email)
	SELECT Ref.UserID, NEWID(), Ref.Email
	FROM @Users AS Ref
	WHERE Ref.UserID IS NOT NULL AND ISNULL(Ref.UserName, N'') <> N'' AND
		ISNULL(Ref.[Password], N'') <> N'' AND ISNULL(Ref.PasswordSalt, N'') <> N'' AND
		ISNULL(Ref.Email, N'') <> N''
		
	INSERT INTO [dbo].[USR_EmailAddresses](
		EmailID, 
		UserID, 
		EmailAddress,
		CreatorUserID, 
		CreationDate, 
		Validated,
		Deleted
	)
	SELECT	E.EmailID,
			E.UserID,
			LOWER(E.Email),
			E.UserID,
			@Now,
			1,
			0
	FROM @Emails AS E
	
	UPDATE P
		SET MainEmailID = E.EmailID
	FROM @Emails AS E
		INNER JOIN [dbo].[USR_Profile] AS P
		ON P.UserID = E.UserID
	-- end of Update Email Addresses
	
	
	-- Update Phone Numbers
	DECLARE @Numbers TABLE (UserID uniqueidentifier, NumberID uniqueidentifier, PhoneNumber varchar(100))
	
	INSERT INTO @Numbers(UserID, NumberID, PhoneNumber)
	SELECT Ref.UserID, NEWID(), Ref.PhoneNumber
	FROM @Users AS Ref
	WHERE Ref.UserID IS NOT NULL AND ISNULL(Ref.UserName, N'') <> N'' AND
		ISNULL(Ref.[Password], N'') <> N'' AND ISNULL(Ref.PasswordSalt, N'') <> N'' AND
		ISNULL(Ref.PhoneNumber, N'') <> N''
		
	INSERT INTO [dbo].[USR_PhoneNumbers](
		NumberID, 
		UserID, 
		PhoneNumber,
		CreatorUserID, 
		CreationDate, 
		Validated,
		Deleted
	)
	SELECT	E.NumberID,
			E.UserID,
			E.PhoneNumber,
			E.UserID,
			@Now,
			1,
			0
	FROM @Numbers AS E
	
	UPDATE P
		SET MainPhoneID = E.NumberID
	FROM @Numbers AS E
		INNER JOIN [dbo].[USR_Profile] AS P
		ON P.UserID = E.UserID
	-- end of Update Phone Numbers
	
	
	SET @_Result = 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_CreateUser]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_CreateUser]
GO

CREATE PROCEDURE [dbo].[USR_CreateUser]
	@ApplicationID		uniqueidentifier,
    @UserID 			uniqueidentifier,
    @UserName			nvarchar(255),
	@NationalID			nvarchar(20),
	@PersonnelID		nvarchar(20),
    @FirstName			nvarchar(255),
    @LastName			nvarchar(255),
    @Password			nvarchar(255),
    @PasswordSalt		nvarchar(255),
    @EncryptedPassword	nvarchar(255),
    @PassAutoGenerated	bit,
    @Email				varchar(100),
    @PhoneNumber		varchar(50),
    @Now				datetime
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE @_Result int, @_ErrorMessage nvarchar(255)
	
	DECLARE @Users ExchangeUserTableType
	
	INSERT INTO @Users (UserID, UserName, NationalID, PersonnelID, FirstName, LastName, 
		[Password], PasswordSalt, EncryptedPassword, Email, PhoneNumber)
	VALUES (@UserID, @UserName, @NationalID, @PersonnelID, @FirstName, @LastName,
		@Password, @PasswordSalt, @EncryptedPassword, @Email, @PhoneNumber)
	
	EXEC [dbo].[USR_P_CreateUsers] @ApplicationID, @Users, @Now, 
		@_Result output, @_ErrorMessage output
	
	IF @_Result <= 0 BEGIN
		SELECT @_Result, @_ErrorMessage
		ROLLBACK TRANSACTION
		RETURN
	END
	
	EXEC [dbo].[USR_P_SavePasswordHistory] @UserID, @EncryptedPassword, @PassAutoGenerated, @Now, @_Result output
	
	IF @_Result <= 0 BEGIN
		SET @_ErrorMessage = NULL
		SELECT @_Result, @_ErrorMessage
		ROLLBACK TRANSACTION
		RETURN
	END
	
	SELECT @_Result, @_ErrorMessage
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_CreateTemporaryUser]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_CreateTemporaryUser]
GO

CREATE PROCEDURE [dbo].[USR_CreateTemporaryUser]
    @UserID 			uniqueidentifier,
    @UserName			nvarchar(255),
    @FirstName			nvarchar(255),
    @LastName			nvarchar(255),
    @Password			nvarchar(255),
    @PasswordSalt		nvarchar(255),
    @EncryptedPassword	nvarchar(255),
    @PassAutoGenerated	bit,
    @Email				nvarchar(255),
    @PhoneNumber		varchar(50),
    @Now				datetime,
    @ExpirationDate		datetime,
    @ActivationCode		varchar(255),
    @InvitationID		uniqueidentifier
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	SET @UserName = [dbo].[GFN_VerifyString](@UserName)
	SET @FirstName = [dbo].[GFN_VerifyString](@FirstName)
	SET @LastName = [dbo].[GFN_VerifyString](@LastName)
	
	IF EXISTS(
		SELECT TOP(1) 1 
		FROM [dbo].[USR_View_Users] 
		WHERE LoweredUserName = LOWER(@UserName)
	) OR EXISTS(
		SELECT TOP(1) 1 
		FROM [dbo].[USR_TemporaryUsers] 
		WHERE LOWER(UserName) = LOWER(@UserName) AND
			(ExpirationDate IS NOT NULL AND ExpirationDate >= @Now)
	) BEGIN
		SELECT -1, N'UserNameAlreadyExists'
		RETURN
	END
	
	IF EXISTS(
		SELECT TOP(1) 1 
		FROM [dbo].[USR_EmailAddresses]  AS E
		WHERE LOWER(E.EmailAddress) = LOWER(@Email)
	) BEGIN
		SELECT -1, N'EmailAddressAlreadyExists'
		RETURN
	END
	
	IF EXISTS(
		SELECT TOP(1) 1 
		FROM [dbo].[USR_PhoneNumbers]  AS E
		WHERE LOWER(E.PhoneNumber) = LOWER(@PhoneNumber)
	) BEGIN
		SELECT -1, N'PhoneNumberAlreadyExists'
		RETURN
	END
	
	
	INSERT INTO [dbo].[USR_TemporaryUsers](
		UserID,
		UserName,
		FirstName,
		LastName,
		[Password],
		PasswordSalt,
		EMail,
		PhoneNumber,
		CreationDate,
		ExpirationDate,
		ActivationCode
	)
	VALUES(
		@UserID,
		@UserName,
		@FirstName,
		@LastName,
		@Password,
		@PasswordSalt,
		@EMail,
		@PhoneNumber,
		@Now,
		@ExpirationDate,
		@ActivationCode
	)
	
	IF @@ROWCOUNT <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	IF @InvitationID IS NOT NULL BEGIN
		UPDATE [dbo].[USR_Invitations]
			SET CreatedUserID = @UserID
		WHERE ID = @InvitationID
		
		IF @@ROWCOUNT <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	DECLARE @_Result int
	
	EXEC [dbo].[USR_P_SavePasswordHistory] @UserID, @EncryptedPassword, @PassAutoGenerated, @Now, @_Result output
		
	IF @_Result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	SELECT 1
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_ActivateTemporaryUser]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_ActivateTemporaryUser]
GO

CREATE PROCEDURE [dbo].[USR_ActivateTemporaryUser]
    @ActivationCode	VARCHAR(255),
    @Now			DATETIME
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserID uniqueidentifier, @UserName nvarchar(255), @FirstName nvarchar(255),
		@LastName nvarchar(255), @Password nvarchar(255), @PasswordSalt nvarchar(255),
		@EMail nvarchar(255), @PhoneNumber varchar(50), @ApplicationID	uniqueidentifier
		
	IF (
		SELECT TOP(1) 1 
		FROM [dbo].[USR_View_Users]
		WHERE UserID = @UserID
	) IS NOT NULL BEGIN
		SELECT 1
		RETURN
	END
	
	SELECT TOP(1)	
			@UserID = T.UserID, @UserName = T.UserName, @FirstName = T.FirstName, @LastName = T.LastName,
			@EMail = T.EMail, @PhoneNumber = T.PhoneNumber, @Password = T.[Password], @PasswordSalt = T.PasswordSalt,
			@ApplicationID = I.ApplicationID
	FROM [dbo].[USR_TemporaryUsers] AS T
		LEFT JOIN [dbo].[USR_Invitations] AS I
		ON I.CreatedUserID = T.UserID
	WHERE T.ActivationCode = @ActivationCode
	
	DECLARE @_Result int, @_ErrorMessage nvarchar(255)
	
	DECLARE @Users ExchangeUserTableType
	
	INSERT INTO @Users (UserID, UserName, FirstName, LastName, 
		[Password], PasswordSalt, EncryptedPassword, Email, PhoneNumber)
	VALUES (@UserID, @UserName, @FirstName, @LastName,
		@Password, @PasswordSalt, @Password, @Email, @PhoneNumber)
	
	EXEC [dbo].[USR_P_CreateUsers] @ApplicationID, @Users, @Now, 
		@_Result output, @_ErrorMessage output
	
	SELECT @_Result, @_ErrorMessage
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetInvitationID]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetInvitationID]
GO

CREATE PROCEDURE [dbo].[USR_GetInvitationID]
	@ApplicationID	uniqueidentifier,
	@Email			nvarchar(255),
	@CheckIfNotUsed	bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT I.ID
	FROM [dbo].[USR_Invitations] AS I
	WHERE I.ApplicationID = @ApplicationID AND I.Email = LOWER(@Email) AND
		(ISNULL(@CheckIfNotUsed, 0) = 0 OR I.CreatedUserID IS NULL)
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_InviteUser]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_InviteUser]
GO

CREATE PROCEDURE [dbo].[USR_InviteUser]
	@ApplicationID	uniqueidentifier,
	@InvitationID	UNIQUEIDENTIFIER,
	@Email			NVARCHAR(255),
    @CurrentUserID	UNIQUEIDENTIFIER,
    @Now			DATETIME
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @Email = LOWER(@Email)

	INSERT INTO [dbo].[USR_Invitations] (
		ApplicationID,
		ID, 
		Email, 
		SenderUserID, 
		SendDate
	)
	VALUES (@ApplicationID, @InvitationID, LOWER(@Email), @CurrentUserID, @Now)

	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetInvitedUsersCount]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetInvitedUsersCount]
GO

CREATE PROCEDURE [dbo].[USR_GetInvitedUsersCount]
	@ApplicationID	uniqueidentifier,
    @UserID			UNIQUEIDENTIFIER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT COUNT(Email)
	FROM [dbo].[USR_Invitations]
	WHERE ApplicationID = @ApplicationID AND @UserID IS NULL OR SenderUserID = @UserID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetUserInvitations]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetUserInvitations]
GO

CREATE PROCEDURE [dbo].[USR_GetUserInvitations]
	@ApplicationID		uniqueidentifier,
	@SenderUserID		UNIQUEIDENTIFIER,
	@Count				INT,
	@LowerBoundary		BIGINT
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Results TABLE (
		Email nvarchar(255), 
		SendDate datetime, 
		UserID uniqueidentifier,
		UserName nvarchar(200),
		FirstName nvarchar(200),
		LastName nvarchar(200),
		AvatarName nvarchar(50),
		UseAvatar bit,
		Activated bit
	)
	
	
	-- Email Based Results
	INSERT INTO @Results (Email, SendDate, UserID, UserName, FirstName, LastName, AvatarName, UseAvatar, Activated)
	SELECT	LOWER(I.Email), 
			MAX(I.SendDate),
			CAST(MAX(CAST(UN.UserID AS varchar(50))) AS uniqueidentifier),
			MAX(UN.UserName),
			MAX(UN.FirstName),
			MAX(UN.LastName),
			MAX(UN.AvatarName),
			CAST(MAX(CAST(UN.UseAvatar AS int)) AS bit),
			1 AS Activated
	FROM [dbo].[USR_Invitations] AS I
		INNER JOIN [dbo].[Users_Normal] AS UN
		ON I.ApplicationID = UN.ApplicationID
		INNER JOIN [dbo].[USR_EmailAddresses] AS EA
		ON EA.UserID = UN.UserID AND LOWER(EA.EmailAddress) = LOWER(I.Email)
	WHERE I.ApplicationID = @ApplicationID AND I.SenderUserID = @SenderUserID
	GROUP BY LOWER(I.Email)
	-- end of Email Based Results
	
	
	-- Temp User Based Results
	INSERT INTO @Results (Email, SendDate, UserID, UserName, FirstName, LastName, AvatarName, UseAvatar, Activated)
	SELECT X.Email, X.SendDate, X.UserID, X.UserName, X.FirstName, X.LastName, X.AvatarName, X.UseAvatar, X.Activated
	FROM (
			SELECT	LOWER(I.Email) AS Email, 
					MAX(I.SendDate) AS SendDate,
					CAST(MAX(CAST(T.UserID AS varchar(50))) AS uniqueidentifier) AS UserID,
					MAX(T.UserName) AS UserName,
					MAX(T.FirstName) AS FirstName,
					MAX(T.LastName) AS LastName,
					MAX(P.AvatarName) AS AvatarName,
					CAST(MAX(CAST(P.UseAvatar AS int)) AS bit) AS UseAvatar,
					MAX(CASE WHEN P.UserID IS NULL THEN 0 ELSE 1 END) AS Activated
			FROM [dbo].[USR_Invitations] AS I
				INNER JOIN [dbo].[USR_TemporaryUsers] AS T
				ON T.UserID = I.CreatedUserID
				LEFT JOIN [dbo].[USR_Profile] AS P
				ON P.UserID = T.UserID
			WHERE I.ApplicationID = @ApplicationID AND I.SenderUserID = @SenderUserID
			GROUP BY LOWER(I.Email)
		) AS X
		LEFT JOIN @Results AS R
		ON R.Email = X.Email
	WHERE R.Email IS NULL
	-- end of Temp User Based Results
	
	
	-- Not Activated Invites
	INSERT INTO @Results (Email, SendDate, UserID, FirstName, LastName, Activated)
	SELECT X.Email, X.SendDate, NULL, NULL, NULL, 0
	FROM (
			SELECT	LOWER(I.Email) AS Email, 
					MAX(I.SendDate) AS SendDate
			FROM [dbo].[USR_Invitations] AS I
			WHERE I.ApplicationID = @ApplicationID AND I.SenderUserID = @SenderUserID
			GROUP BY LOWER(I.Email)
		) AS X
		LEFT JOIN @Results AS R
		ON R.Email = X.Email
	WHERE R.Email IS NULL
	-- Not Activated Invites
	

	SELECT TOP(ISNULL(@Count, 1000000000)) 
		t.UserID AS ReceiverUserID,
		t.UserName AS ReceiverUserName,
		t.FirstName AS ReceiverFirstName,
		t.LastName AS ReceiverLastName,
		t.AvatarName AS ReceiverAvatarName,
		t.UseAvatar AS ReceiverUseAvatar,
		t.Email,
		t.SendDate,
		CAST(t.Activated AS bit) AS Activated,
		t.RowNum AS [Order],
		(t.RevRowNum + t.RowNum - 1) AS TotalCount
	FROM(
		SELECT 
			R.UserID,
			R.UserName,
			R.FirstName,
			R.LastName,
			R.AvatarName,
			R.UseAvatar,
			R.Email,
			R.SendDate,
			R.Activated,
			ROW_NUMBER() OVER (ORDER BY R.SendDate DESC, R.UserID DESC) AS RowNum,
			ROW_NUMBER() OVER (ORDER BY R.SendDate ASC, R.UserID ASC) AS RevRowNum
		FROM @Results AS R
	) AS t
	WHERE t.RowNum >= ISNULL(@LowerBoundary,0)
	ORDER BY t.RowNum ASC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetCurrentInvitations]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetCurrentInvitations]
GO

CREATE PROCEDURE [dbo].[USR_GetCurrentInvitations]
	@UserID			uniqueidentifier,
	@Email			nvarchar(255)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT AppIDs.ApplicationID AS ID
	FROM (
			SELECT DISTINCT I.ApplicationID
			FROM [dbo].[USR_Invitations] AS I
			WHERE LOWER(I.Email) = LOWER(@Email)
		) AS AppIDs
		LEFT JOIN [dbo].[USR_UserApplications] AS A
		ON A.ApplicationID = AppIDs.ApplicationID AND A.UserID = @UserID
	WHERE A.UserID IS NULL
	

END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetInvitationApplicationID]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetInvitationApplicationID]
GO

CREATE PROCEDURE [dbo].[USR_GetInvitationApplicationID]
	@InvitationID		uniqueidentifier,
	@CheckIfNotUsed		bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT I.ApplicationID AS ID
	FROM [dbo].[USR_Invitations] AS I
	WHERE I.ID = @InvitationID AND (ISNULL(@CheckIfNotUsed, 0) = 0 OR I.CreatedUserID IS NULL)
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_SetPassResetTicket]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_SetPassResetTicket]
GO

CREATE PROCEDURE [dbo].[USR_SetPassResetTicket]
	@UserID			UNIQUEIDENTIFIER,
    @Ticket			UNIQUEIDENTIFIER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM [dbo].[USR_PassResetTickets] 
		WHERE UserID = @UserID
	) BEGIN
		UPDATE [dbo].[USR_PassResetTickets]
			SET Ticket = @Ticket
		WHERE UserID = @UserID
	END
	ELSE BEGIN
		INSERT INTO [dbo].[USR_PassResetTickets](
			UserID,
			Ticket
		)
		VALUES(
			@UserID,
			@Ticket
		)
	END
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetPassResetTicket]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetPassResetTicket]
GO

CREATE PROCEDURE [dbo].[USR_GetPassResetTicket]
	@UserID			UNIQUEIDENTIFIER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT Ticket AS ID
	FROM [dbo].[USR_PassResetTickets]
	WHERE UserID = @UserID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_P_SetFirstAndLastName]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_P_SetFirstAndLastName]
GO

CREATE PROCEDURE [dbo].[USR_P_SetFirstAndLastName]
    @UserID 		uniqueidentifier,
    @FirstName		nvarchar(255),
    @LastName		nvarchar(255),
    @_Result		int output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @FirstName = [dbo].[GFN_VerifyString](@FirstName)
	SET @LastName = [dbo].[GFN_VerifyString](@LastName)

	IF EXISTS(SELECT TOP(1) * FROM [dbo].[USR_Profile] WHERE UserID = @UserID) BEGIN
		UPDATE [dbo].[USR_Profile]
			SET FirstName = @FirstName,
				LastName = @LastName
		WHERE UserId = @UserID
	END
	ELSE BEGIN
		INSERT INTO [dbo].[USR_Profile](
			UserID,
			FirstName,
			LastName
		)
		VALUES(
			@UserID,
			@FirstName,
			@LastName
		)
	END
	
	SET @_Result = @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_SetFirstAndLastName]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_SetFirstAndLastName]
GO

CREATE PROCEDURE [dbo].[USR_SetFirstAndLastName]
    @UserID 		uniqueidentifier,
    @FirstName		nvarchar(255),
    @LastName		nvarchar(255)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @_Result int
	
	EXEC [dbo].[USR_P_SetFirstAndLastName] @UserID, @FirstName, @LastName, @_Result output

	SELECT @_Result
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_SetUserName]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_SetUserName]
GO

CREATE PROCEDURE [dbo].[USR_SetUserName]
	@ApplicationID	uniqueidentifier,
    @UserID 		uniqueidentifier,
    @UserName		nvarchar(255)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Exists bit = 0;

	IF @ApplicationID IS NULL BEGIN 
		SET @Exists = (
			SELECT TOP(1) CAST(1 AS bit) 
			FROM [dbo].[USR_View_Users]
			WHERE LoweredUserName = LOWER(@UserName) AND UserId <> @UserID
		)
	END
	ELSE BEGIN
		SET @Exists = (
			SELECT TOP(1) CAST(1 AS bit) 
			FROM [dbo].[Users_Normal]
			WHERE ApplicationID = @ApplicationID AND 
				LoweredUserName = LOWER(@UserName) AND UserId <> @UserID
		)
	END

	IF @UserName IS NOT NULL AND @UserName <> N'' AND ISNULL(@Exists, 0) = 0 BEGIN
		UPDATE [dbo].[aspnet_Users]
			SET UserName = @UserName,
				LoweredUserName = LOWER(@UserName)
		WHERE UserId = @UserID
		
		SELECT @@ROWCOUNT
	END
	ELSE BEGIN
		SELECT -1
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_SetNationalID]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_SetNationalID]
GO

CREATE PROCEDURE [dbo].[USR_SetNationalID]
	@ApplicationID	uniqueidentifier,
    @UserID 		uniqueidentifier,
    @NationalID		nvarchar(20)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	IF @NationalID IS NOT NULL SET @NationalID = LTRIM(RTRIM(@NationalID))
	
	DECLARE @Exists bit = (
		SELECT TOP(1) CAST(1 AS bit) 
		FROM [dbo].[Users_Normal] AS UN
		WHERE UN.ApplicationID = @ApplicationID AND 
			UN.NationalID IS NOT NULL AND ISNULL(@NationalID, N'') <> N'' AND
			LOWER(UN.NationalID) = LOWER(@NationalID) AND UserId <> @UserID
	)

	UPDATE [dbo].[USR_Profile]
	SET NationalID = CASE WHEN ISNULL(@NationalID, N'') = N'' THEN NULL ELSE @NationalID END
	WHERE @ApplicationID IS NOT NULL AND ISNULL(@Exists, 0) = 0 AND UserId = @UserID
		
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_SetPersonnelID]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_SetPersonnelID]
GO

CREATE PROCEDURE [dbo].[USR_SetPersonnelID]
	@ApplicationID	uniqueidentifier,
    @UserID 		uniqueidentifier,
    @PersonnelID	nvarchar(20)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	IF @PersonnelID IS NOT NULL SET @PersonnelID = LTRIM(RTRIM(@PersonnelID))
	
	DECLARE @Exists bit = (
		SELECT TOP(1) CAST(1 AS bit) 
		FROM [dbo].[Users_Normal] AS UN
		WHERE UN.ApplicationID = @ApplicationID AND 
			UN.NationalID IS NOT NULL AND ISNULL(@PersonnelID, N'') <> N'' AND
			LOWER(UN.NationalID) = LOWER(@PersonnelID) AND UserId <> @UserID
	)

	UPDATE [dbo].[USR_Profile]
	SET NationalID = CASE WHEN ISNULL(@PersonnelID, N'') = N'' THEN NULL ELSE @PersonnelID END
	WHERE @ApplicationID IS NOT NULL AND ISNULL(@Exists, 0) = 0 AND UserId = @UserID
		
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_SetPassword]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_SetPassword]
GO

CREATE PROCEDURE [dbo].[USR_SetPassword]
    @UserID 			uniqueidentifier,
    @Password			nvarchar(255),
    @PasswordSalt		nvarchar(255),
    @EncryptedPassword	nvarchar(255),
    @AutoGenerated		bit,
    @Now				datetime
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	UPDATE [dbo].[aspnet_Membership]
		SET [Password] = @Password,
			PasswordSalt = @PasswordSalt,
			IsLockedOut = 0
	WHERE UserId = @UserID
	
	IF @@ROWCOUNT <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	DECLARE @_Result int
	
	EXEC [dbo].[USR_P_SavePasswordHistory] @UserID, @EncryptedPassword, @AutoGenerated, @Now, @_Result output
	
	IF @_Result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	SELECT 1
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_Locked]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_Locked]
GO

CREATE PROCEDURE [dbo].[USR_Locked]
    @UserID 		uniqueidentifier,
    @Locked			bit,
    @Now			datetime	
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF @Locked IS NULL BEGIN
		SELECT TOP(1) M.UserId AS UserID, M.IsLockedOut, M.LastLockoutDate, M.IsApproved
		FROM [dbo].[aspnet_Membership] AS M
		WHERE M.UserID = @UserID
	END
	ELSE BEGIN
		UPDATE M
			SET IsLockedOut = @Locked,
				LastLockoutDate = CASE WHEN @Locked = 1 THEN @Now ELSE LastLockoutDate END,
				FailedPasswordAttemptCount = 
					(CASE WHEN M.IsLockedOut = @Locked THEN FailedPasswordAttemptCount ELSE 0 END)
		FROM [dbo].[aspnet_Membership] AS M
		WHERE M.UserID = @UserID
		
		SELECT @@ROWCOUNT
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_LoginAttempt]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_LoginAttempt]
GO

CREATE PROCEDURE [dbo].[USR_LoginAttempt]
    @UserID 		uniqueidentifier,
    @Succeed		bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE M
		SET FailedPasswordAttemptCount = 
				(CASE WHEN ISNULL(@Succeed, 0) = 0 THEN ISNULL(FailedPasswordAttemptCount, 0) + 1 ELSE 0 END)
	FROM [dbo].[aspnet_Membership] AS M
	WHERE M.UserID = @UserID
		
		
	SELECT TOP(1) 
		(CASE WHEN M.FailedPasswordAttemptCount <= 0 THEN 1 ELSE M.FailedPasswordAttemptCount END) AS Value
	FROM [dbo].[aspnet_Membership] AS M
	WHERE M.UserID = @UserID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_IsApproved]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_IsApproved]
GO

CREATE PROCEDURE [dbo].[USR_IsApproved]
	@ApplicationID	uniqueidentifier,
    @UserID 		uniqueidentifier,
    @IsApproved		bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF @IsApproved IS NULL BEGIN
		SELECT TOP(1) IsApproved
		FROM [dbo].[aspnet_Membership] AS M
		WHERE UserId = @UserID
	END
	ELSE BEGIN
		UPDATE [dbo].[aspnet_Membership]
			SET IsApproved = @IsApproved
		WHERE UserId = @UserID
		
		SELECT @@ROWCOUNT
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_SetAvatar]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_SetAvatar]
GO

CREATE PROCEDURE [dbo].[USR_SetAvatar]
	@ApplicationID	uniqueidentifier,
    @UserID 		uniqueidentifier,
    @AvatarName		varchar(50)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[USR_Profile]
	SET AvatarName = CASE WHEN ISNULL(@AvatarName, '') = '' THEN AvatarName ELSE @AvatarName END,
		UseAvatar = CASE WHEN ISNULL(@AvatarName, '') = '' THEN 0 ELSE 1 END
	WHERE UserId = @UserID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_SetBirthday]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_SetBirthday]
GO

CREATE PROCEDURE [dbo].[USR_SetBirthday]
	@ApplicationID	uniqueidentifier,
    @UserID 		uniqueidentifier,
    @Birthday		datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[USR_Profile]
		SET BirthDay = @Birthday
	WHERE UserId = @UserID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_SetAboutMe]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_SetAboutMe]
GO

CREATE PROCEDURE [dbo].[USR_SetAboutMe]
    @UserID uniqueidentifier,
    @Text	nvarchar(2000)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @Text = [dbo].[GFN_VerifyString](@Text)
	
	UPDATE [dbo].[USR_Profile]
		SET AboutMe = @Text
	WHERE  UserID = @UserID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_SetCity]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_SetCity]
GO

CREATE PROCEDURE [dbo].[USR_SetCity]
    @UserID uniqueidentifier,
    @City	nvarchar(255)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @City = [dbo].[GFN_VerifyString](@City)
	
	UPDATE [dbo].[USR_Profile]
		SET City = @City
	WHERE  UserID = @UserID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_SetOrganization]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_SetOrganization]
GO

CREATE PROCEDURE [dbo].[USR_SetOrganization]
	@ApplicationID	uniqueidentifier,
    @UserID 		uniqueidentifier,
    @Organization	nvarchar(255)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @Organization = [dbo].[GFN_VerifyString](@Organization)
	
	UPDATE [dbo].[USR_UserApplications]
		SET Organization = @Organization
	WHERE  ApplicationID = @ApplicationID AND UserID = @UserID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_SetDepartment]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_SetDepartment]
GO

CREATE PROCEDURE [dbo].[USR_SetDepartment]
	@ApplicationID	uniqueidentifier,
    @UserID 		uniqueidentifier,
    @Department		nvarchar(255)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @Department = [dbo].[GFN_VerifyString](@Department)
	
	UPDATE [dbo].[USR_UserApplications]
		SET Department = @Department
	WHERE  ApplicationID = @ApplicationID AND UserID = @UserID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_SetJobTitle]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_SetJobTitle]
GO

CREATE PROCEDURE [dbo].[USR_SetJobTitle]
	@ApplicationID	uniqueidentifier,
    @UserID 		uniqueidentifier,
    @JobTitle		nvarchar(255)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @JobTitle = [dbo].[GFN_VerifyString](@JobTitle)
	
	UPDATE [dbo].[USR_UserApplications]
		SET JobTitle = @JobTitle
	WHERE  ApplicationID = @ApplicationID AND UserID = @UserID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_SetEmploymentType]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_SetEmploymentType]
GO

CREATE PROCEDURE [dbo].[USR_SetEmploymentType]
	@ApplicationID	uniqueidentifier,
    @UserID 		uniqueidentifier,
    @EmploymentType	varchar(50)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[USR_UserApplications]
		SET EmploymentType = @EmploymentType
	WHERE ApplicationID = @ApplicationID AND UserID = @UserID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_SetPhoneNumber]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_SetPhoneNumber]
GO

CREATE PROCEDURE [dbo].[USR_SetPhoneNumber]
	@NumberID			uniqueidentifier,
    @UserID 			uniqueidentifier,
    @PhoneNumber		varchar(50),
    @PhoneNumberType	varchar(20),
    @CreatorUserID		uniqueidentifier,
    @CreationDate		datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	INSERT INTO USR_PhoneNumbers(
		NumberID,
		PhoneNumber,
		UserID,
		CreatorUserID,
		CreationDate,
		PhoneType, 
		Deleted
	)
	VALUES (
		@NumberID,
		@PhoneNumber,
		@UserID,
		@CreatorUserID,
		@CreationDate,
		@PhoneNumberType,
		0
	)
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetPhoneNumbers]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetPhoneNumbers]
GO

CREATE PROCEDURE [dbo].[USR_GetPhoneNumbers]
	@UserID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT	UserID,
			NumberID, 
			PhoneNumber, 
			PhoneType
	FROM [dbo].[USR_PhoneNumbers]
	WHERE UserID = @UserID AND Deleted = 0
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetPhoneNumber]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetPhoneNumber]
GO

CREATE PROCEDURE [dbo].[USR_GetPhoneNumber]
	@NumberID		uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT	UserID,
			NumberID, 
			PhoneNumber, 
			PhoneType
	FROM [dbo].[USR_PhoneNumbers]
	WHERE NumberID = @NumberID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_EditPhoneNumber]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_EditPhoneNumber]
GO

CREATE PROCEDURE [dbo].[USR_EditPhoneNumber]
	@NumberID				UNIQUEIDENTIFIER,
	@PhoneNumber			VARCHAR(50),
	@PhoneType				VARCHAR(20),
	@LastModifierUserID		UNIQUEIDENTIFIER,
	@LastModificationDate	DATETIME
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[USR_PhoneNumbers]
		SET PhoneNumber = @PhoneNumber,
			PhoneType = @PhoneType,
			LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate
	WHERE NumberID = @NumberID AND Deleted = 0
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_RemovePhoneNumber]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_RemovePhoneNumber]
GO

CREATE PROCEDURE [dbo].[USR_RemovePhoneNumber]
	@NumberID				UNIQUEIDENTIFIER,
	@LastModifierUserID		UNIQUEIDENTIFIER,
	@LastModificationDate	DATETIME
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[USR_Profile]
		SET MainPhoneID = null
	WHERE MainPhoneID = @NumberID
	
	UPDATE [dbo].[USR_PhoneNumbers]
		SET Deleted = 1,
			LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate
	WHERE NumberID = @NumberID AND Deleted = 0
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_SetMainPhone]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_SetMainPhone]
GO

CREATE PROCEDURE [dbo].[USR_SetMainPhone]
	@NumberID		UNIQUEIDENTIFIER,
	@UserID			UNIQUEIDENTIFIER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[USR_Profile]
		SET MainPhoneID = @NumberID
	WHERE UserID = @UserID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetMainPhone]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetMainPhone]
GO

CREATE PROCEDURE [dbo].[USR_GetMainPhone]
	@UserID			UNIQUEIDENTIFIER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT MainPhoneID AS ID
	FROM [dbo].[USR_Profile]
	WHERE UserID = @UserID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_SetEmailAddress]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_SetEmailAddress]
GO

CREATE PROCEDURE [dbo].[USR_SetEmailAddress]
	@EmailID		uniqueidentifier,
    @UserID 		uniqueidentifier,
    @EmailAddress	varchar(100),
	@IsMainEmail	bit,
	@CreatorUserID	uniqueidentifier,
	@CreationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	INSERT INTO USR_EmailAddresses(
		EmailID,
		EmailAddress,
		UserID,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	VALUES (
		@EmailID,
		@EmailAddress,
		@UserID,
		@CreatorUserID,
		@CreationDate,
		0
	)
	
	DECLARE @Result int = @@ROWCOUNT
	
	IF @IsMainEmail = 1 BEGIN
		UPDATE [dbo].[USR_Profile]
			SET MainEmailID = @EmailID
		WHERE UserID = @UserID
	END

	SELECT @Result
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetEmailAddresses]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetEmailAddresses]
GO

CREATE PROCEDURE [dbo].[USR_GetEmailAddresses]
	@UserID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT	UserID,
			EmailID, 
			EmailAddress
	FROM [dbo].[USR_EmailAddresses]
	WHERE UserID = @UserID AND Deleted = 0
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetEmailAddress]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetEmailAddress]
GO

CREATE PROCEDURE [dbo].[USR_GetEmailAddress]
	@EmailID		UNIQUEIDENTIFIER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT	UserID,
			EmailID, 
			EmailAddress
	FROM [dbo].[USR_EmailAddresses]
	WHERE EmailID = @EmailID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetEmailOwners]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetEmailOwners]
GO

CREATE PROCEDURE [dbo].[USR_GetEmailOwners]
	@strEmails		varchar(max),
    @delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Emails StringTableType
	
	INSERT INTO @Emails
	SELECT Ref.Value 
	FROM [dbo].[GFN_StrToStringTable](@strEmails, @delimiter) AS Ref

	SELECT	EA.UserID, 
			EA.EmailID, 
			EA.EmailAddress,
			CAST(CASE WHEN USR.UserID IS NULL THEN 0 ELSE 1 END AS bit) AS IsMain
	FROM @Emails AS E
		INNER JOIN [dbo].[USR_EmailAddresses] AS EA
		ON E.Value = EA.EmailAddress
		LEFT JOIN [dbo].[USR_Profile] AS USR
		ON USR.UserID = EA.UserID AND USR.MainEmailID = EA.EmailID
	WHERE EA.Deleted = 0
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetPhoneOwners]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetPhoneOwners]
GO

CREATE PROCEDURE [dbo].[USR_GetPhoneOwners]
	@strNumbers		varchar(max),
    @delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Numbers StringTableType
	
	INSERT INTO @Numbers
	SELECT Ref.Value 
	FROM [dbo].[GFN_StrToStringTable](@strNumbers, @delimiter) AS Ref

	SELECT	PN.UserID, 
			PN.NumberID, 
			PN.PhoneNumber,
			CAST(CASE WHEN USR.UserID IS NULL THEN 0 ELSE 1 END AS bit) AS IsMain
	FROM @Numbers AS N
		INNER JOIN [dbo].[USR_PhoneNumbers] AS PN
		ON N.Value = PN.PhoneNumber
		LEFT JOIN [dbo].[USR_Profile] AS USR
		ON USR.UserID = PN.UserID AND USR.MainPhoneID = PN.NumberID
	WHERE PN.Deleted = 0
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetNotExistingEmails]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetNotExistingEmails]
GO

CREATE PROCEDURE [dbo].[USR_GetNotExistingEmails]
	@ApplicationID	uniqueidentifier,
    @EmailsTemp		StringTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Emails StringTableType
	INSERT INTO @Emails SELECT * FROM @EmailsTemp
	
	IF @ApplicationID IS NULL BEGIN
		SELECT E.Value
		FROM @Emails AS E
			LEFT JOIN [dbo].[USR_EmailAddresses] AS A
			INNER JOIN [dbo].[USR_View_Users] AS UN
			ON UN.UserID = A.UserID
			ON LOWER(E.[Value]) = LOWER(A.EmailAddress) AND A.Deleted = 0
		WHERE A.EmailID IS NULL
	END
	ELSE BEGIN
		SELECT E.Value
		FROM @Emails AS E
			LEFT JOIN [dbo].[USR_EmailAddresses] AS A
			INNER JOIN [dbo].[Users_Normal] AS UN
			ON UN.ApplicationID = @ApplicationID AND UN.UserID = A.UserID
			ON LOWER(E.[Value]) = LOWER(A.EmailAddress) AND A.Deleted = 0
		WHERE A.EmailID IS NULL
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_EditEmailAddress]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_EditEmailAddress]
GO

CREATE PROCEDURE [dbo].[USR_EditEmailAddress]
	@EmailID				UNIQUEIDENTIFIER,
	@Address				VARCHAR(100),
	@LastModifierUserID		UNIQUEIDENTIFIER,
	@LastModificationDate	DATETIME
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE USR_EmailAddresses
		SET EmailAddress = @Address,
			LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate
	WHERE EmailID = @EmailID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_RemoveEmailAddress]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_RemoveEmailAddress]
GO

CREATE PROCEDURE [dbo].[USR_RemoveEmailAddress]
	@EmailID				UNIQUEIDENTIFIER,
	@LastModifierUserID		UNIQUEIDENTIFIER,
	@LastModificationDate	DATETIME
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[USR_Profile]
		SET MainEmailID = null
	WHERE MainEmailID = @EmailID
	
	UPDATE [dbo].[USR_EmailAddresses]
		SET Deleted = 1,
			LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate
	WHERE EmailID = @EmailID AND Deleted = 0
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_SetMainEmail]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_SetMainEmail]
GO

CREATE PROCEDURE [dbo].[USR_SetMainEmail]
	@EmailID		UNIQUEIDENTIFIER,
	@UserID			UNIQUEIDENTIFIER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[USR_Profile]
		SET MainEmailID = @EmailID
	WHERE UserID = @UserID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetMainEmail]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetMainEmail]
GO

CREATE PROCEDURE [dbo].[USR_GetMainEmail]
	@UserID			UNIQUEIDENTIFIER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT MainEmailID AS ID
	FROM [dbo].[USR_Profile]
	WHERE UserID = @UserID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetUsersMainEmail]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetUsersMainEmail]
GO

CREATE PROCEDURE [dbo].[USR_GetUsersMainEmail]
    @strUserIDs		varchar(max),
    @delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserIDs GuidTableType
	INSERT INTO @UserIDs
	SELECT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strUserIDs, @delimiter) AS Ref
	
	SELECT EA.EmailID, UN.UserID, EA.EmailAddress
	FROM @UserIDs AS UIDs
		INNER JOIN [dbo].[USR_Profile] AS UN
		ON un.UserID = UIDs.Value
		INNER JOIN [dbo].[USR_EmailAddresses] AS EA
		ON EA.EmailID = UN.MainEmailID
	WHERE EA.Deleted = 0 
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetUsersMainPhone]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetUsersMainPhone]
GO

CREATE PROCEDURE [dbo].[USR_GetUsersMainPhone]
    @strUserIDs		varchar(max),
    @delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserIDs GuidTableType
	INSERT INTO @UserIDs
	SELECT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strUserIDs, @delimiter) AS Ref
	
	SELECT PN.NumberID, UN.UserID, PN.PhoneNumber, PN.PhoneType
	FROM @UserIDs AS UIDs
		INNER JOIN [dbo].[USR_Profile] AS UN
		ON UN.UserID = UIDs.Value
		INNER JOIN [dbo].[USR_PhoneNumbers] AS PN
		ON PN.NumberID = UN.MainPhoneID
	WHERE PN.Deleted = 0
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetJobExperiences]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetJobExperiences]
GO

CREATE PROCEDURE [dbo].[USR_GetJobExperiences]
	@ApplicationID uniqueidentifier,
    @userId			UNIQUEIDENTIFIER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT 
		je.JobID, 
		je.UserID,
		je.Title, 
		je.Employer,
		je.StartDate,
		je.EndDate
	FROM [dbo].[USR_JobExperiences] AS je
	WHERE je.ApplicationID = @ApplicationID AND je.UserID = @userId AND Deleted = 0
	ORDER BY je.StartDate DESC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetJobExperience]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetJobExperience]
GO

CREATE PROCEDURE [dbo].[USR_GetJobExperience]
	@ApplicationID	uniqueidentifier,
    @JobID			UNIQUEIDENTIFIER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT 
		je.JobID, 
		je.UserID,
		je.Title, 
		je.Employer,
		je.StartDate,
		je.EndDate
	FROM [dbo].[USR_JobExperiences] AS je
	WHERE je.ApplicationID = @ApplicationID AND je.JobID = @JobID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetEducationalExperiences]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetEducationalExperiences]
GO

CREATE PROCEDURE [dbo].[USR_GetEducationalExperiences]
	@ApplicationID	uniqueidentifier,
    @userId			UNIQUEIDENTIFIER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT 
		ee.[EducationID],
		ee.[UserID],
		ee.[School],
		ee.[StudyField],
		ee.[Level],
		ee.[StartDate],
		ee.[EndDate],
		ee.[GraduateDegree],
		ee.IsSchool
	FROM [dbo].[USR_EducationalExperiences] AS ee
	WHERE ee.ApplicationID = @ApplicationID AND ee.UserID = @userId AND Deleted = 0
	ORDER BY ee.StartDate DESC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetEducationalExperience]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetEducationalExperience]
GO

CREATE PROCEDURE [dbo].[USR_GetEducationalExperience]
	@ApplicationID		uniqueidentifier,
    @EducationID		UNIQUEIDENTIFIER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT 
		ee.[EducationID],
		ee.[UserID],
		ee.[School],
		ee.[StudyField],
		ee.[Level],
		ee.[StartDate],
		ee.[EndDate],
		ee.[GraduateDegree],
		ee.IsSchool
	FROM [dbo].[USR_EducationalExperiences] AS ee
	WHERE ee.ApplicationID = @ApplicationID AND ee.EducationID = @EducationID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetHonorsAndAwards]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetHonorsAndAwards]
GO

CREATE PROCEDURE [dbo].[USR_GetHonorsAndAwards]
	@ApplicationID	uniqueidentifier,
    @userId			UNIQUEIDENTIFIER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT 
		hnr.ID,
		hnr.UserID,
		hnr.Title,
		hnr.Issuer,
		hnr.Occupation,
		hnr.IssueDate,
		hnr.[Description]
	FROM [dbo].[USR_HonorsAndAwards] AS hnr
	WHERE hnr.ApplicationID = @ApplicationID AND hnr.UserID = @userId AND Deleted = 0
	ORDER BY hnr.IssueDate DESC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetHonorOrAward]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetHonorOrAward]
GO

CREATE PROCEDURE [dbo].[USR_GetHonorOrAward]
	@ApplicationID	uniqueidentifier,
    @ID				uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT 
		hnr.ID,
		hnr.UserID,
		hnr.Title,
		hnr.Issuer,
		hnr.Occupation,
		hnr.IssueDate,
		hnr.[Description]
	FROM [dbo].[USR_HonorsAndAwards] AS hnr
	WHERE hnr.ApplicationID = @ApplicationID AND hnr.ID = @ID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetUserLanguages]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetUserLanguages]
GO

CREATE PROCEDURE [dbo].[USR_GetUserLanguages]
	@ApplicationID	uniqueidentifier,
    @userId			UNIQUEIDENTIFIER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT 
		UL.ID,
		UL.UserID,
		LN.LanguageName,
		UL.[Level]
	FROM [dbo].[USR_UserLanguages] AS UL
		INNER JOIN [dbo].[USR_LanguageNames] AS LN
		ON LN.ApplicationID = @ApplicationID AND LN.LanguageID = UL.LanguageID
	WHERE UL.ApplicationID = @ApplicationID AND UL.UserID = @userId AND Deleted = 0
	ORDER BY LN.LanguageName DESC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetUserLanguage]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetUserLanguage]
GO

CREATE PROCEDURE [dbo].[USR_GetUserLanguage]
	@ApplicationID	uniqueidentifier,
    @ID				UNIQUEIDENTIFIER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT 
		UL.ID,
		UL.UserID,
		LN.LanguageName,
		UL.[Level]
	FROM [dbo].[USR_UserLanguages] AS UL
		INNER JOIN [dbo].[USR_LanguageNames] AS LN
		ON LN.ApplicationID = @ApplicationID AND LN.LanguageID = UL.LanguageID
	WHERE UL.ApplicationID = @ApplicationID AND UL.ID = @ID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_GetLanguages]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_GetLanguages]
GO

CREATE PROCEDURE [dbo].[USR_GetLanguages]
	@ApplicationID		uniqueidentifier,
	@strLanguageIDs		NVARCHAR(MAX),
	@delimiter			CHAR
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @getAll AS BIT
	
	IF(@strLanguageIDs IS NULL) SET @getAll = 1
	ELSE SET @getAll = 0
	
	DECLARE @LanguageIDs GuidTableType
	
	IF(@getAll = 0)
	BEGIN
		INSERT INTO @LanguageIDs
		SELECT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strLanguageIDs, ISNULL(@delimiter,',')) AS Ref
	END
	
	SELECT LN.LanguageID,
		LN.LanguageName
	FROM [dbo].[USR_LanguageNames] AS LN
		LEFT JOIN @LanguageIDs AS L
		ON LN.LanguageID = L.Value
	WHERE LN.ApplicationID = @ApplicationID AND (@getAll = 1 OR L.Value = LN.LanguageID)
	ORDER BY LN.LanguageName
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_SetJobExperience]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_SetJobExperience]
GO

CREATE PROCEDURE [dbo].[USR_SetJobExperience]
	@ApplicationID	uniqueidentifier,
	@jobId			UNIQUEIDENTIFIER,
    @userId			UNIQUEIDENTIFIER,
    @creatorUserId	UNIQUEIDENTIFIER,
	@creationDate	DATETIME,
    @title			NVARCHAR(256),
    @employer		NVARCHAR(256),
    @startDate		DATETIME,
    @endDate		DATETIME
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM [dbo].[USR_JobExperiences] 
		WHERE ApplicationID = @ApplicationID AND JobID = @jobId
	) BEGIN
		UPDATE [dbo].[USR_JobExperiences]
			SET UserID = @userId,
				Title = @title,
				Employer = @employer,
				StartDate = @startDate,
				EndDate = @endDate
		WHERE ApplicationID = @ApplicationID AND JobID = @jobId
	END
	ELSE BEGIN
		INSERT INTO [dbo].[USR_JobExperiences](
			ApplicationID,
			JobID,
			UserID,
			Title,
			Employer,
			StartDate,
			EndDate,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES(
			@ApplicationID,
			@jobId,
			@userId,
			@title,
			@employer,
			@startDate,
			@endDate,
			@creatorUserId,
			@creationDate,
			0
		)
	END
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_SetEducationalExperience]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_SetEducationalExperience]
GO

CREATE PROCEDURE [dbo].[USR_SetEducationalExperience]
	@ApplicationID	uniqueidentifier,
	@educationId	UNIQUEIDENTIFIER,
	@userId			UNIQUEIDENTIFIER,
	@creatorUserId	UNIQUEIDENTIFIER,
	@creationDate	DATETIME,
	@school			NVARCHAR(256),
	@studyField		NVARCHAR(256),
	@level			VARCHAR(50),
	@graduateDegree	VARCHAR(50),
	@startDate		DATETIME,
	@endDate		DATETIME,
	@isSchool		BIT
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM [dbo].[USR_EducationalExperiences] 
		WHERE ApplicationID = @ApplicationID AND EducationID = @educationId
	) BEGIN	
		UPDATE [dbo].[USR_EducationalExperiences]
			SET UserID = @userId,
				School = @school,
				StudyField = @studyField,
				[Level] = @level,
				[GraduateDegree] = @graduateDegree,
				StartDate = @startDate,
				EndDate = @endDate,
				CreatorUserID = @creatorUserId,
				CreationDate = @creationDate,
				IsSchool = @isSchool
		WHERE ApplicationID = @ApplicationID AND EducationID = @educationId
	END
	ELSE BEGIN
		INSERT INTO [dbo].[USR_EducationalExperiences](
			ApplicationID,
			EducationID,
			UserID,
			School,
			StudyField,
			[Level],
			[GraduateDegree],
			StartDate,
			EndDate,
			CreatorUserID,
			CreationDate,
			IsSchool,
			Deleted
		)
		VALUES(
			@ApplicationID,
			@educationId,
			@userId,
			@school,
			@studyField,
			@level,
			@graduateDegree,
			@startDate,
			@endDate,
			@creatorUserId,
			@creationDate,
			@isSchool,
			0
		)
	END
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_SetHonorAndAward]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_SetHonorAndAward]
GO

CREATE PROCEDURE [dbo].[USR_SetHonorAndAward]
	@ApplicationID	uniqueidentifier,
	@honorId		UNIQUEIDENTIFIER,
	@userId			UNIQUEIDENTIFIER,
	@creatorUserId	UNIQUEIDENTIFIER,
	@creationDate	DATETIME,
	@title			NVARCHAR(512),
	@occupation		NVARCHAR(512),
	@issuer			NVARCHAR(512),
	@issueDate		DATETIME,
	@description	NVARCHAR(MAX)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM [dbo].[USR_HonorsAndAwards] 
		WHERE ApplicationID = @ApplicationID AND ID = @honorId
	) BEGIN
		UPDATE [dbo].[USR_HonorsAndAwards]
			SET UserID = @userId,
				Title = @title,
				Occupation = @occupation,
				Issuer = @issuer,
				IssueDate = @issueDate,
				[Description] = @description,
				CreatorUserID = @creatorUserId,
				CreationDate = @creationDate
		WHERE ApplicationID = @ApplicationID AND ID = @honorId
	END
	ELSE BEGIN
		INSERT INTO [dbo].[USR_HonorsAndAwards](
			ApplicationID,
			ID,
			UserID,
			Title,
			Occupation,
			Issuer,
			IssueDate,
			[Description],
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES(
			@ApplicationID,
			@honorId,
			@userId,
			@title,
			@occupation,
			@issuer,
			@issueDate,
			@description,
			@creatorUserId,
			@creationDate,
			0
		)
	END
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_SetLanguage]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_SetLanguage]
GO

CREATE PROCEDURE [dbo].[USR_SetLanguage]
	@ApplicationID	uniqueidentifier,
	@id				UNIQUEIDENTIFIER,
	@languageName	NVARCHAR(256),
	@userId			UNIQUEIDENTIFIER,
	@creatorUserId	UNIQUEIDENTIFIER,
	@creationDate	DATETIME,
	@level			NVARCHAR(50)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @languageName = [dbo].[GFN_VerifyString](@languageName)
	
	DECLARE @languageId UNIQUEIDENTIFIER = (
		SELECT LanguageID 
		FROM [dbo].[USR_LanguageNames] 
		WHERE ApplicationID = @ApplicationID AND LanguageName = @languageName
	)
	
	IF (@languageId IS NULL) BEGIN
		SET @languageId = NEWID()
		
		INSERT INTO [dbo].[USR_LanguageNames](
			ApplicationID,
			LanguageID,
			LanguageName
		)
		VALUES(
			@ApplicationID,
			@languageId,
			@languageName
		)
	END
		
	IF EXISTS(
		SELECT TOP(1) * 
		FROM [dbo].[USR_UserLanguages] 
		WHERE ApplicationID = @ApplicationID AND ID = @id
	) BEGIN
		UPDATE [dbo].[USR_UserLanguages]
			SET UserID = @userId,
				LanguageID = @languageId,
				[Level]	= @level,
				CreatorUserID = @creatorUserId,
				CreationDate = @creationDate
		WHERE ApplicationID = @ApplicationID AND ID = @id
	END
	ELSE BEGIN
		INSERT INTO [dbo].[USR_UserLanguages](
			ApplicationID,
			ID,
			LanguageID,
			UserID,
			[Level],
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES(
			@ApplicationID,
			@id,
			@languageId,
			@userId,
			@level,
			@creatorUserId,
			@creationDate,
			0
		)
	ENd
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_RemoveJobExperience]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_RemoveJobExperience]
GO

CREATE PROCEDURE [dbo].[USR_RemoveJobExperience]
	@ApplicationID	uniqueidentifier,
	@jobID			UNIQUEIDENTIFIER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[USR_JobExperiences]
		SET Deleted = 1
	WHERE ApplicationID = @ApplicationID AND JobID = @jobID AND Deleted = 0
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_RemoveEducationalExperience]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_RemoveEducationalExperience]
GO

CREATE PROCEDURE [dbo].[USR_RemoveEducationalExperience]
	@ApplicationID	uniqueidentifier,
	@educationID	UNIQUEIDENTIFIER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[USR_EducationalExperiences]
		SET Deleted = 1
	WHERE ApplicationID = @ApplicationID AND EducationID = @educationID AND Deleted = 0
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_RemoveHonorAndAward]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_RemoveHonorAndAward]
GO

CREATE PROCEDURE [dbo].[USR_RemoveHonorAndAward]
	@ApplicationID	uniqueidentifier,
	@honorID		UNIQUEIDENTIFIER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[USR_HonorsAndAwards]
		SET Deleted = 1
	WHERE ApplicationID = @ApplicationID AND ID = @honorID AND Deleted = 0
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_RemoveLanguage]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_RemoveLanguage]
GO

CREATE PROCEDURE [dbo].[USR_RemoveLanguage]
	@ApplicationID	uniqueidentifier,
	@id				UNIQUEIDENTIFIER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[USR_UserLanguages]
		SET Deleted = 1
	WHERE ApplicationID = @ApplicationID AND ID = @id AND Deleted = 0
	
	SELECT @@ROWCOUNT
END

GO

-- end of Profile