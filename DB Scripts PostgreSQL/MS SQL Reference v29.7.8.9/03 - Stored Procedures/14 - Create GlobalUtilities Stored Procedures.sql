USE [EKM_App]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_GetSystemVersion]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_GetSystemVersion]
GO

CREATE PROCEDURE [dbo].[RV_GetSystemVersion]
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(1) [Version]
	FROM [dbo].[AppSetting]
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_SetApplications]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_SetApplications]
GO

CREATE PROCEDURE [dbo].[RV_SetApplications]
	@ApplicationsTemp	GuidStringTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Applications GuidStringTableType
	INSERT INTO @Applications SELECT * FROM @ApplicationsTemp
	
	DECLARE @Count int = 0
	
	UPDATE APP
		SET ApplicationName = A.SecondValue,
			LoweredApplicationName = LOWER(A.SecondValue)
	FROM @Applications AS A
		INNER JOIN [dbo].[aspnet_Applications] AS APP
		ON APP.ApplicationId = A.FirstValue
		
	SET @Count = @@ROWCOUNT
		
	INSERT INTO [dbo].[aspnet_Applications](
		ApplicationId,
		ApplicationName,
		LoweredApplicationName
	)
	SELECT A.FirstValue, A.SecondValue, LOWER(A.SecondValue)
	FROM @Applications AS A
		LEFT JOIN [dbo].[aspnet_Applications] AS APP
		ON APP.ApplicationId = A.FirstValue
	WHERE APP.ApplicationId IS NULL
	
	SELECT @@ROWCOUNT + @Count
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_GetApplicationsByIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_GetApplicationsByIDs]
GO

CREATE PROCEDURE [dbo].[RV_GetApplicationsByIDs]
	@strApplicationIDs	varchar(max),
	@delimiter			char
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @ApplicationIDs GuidTableType

	INSERT INTO @ApplicationIDs ([Value]) 
	SELECT DISTINCT Ref.[Value] 
	FROM [dbo].[GFN_StrToGuidTable](@strApplicationIDs, @delimiter) AS Ref
	
	DECLARE @TotalCount int  = ISNULL((SELECT TOP(1) COUNT(*) FROM @ApplicationIDs), 0)
	
	SELECT 
		@TotalCount AS TotalCount,
		A.ApplicationID,
		A.ApplicationName,
		A.Title,
		A.[Description],
		A.CreatorUserID
	FROM @ApplicationIDs AS IDs
		INNER JOIN [dbo].[aspnet_Applications] AS A
		ON A.ApplicationId = IDs.[Value]
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_GetApplications]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_GetApplications]
GO

CREATE PROCEDURE [dbo].[RV_GetApplications]
	@Count			int,
	@LowerBoundary	int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(ISNULL(@Count, 100))
		X.RowNumber + X.RevRowNumber - 1 AS TotalCount,
		X.ApplicationID,
		X.ApplicationName,
		X.Title,
		X.[Description],
		X.CreatorUserID
	FROM (
			SELECT	ROW_NUMBER() OVER (ORDER BY ApplicationID DESC) AS RowNumber,
					ROW_NUMBER() OVER (ORDER BY ApplicationID ASC) AS RevRowNumber,
					ApplicationId AS ApplicationID,
					ApplicationName,
					Title,
					[Description],
					CreatorUserID
			FROM [dbo].[aspnet_Applications]
		) AS X
	WHERE X.RowNumber >= ISNULL(@LowerBoundary, 0)
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_GetUserApplications]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_GetUserApplications]
GO

CREATE PROCEDURE [dbo].[RV_GetUserApplications]
	@UserID		uniqueidentifier,
	@IsCreator	bit,
	@Archive	bit
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	SET @IsCreator = ISNULL(@IsCreator, 0)
	
	SELECT	0 AS TotalCount,
			App.ApplicationId AS ApplicationID,
			App.ApplicationName,
			App.Title,
			App.[Description],
			CreatorUserID
	FROM [dbo].[USR_UserApplications] AS USR
		INNER JOIN [dbo].[aspnet_Applications] AS App
		ON App.ApplicationId = USR.ApplicationID AND 
			(@IsCreator = 0 OR App.CreatorUserID = @UserID) AND
			(@Archive IS NULL OR ISNULL(App.Deleted, 0) = @Archive)
	WHERE USR.UserID = @UserID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_AddOrModifyApplication]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_AddOrModifyApplication]
GO

CREATE PROCEDURE [dbo].[RV_AddOrModifyApplication]
	@ApplicationID	uniqueidentifier,
	@Name			nvarchar(255),
	@Title			nvarchar(255),
	@Description	nvarchar(255),
	@CurrentUserID	uniqueidentifier,
	@Now			datetime
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) 1
		FROM [dbo].[aspnet_Applications] AS A
		WHERE A.ApplicationId = @ApplicationID
	) BEGIN
		UPDATE [dbo].[aspnet_Applications]
			SET Title = [dbo].[GFN_VerifyString](ISNULL(@Title, N'')),
				[Description] = [dbo].[GFN_VerifyString](ISNULL(@Description, N''))
		WHERE ApplicationId = @ApplicationID	
	END
	ELSE BEGIN
		INSERT INTO [dbo].[aspnet_Applications](
			ApplicationId,
			ApplicationName,
			LoweredApplicationName,
			Title,
			[Description],
			CreatorUserID,
			CreationDate
		)
		VALUES (
			@ApplicationID,
			[dbo].[GFN_VerifyString](ISNULL(@Name, N'')),
			[dbo].[GFN_VerifyString](ISNULL(@Name, N'')),
			[dbo].[GFN_VerifyString](ISNULL(@Title, N'')),
			[dbo].[GFN_VerifyString](ISNULL(@Description, N'')),
			@CurrentUserID,
			@Now
		)
		
		IF @CurrentUserID IS NOT NULL AND @ApplicationID IS NOT NULL BEGIN
			INSERT INTO [dbo].[USR_UserApplications] (ApplicationID, UserID, CreationDate)
			VALUES (@ApplicationID, @CurrentUserID, @Now)
		END
	END
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_RemoveApplication]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_RemoveApplication]
GO

CREATE PROCEDURE [dbo].[RV_RemoveApplication]
	@ApplicationID	uniqueidentifier
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON

	UPDATE [dbo].[aspnet_Applications]
		SET Deleted = 1
	WHERE ApplicationId = @ApplicationID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_RecycleApplication]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_RecycleApplication]
GO

CREATE PROCEDURE [dbo].[RV_RecycleApplication]
	@ApplicationID	uniqueidentifier
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON

	UPDATE [dbo].[aspnet_Applications]
		SET Deleted = 0
	WHERE ApplicationId = @ApplicationID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_AddUserToApplication]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_AddUserToApplication]
GO

CREATE PROCEDURE [dbo].[RV_AddUserToApplication]
	@ApplicationID	uniqueidentifier,
	@UserID			uniqueidentifier,
	@Now			datetime
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	IF @ApplicationID IS NOT NULL AND @UserID IS NOT NULL AND NOT EXISTS(
		SELECT TOP(1) *
		FROM [dbo].[USR_UserApplications]
		WHERE ApplicationID = @ApplicationID AND UserID = @UserID
	) BEGIN
		INSERT INTO [dbo].[USR_UserApplications] (ApplicationID, UserID, CreationDate)
		VALUES (@ApplicationID, @UserID, @Now)
	END
	
	SELECT CASE WHEN @ApplicationID IS NULL OR @UserID IS NULL THEN 0 ELSE 1 END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_RemoveUserFromApplication]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_RemoveUserFromApplication]
GO

CREATE PROCEDURE [dbo].[RV_RemoveUserFromApplication]
	@ApplicationID	uniqueidentifier,
	@UserID			uniqueidentifier
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DELETE [dbo].[USR_UserApplications]
	WHERE ApplicationID = @ApplicationID AND UserID = @UserID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_SetVariable]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_SetVariable]
GO

CREATE PROCEDURE [dbo].[RV_SetVariable]
	@ApplicationID	uniqueidentifier,
	@Name			VARCHAR(100),
	@Value			NVARCHAR(MAX),
	@CurrentUserID	UNIQUEIDENTIFIER,
	@Now			DATETIME
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @Name = LOWER(@Name)
	
	IF EXISTS(
		SELECT TOP(1) 1 
		FROM [dbo].[RV_Variables] 
		WHERE (@ApplicationID IS NULL OR ApplicationID = @ApplicationID) AND Name = @Name
	) BEGIN
		UPDATE [dbo].[RV_Variables]
			SET Value = @Value,
				LastModifierUserID = @CurrentUserID,
				LastModificationDate = @Now
		WHERE (@ApplicationID IS NULL OR ApplicationID = @ApplicationID) AND Name = @Name
	END
	ELSE BEGIN
		INSERT INTO [dbo].[RV_Variables](
			ApplicationID,
			Name,
			Value,
			LastModifierUserID,
			LastModificationDate
		)
		VALUES(
			@ApplicationID,
			@Name,
			@Value,
			@CurrentUserID,
			@Now
		)
	END
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_GetVariable]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_GetVariable]
GO

CREATE PROCEDURE [dbo].[RV_GetVariable]
	@ApplicationID	uniqueidentifier,
	@Name			varchar(100)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @Name = LOWER(@Name)
	
	SELECT TOP(1) Value
	FROM [dbo].[RV_Variables]
	WHERE (@ApplicationID IS NULL OR ApplicationID = @ApplicationID) AND Name = @Name
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_SetOwnerVariable]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_SetOwnerVariable]
GO

CREATE PROCEDURE [dbo].[RV_SetOwnerVariable]
	@ApplicationID	uniqueidentifier,
	@ID				bigint,
	@OwnerID		uniqueidentifier,
	@Name			VARCHAR(100),
	@Value			NVARCHAR(MAX),
	@CurrentUserID	UNIQUEIDENTIFIER,
	@Now			DATETIME
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF @Name IS NOT NULL SET @Name = LOWER(@Name)
	
	IF @ID IS NOT NULL BEGIN
		UPDATE [dbo].[RV_VariablesWithOwner]
			SET Name = LOWER(CASE WHEN ISNULL(@Name, N'') = N'' THEN Name ELSE @Name END),
				Value = @Value,
				LastModifierUserID = @CurrentUserID,
				LastModificationDate = @Now
		WHERE ApplicationID = @ApplicationID AND ID = @ID
		
		IF @@ROWCOUNT > 0 SELECT @ID
		ELSE SELECT NULL
	END
	ELSE BEGIN
		INSERT INTO [dbo].[RV_VariablesWithOwner] (
			ApplicationID,
			OwnerID,
			Name,
			Value,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES (
			@ApplicationID,
			@OwnerID,
			LOWER(@Name),
			@Value,
			@CurrentUserID,
			@Now,
			0
		)
		
		SELECT @@IDENTITY
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_GetOwnerVariables]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_GetOwnerVariables]
GO

CREATE PROCEDURE [dbo].[RV_GetOwnerVariables]
	@ApplicationID	uniqueidentifier,
	@ID				bigint,
	@OwnerID		uniqueidentifier,
	@Name			varchar(100),
	@CreatorUserID	uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @Name = LOWER(@Name)
	
	SELECT	ID,
			OwnerID,
			Name,
			Value,
			CreatorUserID,
			CreationDate
	FROM [dbo].[RV_VariablesWithOwner]
	WHERE ApplicationID = @ApplicationID AND (@ID IS NULL OR ID = @ID) AND 
		(@OwnerID IS NULL OR OwnerID = @OwnerID) AND (@Name IS NULL OR Name = @Name) AND 
		(@CreatorUserID IS NULL OR CreatorUserID = @CreatorUserID) AND Deleted = 0
	ORDER BY ID ASC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_RemoveOwnerVariable]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_RemoveOwnerVariable]
GO

CREATE PROCEDURE [dbo].[RV_RemoveOwnerVariable]
	@ApplicationID	uniqueidentifier,
	@ID				bigint,
	@CurrentUserID	uniqueidentifier,
	@Now			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[RV_VariablesWithOwner]
		SET Deleted = 1,
			LastModifierUserID = @CurrentUserID,
			LastModificationDate = @Now
	WHERE ApplicationID = @ApplicationID AND ID = @ID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_AddEmailsToQueue]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_AddEmailsToQueue]
GO

CREATE PROCEDURE [dbo].[RV_AddEmailsToQueue]
	@ApplicationID			uniqueidentifier,
	@EmailQueueItemsTemp	EmailQueueItemTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @EmailQueueItems EmailQueueItemTableType
	INSERT INTO @EmailQueueItems SELECT * FROM @EmailQueueItemsTemp
	
	UPDATE Q
		SET Title = E.Title,
			EmailBody = E.EmailBody
	FROM @EmailQueueItems AS E
		INNER JOIN [dbo].[RV_EmailQueue] AS Q
		ON Q.ApplicationID = @ApplicationID AND Q.SenderUserID = E.SenderUserID AND 
			Q.[Action] = E.[Action] AND Q.Email = LOWER(E.Email)
	
	DECLARE @Result int = @@ROWCOUNT
	
	INSERT INTO [dbo].[RV_EmailQueue](
		ApplicationID,
		SenderUserID,
		[Action],
		Email,
		Title,
		EmailBody
	)
	SELECT @ApplicationID, E.SenderUserID, E.[Action], LOWER(E.Email), E.Title, E.EmailBody
	FROM @EmailQueueItems AS E
		LEFT JOIN [dbo].[RV_EmailQueue] AS Q
		ON Q.ApplicationID = @ApplicationID AND 
			Q.SenderUserID = E.SenderUserID AND Q.[Action] = E.[Action] AND Q.Email = E.Email
	WHERE Q.ID IS NULL
	
	SELECT @@ROWCOUNT + @Result
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_GetEmailQueueItems]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_GetEmailQueueItems]
GO

CREATE PROCEDURE [dbo].[RV_GetEmailQueueItems]
	@ApplicationID	uniqueidentifier,
	@Count			int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(ISNULL(@Count, 100))
			E.ID,
			E.SenderUserID,
			E.[Action],
			E.Email,
			E.Title,
			E.EmailBody
	FROM [dbo].[RV_EmailQueue] AS E
	WHERE ApplicationID = @ApplicationID
	ORDER BY E.ID ASC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_ArchiveEmailQueueItems]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_ArchiveEmailQueueItems]
GO

CREATE PROCEDURE [dbo].[RV_ArchiveEmailQueueItems]
	@ApplicationID	uniqueidentifier,
	@ItemIDsTemp	BigIntTableType readonly,
	@Now			datetime
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @ItemIDs BigIntTableType
	INSERT INTO @ItemIDs SELECT * FROM @ItemIDsTemp
	
	INSERT INTO [dbo].[RV_SentEmails](
		ApplicationID,
		SenderUserID,
		SendDate,
		[Action],
		Email,
		Title,
		EmailBody
	)
	SELECT @ApplicationID, E.SenderUserID, @Now, E.[Action], E.Email, E.Title, E.EmailBody
	FROM @ItemIDs AS IDs
		INNER JOIN [dbo].[RV_EmailQueue] AS E
		ON E.ApplicationID = @ApplicationID AND E.ID = IDs.Value
		
		
	DELETE E
	FROM @ItemIDs AS IDs
		INNER JOIN [dbo].[RV_EmailQueue] AS E
		ON E.ApplicationID = @ApplicationID AND E.ID = IDs.Value
		
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_P_SetDeletedStates]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_P_SetDeletedStates]
GO

CREATE PROCEDURE [dbo].[RV_P_SetDeletedStates]
	@ApplicationID	uniqueidentifier,
	@ObjectsTemp	GuidBitTableType readonly,
	@ObjectType		varchar(50),
	@Now			datetime,
	@_Result		int output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Objects GuidBitTableType
	INSERT INTO @Objects SELECT * FROM @ObjectsTemp
	
	IF @Now IS NULL SET @Now = GETDATE()
	
	DELETE D
	FROM @Objects AS O
		INNER JOIN [dbo].[RV_DeletedStates] AS D
		ON D.ApplicationID = @ApplicationID AND D.ObjectID = O.FirstValue
		
	INSERT INTO [dbo].[RV_DeletedStates](ApplicationID, ObjectID, ObjectType, Deleted, [Date])
	SELECT @ApplicationID, O.FirstValue, @ObjectType, O.SecondValue, @Now
	FROM @Objects AS O
		
	SET @_Result = @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_GetDeletedStates]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_GetDeletedStates]
GO

CREATE PROCEDURE [dbo].[RV_GetDeletedStates]
	@ApplicationID	uniqueidentifier,
	@Count			int,
	@StartFrom		bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF ISNULL(@Count, 0) < 1 SET @Count = 1000
	
	SELECT TOP(@Count)
		D.ID,
		D.ObjectID,
		D.ObjectType,
		D.[Date],
		D.Deleted,
		CASE
			WHEN ObjectType = N'NodeRelation' THEN CAST(1 as bit)
			WHEN ObjectType = N'Friend' AND FR.AreFriends = 1 THEN CAST(1 as bit)
			ELSE CAST(0 as bit)
		END AS Bidirectional,
		CASE
			WHEN ObjectType = N'Friend' AND FR.AreFriends = 0 THEN CAST(1 as bit)
			WHEN ObjectType = N'NodeMember' THEN CAST(1 as bit)
			WHEN ObjectType = N'Expert' THEN CAST(1 as bit)
			WHEN ObjectType = N'NodeLike' THEN CAST(1 as bit)
			WHEN ObjectType = N'ItemVisit' THEN CAST(1 as bit)
			WHEN ObjectType = N'NodeCreator' THEN CAST(1 as bit)
			WHEN ObjectType = N'TaggedItem' THEN CAST(1 as bit)
			WHEN ObjectType = N'WikiChange' THEN CAST(1 as bit)
			ELSE CAST(0 as bit)
		END AS HasReverse,
		CASE
			WHEN ObjectType = N'NodeCreator' THEN NC.NodeID
			WHEN ObjectType = N'NodeRelation' THEN NR.SourceNodeID
			WHEN ObjectType = N'NodeMember' THEN NM.NodeID
			WHEN ObjectType = N'Expert' THEN EX.NodeID
			WHEN ObjectType = N'NodeLike' THEN NL.NodeID
			WHEN ObjectType = N'ItemVisit' THEN IV.ItemID
			WHEN ObjectType = N'Friend' THEN FR.SenderUserID
			WHEN ObjectType = N'WikiChange' THEN WT.OwnerID
			WHEN ObjectType = N'TaggedItem' AND TI.ContextType = N'WikiChange' THEN TGWT.OwnerID
			WHEN ObjectType = N'TaggedItem' AND TI.ContextType = N'Post' THEN TGPS.OwnerID
			WHEN ObjectType = N'TaggedItem' AND TI.ContextType = N'Comment' THEN TGPS2.OwnerID
			ELSE NULL
		END AS RelSourceID,
		CASE
			WHEN ObjectType = N'NodeCreator' THEN NC.UserID
			WHEN ObjectType = N'NodeRelation' THEN NR.DestinationNodeID
			WHEN ObjectType = N'NodeMember' THEN NM.UserID
			WHEN ObjectType = N'Expert' THEN EX.UserID
			WHEN ObjectType = N'NodeLike' THEN NL.UserID
			WHEN ObjectType = N'ItemVisit' THEN IV.UserID
			WHEN ObjectType = N'Friend' THEN FR.ReceiverUserID
			WHEN ObjectType = N'WikiChange' THEN WC.UserID
			WHEN ObjectType = N'TaggedItem' THEN TI.TaggedID
			ELSE NULL
		END AS RelDestinationID,
		CASE
			WHEN ObjectType = N'NodeCreator' THEN N'Node'
			WHEN ObjectType = N'NodeRelation' THEN N'Node'
			WHEN ObjectType = N'NodeMember' THEN N'Node'
			WHEN ObjectType = N'Expert' THEN N'Node'
			WHEN ObjectType = N'NodeLike' THEN N'Node'
			WHEN ObjectType = N'ItemVisit' AND IV.ItemType = N'User' THEN N'User'
			WHEN ObjectType = N'ItemVisit' THEN N'Node'
			WHEN ObjectType = N'Friend' THEN N'User'
			WHEN ObjectType = N'WikiChange' THEN N'Node'
			WHEN ObjectType = N'TaggedItem' AND TI.ContextType = N'WikiChange' THEN N'Node'
			WHEN ObjectType = N'TaggedItem' AND TGUN.UserID IS NOT NULL THEN N'User'
			WHEN ObjectType = N'TaggedItem' THEN N'Node'
			ELSE NULL
		END AS RelSourceType,
		CASE
			WHEN ObjectType = N'NodeCreator' THEN N'User'
			WHEN ObjectType = N'NodeRelation' THEN N'User'
			WHEN ObjectType = N'NodeMember' THEN N'User'
			WHEN ObjectType = N'Expert' THEN N'User'
			WHEN ObjectType = N'NodeLike' THEN N'User'
			WHEN ObjectType = N'ItemVisit' THEN N'User'
			WHEN ObjectType = N'Friend' THEN N'User'
			WHEN ObjectType = N'WikiChange' THEN N'User'
			WHEN ObjectType = N'TaggedItem' THEN TI.TaggedType
			ELSE NULL
		END AS RelDestinationType,
		CASE
			WHEN ObjectType = N'TaggedItem' THEN TI.CreatorUserID
			ELSE NULL
		END AS RelCreatorID
	FROM [dbo].[RV_DeletedStates] AS D
		LEFT JOIN [dbo].[CN_NodeCreators] AS NC
		ON NC.ApplicationID = @ApplicationID AND NC.UniqueID = D.ObjectID
		LEFT JOIN [dbo].[CN_NodeRelations] AS NR
		ON NR.ApplicationID = @ApplicationID AND NR.UniqueID = D.ObjectID
		LEFT JOIN [dbo].[CN_NodeMembers] AS NM
		ON NM.ApplicationID = @ApplicationID AND NM.UniqueID = D.ObjectID
		LEFT JOIN [dbo].[CN_Experts] AS EX
		ON EX.ApplicationID = @ApplicationID AND EX.UniqueID = D.ObjectID
		LEFT JOIN [dbo].[CN_NodeLikes] AS NL
		ON NL.ApplicationID = @ApplicationID AND NL.UniqueID = D.ObjectID
		LEFT JOIN [dbo].[USR_ItemVisits] AS IV
		ON IV.ApplicationID = @ApplicationID AND IV.UniqueID = D.ObjectID
		LEFT JOIN [dbo].[USR_Friends] AS FR
		ON FR.ApplicationID = @ApplicationID AND FR.UniqueID = D.ObjectID
		LEFT JOIN [dbo].[WK_Changes] AS WC
		ON WC.ApplicationID = @ApplicationID AND WC.ChangeID = D.ObjectID
		LEFT JOIN [dbo].[WK_Paragraphs] AS WP
		ON WP.ApplicationID = @ApplicationID AND WP.ParagraphID = WC.ParagraphID
		LEFT JOIN [dbo].[WK_Titles] AS WT
		ON WT.ApplicationID = @ApplicationID AND WT.TitleID = WP.TitleID
		LEFT JOIN [dbo].[RV_TaggedItems] AS TI
		ON TI.ApplicationID = @ApplicationID AND TI.UniqueID = D.ObjectID
		LEFT JOIN [dbo].[WK_Paragraphs] AS TGWP
		ON TGWP.ApplicationID = @ApplicationID AND TGWP.ParagraphID = TI.ContextID
		LEFT JOIN [dbo].[WK_Titles] AS TGWT
		ON TGWT.ApplicationID = @ApplicationID AND TGWT.TitleID = TGWP.TitleID
		LEFT JOIN [dbo].[SH_PostShares] AS TGPS
		ON TGPS.ApplicationID = @ApplicationID AND TGPS.ShareID = TI.ContextID
		LEFT JOIN [dbo].[SH_Comments] AS TGPC
		ON TGPC.ApplicationID = @ApplicationID AND TGPC.CommentID = TI.ContextID
		LEFT JOIN [dbo].[SH_PostShares] AS TGPS2
		ON TGPS2.ApplicationID = @ApplicationID AND TGPS2.ShareID = TGPC.ShareID
		LEFT JOIN [dbo].[Users_Normal] AS TGUN
		ON TGUN.ApplicationID = @ApplicationID AND
			TGUN.UserID = TGPS.OwnerID OR TGUN.UserID = TGPS2.OwnerID
	WHERE D.ApplicationID = @ApplicationID AND D.ID >= ISNULL(@StartFrom, 0)
	ORDER BY D.ID ASC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_GetGuids]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_GetGuids]
GO

CREATE PROCEDURE [dbo].[RV_GetGuids]
	@ApplicationID		uniqueidentifier,
	@IDsTemp			StringTableType readonly,
	@Type				varchar(100),
	@Exist				bit,
	@CreateIfNotExist	bit
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @IDs StringTableType
	INSERT INTO @IDs SELECT * FROM @IDsTemp
	
	DECLARE @TBL TABLE (ID varchar(100), [Exists] bit, [Guid] uniqueidentifier)
	
	INSERT INTO @TBL (ID, [Exists], [Guid])
	SELECT I.Value, (CASE WHEN G.ID IS NULL THEN 0 ELSE 1 END), ISNULL(G.[Guid], NEWID())
	FROM @IDs AS I
		LEFT JOIN [dbo].[RV_ID2Guid] AS G
		ON G.ApplicationID = @ApplicationID AND G.ID = I.Value AND G.[Type] = @Type
		
	IF @CreateIfNotExist = 1 BEGIN
		INSERT INTO [dbo].[RV_ID2Guid](ApplicationID, ID, [Type], [Guid])
		SELECT @ApplicationID, I.ID, @Type, I.[Guid] 
		FROM @TBL AS I
		WHERE I.[Exists] = 0
	END
	
	SELECT I.ID, I.[Guid]
	FROM @TBL AS I
	WHERE @Exist IS NULL OR I.[Exists] = @Exist
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_SaveTaggedItems]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_SaveTaggedItems]
GO

CREATE PROCEDURE [dbo].[RV_SaveTaggedItems]
	@ApplicationID		uniqueidentifier,
	@TaggedItemsTemp	TaggedItemTableType readonly,
	@RemoveOldTags		bit,
	@CurrentUserID		uniqueidentifier
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @TaggedItems TaggedItemTableType
	INSERT INTO @TaggedItems SELECT * FROM @TaggedItemsTemp
	
	IF @RemoveOldTags = 1 BEGIN
		DELETE TI
		FROM (
				SELECT DISTINCT I.ContextID
				FROM @TaggedItems AS I
			) AS Con
			INNER JOIN [dbo].[RV_TaggedItems] AS TI
			ON TI.ApplicationID = @ApplicationID AND TI.ContextID = Con.ContextID
			LEFT JOIN @TaggedItems AS T
			ON T.ContextID = TI.ContextID AND T.TaggedID = TI.TaggedID
		WHERE T.ContextID IS NULL
	END
	
	INSERT INTO [dbo].[RV_TaggedItems](
		ApplicationID,
		ContextID,
		TaggedID,
		CreatorUserID,
		ContextType,
		TaggedType,
		UniqueID
	)
	SELECT @ApplicationID, TI.ContextID, TI.TaggedID, 
		@CurrentUserID, TI.ContextType, TI.TaggedType, NEWID()
	FROM (
			SELECT DISTINCT * 
			FROM @TaggedItems
		) AS TI
		LEFT JOIN [dbo].[RV_TaggedItems] AS T
		ON T.ApplicationID = @ApplicationID AND T.ContextID = TI.ContextID AND 
			T.TaggedID = TI.TaggedID AND T.CreatorUserID = @CurrentUserID
	WHERE TI.TaggedID IS NOT NULL AND T.ContextID IS NULL
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_GetTaggedItems]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_GetTaggedItems]
GO

CREATE PROCEDURE [dbo].[RV_GetTaggedItems]
	@ApplicationID		uniqueidentifier,
	@ContextID			uniqueidentifier,
	@TaggedTypesTemp	StringTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @TaggedTypes StringTableType
	INSERT INTO @TaggedTypes SELECT * FROM @TaggedTypesTemp
	
	DECLARE @TaggedTypesCount int = (SELECT COUNT(*) FROM @TaggedTypes)
	
	SELECT	TI.TaggedID AS ID,
			TI.TaggedType AS [Type]
	FROM [dbo].[RV_TaggedItems] AS TI
	WHERE TI.ApplicationID = @ApplicationID AND TI.ContextID = @ContextID AND
		(@TaggedTypesCount = 0 OR TI.TaggedType IN (SELECT Value FROM @TaggedTypes))
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_AddSystemAdmin]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_AddSystemAdmin]
GO

CREATE PROCEDURE [dbo].[RV_AddSystemAdmin]
	@ApplicationID		uniqueidentifier,
	@UserID				uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
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
	
	IF EXISTS(
		SELECT TOP(1) 1
		FROM [dbo].[aspnet_UsersInRoles]
		WHERE UserId = @UserID AND RoleId = @AdminRoleID
	) BEGIN
		SELECT 1
	END
	ELSE BEGIN
		INSERT INTO [dbo].[aspnet_UsersInRoles] (UserID, RoleID)
		VALUES (@UserID, @AdminRoleID)
		
		SELECT @@ROWCOUNT
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_IsSystemAdmin]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_IsSystemAdmin]
GO

CREATE PROCEDURE [dbo].[RV_IsSystemAdmin]
	@ApplicationID		uniqueidentifier,
	@UserID				uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT [dbo].[GFN_IsSystemAdmin](@ApplicationID, @UserID)
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_GetFileExtension]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_GetFileExtension]
GO

CREATE PROCEDURE [dbo].[RV_GetFileExtension]
	@ApplicationID		uniqueidentifier,
	@FileID				uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(1) F.Extension AS Value
	FROM [dbo].[DCT_Files] AS F
	WHERE F.ApplicationID = @ApplicationID AND 
		(F.ID = @FileID OR F.FileNameGuid = @FileID)
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_LikeDislikeUnlike]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_LikeDislikeUnlike]
GO

CREATE PROCEDURE [dbo].[RV_LikeDislikeUnlike]
	@ApplicationID		uniqueidentifier,
	@UserID				uniqueidentifier,
	@LikedID			uniqueidentifier,
	@Like				bit,
	@Now				datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF @Like IS NULL BEGIN
		DELETE [dbo].[RV_Likes]
		WHERE ApplicationID = @ApplicationID AND UserID = @UserID AND LikedID = @LikedID
	END
	ELSE BEGIN
		UPDATE [dbo].[RV_Likes]
			SET [Like] = @Like,
				ActionDate = ISNULL(ActionDate, @Now)
		WHERE ApplicationID = @ApplicationID AND 
			UserID = @UserID AND LikedID = @LikedID
			
		IF @@ROWCOUNT = 0 BEGIN
			INSERT INTO [dbo].[RV_Likes] (
				ApplicationID,
				UserID,
				LikedID,
				[Like],
				ActionDate
			)
			VALUES (
				@ApplicationID,
				@UserID,
				@LikedID,
				@Like,
				@Now
			)
		END
	END
	
	SELECT 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_GetFanIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_GetFanIDs]
GO

CREATE PROCEDURE [dbo].[RV_GetFanIDs]
	@ApplicationID		uniqueidentifier,
	@LikedID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT L.UserID AS ID
	FROM [dbo].[RV_Likes] AS L
	WHERE L.ApplicationID =  @ApplicationID AND L.LikedID = @LikedID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_FollowUnfollow]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_FollowUnfollow]
GO

CREATE PROCEDURE [dbo].[RV_FollowUnfollow]
	@ApplicationID		uniqueidentifier,
	@UserID				uniqueidentifier,
	@FollowedID			uniqueidentifier,
	@Follow				bit,
	@Now				datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF ISNULL(@Follow, 0) = 0 BEGIN
		DELETE [dbo].[RV_Followers]
		WHERE ApplicationID = @ApplicationID AND FollowedID = @FollowedID AND UserID = @UserID
	END
	ELSE BEGIN
		UPDATE [dbo].[RV_Followers]
			SET ActionDate = ISNULL(ActionDate, @Now)
		WHERE ApplicationID = @ApplicationID AND 
			FollowedID = @FollowedID AND UserID = @UserID
			
		IF @@ROWCOUNT = 0 BEGIN
			INSERT INTO [dbo].[RV_Followers] (
				ApplicationID,
				UserID,
				FollowedID,
				ActionDate
			)
			VALUES (
				@ApplicationID,
				@UserID,
				@FollowedID,
				@Now
			)
		END
	END
	
	SELECT 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_SetSystemSettings]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_SetSystemSettings]
GO

CREATE PROCEDURE [dbo].[RV_SetSystemSettings]
	@ApplicationID	uniqueidentifier,
	@ItemsTemp		StringPairTableType readonly,
	@CurrentUserID	uniqueidentifier,
	@Now			datetime
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Items StringPairTableType
	INSERT INTO @Items SELECT * FROM @ItemsTemp
	
	UPDATE S
		SET Value = I.SecondValue,
			LastModifierUserID = @CurrentUserID,
			LastModificationDate = @Now
	FROM @Items AS I
		INNER JOIN [dbo].[RV_SystemSettings] AS S
		ON S.ApplicationID = @ApplicationID AND S.Name = I.FirstValue
		
	INSERT INTO [dbo].[RV_SystemSettings] (ApplicationID, Name, Value, 
		LastModifierUserID, LastModificationDate)
	SELECT @ApplicationID, I.FirstValue, [dbo].[GFN_VerifyString](I.SecondValue), @CurrentUserID, @Now
	FROM @Items AS I
		LEFT JOIN [dbo].[RV_SystemSettings] AS S
		ON S.ApplicationID = @ApplicationID AND S.Name = I.FirstValue
	WHERE S.ID IS NULL
	
	SELECT 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_GetSystemSettings]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_GetSystemSettings]
GO

CREATE PROCEDURE [dbo].[RV_GetSystemSettings]
	@ApplicationID	uniqueidentifier,
	@strItemNames	varchar(2000),
	@delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Names StringTableType
	
	INSERT INTO @Names (Value)
	SELECT DISTINCT Ref.Value
	FROM [dbo].[GFN_StrToStringTable](@strItemNames, @delimiter) AS Ref
	
	DECLARE @Count int = (SELECT COUNT(*) FROM @Names)
	
	SELECT S.[Name], S.[Value]
	FROM [dbo].[RV_SystemSettings] AS S
	WHERE S.ApplicationID = @ApplicationID AND 
		(@Count = 0 OR S.Name IN (SELECT N.Value FROM @Names AS N))
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_GetLastContentCreators]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_GetLastContentCreators]
GO

CREATE PROCEDURE [dbo].[RV_GetLastContentCreators]
	@ApplicationID		uniqueidentifier,
	@Count				int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	;WITH Users
	AS
	(
		SELECT	X.UserID, 
				MAX(X.[Date]) AS [Date],
				N'Post' AS [Type]
		FROM (
				SELECT TOP(20) PS.SenderUserID AS UserID, PS.SendDate AS [Date]
				FROM [dbo].[SH_PostShares] AS PS
				WHERE PS.ApplicationID = @ApplicationID AND PS.Deleted = 0
				ORDER BY PS.SendDate DESC
			) AS X
		GROUP BY X.UserID

		UNION ALL

		SELECT	X.UserID, 
				MAX(X.[Date]) AS [Date],
				N'Question' AS [Type]
		FROM (
				SELECT TOP(20) Q.SenderUserID AS UserID, Q.SendDate AS [Date]
				FROM [dbo].[QA_Questions] AS Q
				WHERE Q.ApplicationID = @ApplicationID AND 
					Q.PublicationDate IS NOT NULL AND Q.Deleted = 0
				ORDER BY Q.SendDate DESC
			) AS X
		GROUP BY X.UserID

		UNION ALL

		SELECT	X.UserID, 
				MAX(X.[Date]) AS [Date],
				N'Node' AS [Type]
		FROM (
				SELECT TOP(20) ND.CreatorUserID AS UserID, ND.CreationDate AS [Date]
				FROM [dbo].[CN_Nodes] AS ND
				WHERE ND.ApplicationID = @ApplicationID AND ND.Deleted = 0
				ORDER BY ND.CreationDate DESC
			) AS X
		GROUP BY X.UserID

		UNION ALL

		SELECT	X.UserID, 
				MAX(X.[Date]) AS [Date],
				N'Wiki' AS [Type]
		FROM (
				SELECT TOP(20) C.UserID AS UserID, C.SendDate  AS [Date]
				FROM [dbo].[WK_Changes] AS C
				WHERE C.ApplicationID = @ApplicationID AND C.Applied = 1
				ORDER BY C.SendDate DESC
			) AS X
		GROUP BY X.UserID
	)
	SELECT TOP(ISNULL(@Count, 10))
		X.UserID,
		UN.UserName,
		UN.FirstName,
		UN.LastName,
		X.[Date],
		X.[Types]
	FROM (
			SELECT	Users.UserID, 
					MAX(Users.[Date]) AS [Date],
					STUFF((
						SELECT ',' + [Type]
						FROM Users AS x
						WHERE UserID = Users.UserID
						FOR XML PATH(''),TYPE).value('(./text())[1]','VARCHAR(MAX)')
					  ,1,1,'') AS [Types]
			FROM Users
			GROUP BY Users.UserID
		) AS X
		INNER JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND UN.UserID = X.UserID
	ORDER BY X.[Date] DESC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_RaaiVanStatistics]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_RaaiVanStatistics]
GO

CREATE PROCEDURE [dbo].[RV_RaaiVanStatistics]
	@ApplicationID	uniqueidentifier,
	@DateFrom		datetime,
	@DateTo			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT 
		(
			SELECT COUNT(NodeID)
			FROM [dbo].[CN_View_Nodes_Normal]
			WHERE ApplicationID = @ApplicationID AND Deleted = 0 AND
				(@DateFrom IS NULL OR CreationDate >= @DateFrom) AND
				(@DateTo IS NULL OR CreationDate <= @DateTo)
		) AS NodesCount,
		(
			SELECT COUNT(QuestionID)
			FROM [dbo].[QA_Questions]
			WHERE ApplicationID = @ApplicationID AND PublicationDate IS NOT NULL AND Deleted = 0 AND
				(@DateFrom IS NULL OR SendDate >= @DateFrom) AND
				(@DateTo IS NULL OR SendDate <= @DateTo)
		) AS QuestionsCount,
		(
			SELECT COUNT(A.AnswerID)
			FROM [dbo].[QA_Answers] AS A
				INNER JOIN [dbo].[QA_Questions] AS Q
				ON Q.ApplicationID = @ApplicationID AND Q.QuestionID = A.QuestionID AND 
					Q.PublicationDate IS NOT NULL AND Q.Deleted = 0
			WHERE A.ApplicationID = @ApplicationID AND A.Deleted = 0 AND
				(@DateFrom IS NULL OR A.SendDate >= @DateFrom) AND
				(@DateTo IS NULL OR A.SendDate <= @DateTo)
		) AS AnswersCount,
		(
			SELECT COUNT(C.ChangeID)
			FROM [dbo].[WK_Changes] AS C
			WHERE C.ApplicationID = @ApplicationID AND C.Applied = 1 AND C.Deleted = 0 AND
				(@DateFrom IS NULL OR C.SendDate >= @DateFrom) AND
				(@DateTo IS NULL OR C.SendDate <= @DateTo)
		) AS WikiChangesCount,
		(
			SELECT COUNT(PS.ShareID)
			FROM [dbo].[SH_PostShares] AS PS
			WHERE PS.ApplicationID = @ApplicationID AND PS.[Deleted] = 0 AND
				(@DateFrom IS NULL OR PS.SendDate >= @DateFrom) AND
				(@DateTo IS NULL OR PS.SendDate <= @DateTo)
		) AS PostsCount,
		(
			SELECT COUNT(C.CommentID)
			FROM [dbo].[SH_Comments] AS C
			WHERE C.ApplicationID = @ApplicationID AND C.[Deleted] = 0 AND
				(@DateFrom IS NULL OR C.SendDate >= @DateFrom) AND
				(@DateTo IS NULL OR C.SendDate <= @DateTo)
		) AS CommentsCount,
		(
			SELECT COUNT(DISTINCT LG.UserID)
			FROM [dbo].[LG_Logs] AS LG
			WHERE LG.ApplicationID = @ApplicationID AND LG.[Action] = N'Login' AND
				(@DateFrom IS NULL OR LG.[Date] >= @DateFrom) AND
				(@DateTo IS NULL OR LG.[Date] <= @DateTo)
		) AS ActiveUsersCount,
		(
			SELECT COUNT(ItemID) 
			FROM [dbo].[CN_Nodes] AS ND
				INNER JOIN [dbo].[USR_ItemVisits] AS IV
				ON IV.ApplicationID = @ApplicationID AND IV.[ItemID] = ND.NodeID
			WHERE ND.ApplicationID = @ApplicationID AND ND.NodeID = IV.ItemID AND ND.Deleted = 0 AND
				(@DateFrom IS NULL OR IV.VisitDate >= @DateFrom) AND
				(@DateTo IS NULL OR IV.VisitDate <= @DateTo)
		) AS NodePageVisitsCount,
		(
			SELECT COUNT(LogID)
			FROM [dbo].[LG_Logs] AS LG
			WHERE LG.ApplicationID = @ApplicationID AND LG.[Action] = N'Search' AND
				(@DateFrom IS NULL OR LG.[Date] >= @DateFrom) AND
				(@DateTo IS NULL OR LG.[Date] <= @DateTo)
		) AS SearchesCount
END

GO



IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_SchemaInfo]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_SchemaInfo]
GO

CREATE PROCEDURE [dbo].[RV_SchemaInfo]
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT	TBL.TABLE_NAME AS [Table], 
			CLM.COLUMN_NAME AS [Column], 
			CAST(CASE WHEN PRM.COLUMN_NAME IS NULL THEN 0 ELSE 1 END AS bit) AS IsPrimaryKey,
			CAST(COLUMNPROPERTY(object_id(TBL.TABLE_NAME), CLM.COLUMN_NAME, 'IsIdentity') AS bit) AS IsIdentity,
			CAST(CASE WHEN CLM.IS_NULLABLE = 'YES' THEN 1 ELSE 0 END AS bit) AS IsNullable, 
			UPPER(CLM.DATA_TYPE) AS DataType, 
			CLM.CHARACTER_MAXIMUM_LENGTH AS [MaxLength],
			CLM.ORDINAL_POSITION AS [Order],
			CLM.COLUMN_DEFAULT AS DefaultValue
	FROM INFORMATION_SCHEMA.TABLES AS TBL
		INNER JOIN INFORMATION_SCHEMA.COLUMNS AS CLM
		ON CLM.TABLE_NAME = TBL.TABLE_NAME
		LEFT JOIN (
			SELECT CCU.TABLE_NAME, CCU.COLUMN_NAME
			FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS CNT
				INNER JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE AS CCU
				ON CCU.CONSTRAINT_NAME = CNT.CONSTRAINT_NAME
			WHERE CNT.CONSTRAINT_TYPE = N'PRIMARY KEY'
		) AS PRM
		ON PRM.TABLE_NAME = TBL.TABLE_NAME AND PRM.COLUMN_NAME = CLM.COLUMN_NAME
	WHERE TBL.TABLE_TYPE = N'BASE TABLE'
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_ForeignKeys]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_ForeignKeys]
GO

CREATE PROCEDURE [dbo].[RV_ForeignKeys]
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT	OBJ.[name] AS [Name],
			FromTable.[name] AS [Table],
			FromColumn.[name] AS [Column],
			ToTable.[name] AS RefTable,
			ToColumn.[name] AS RefColumn
	FROM sys.foreign_key_columns AS FKC
		INNER JOIN sys.objects AS OBJ
		ON OBJ.object_id = FKC.constraint_object_id
		INNER JOIN sys.tables AS FromTable
		ON FromTable.object_id = FKC.parent_object_id
		INNER JOIN sys.columns AS FromColumn
		ON FromColumn.column_id = FKC.parent_column_id AND FromColumn.object_id = FromTable.object_id
		INNER JOIN sys.tables AS ToTable
		ON ToTable.object_id = FKC.referenced_object_id
		INNER JOIN sys.columns AS ToColumn
		ON ToColumn.column_id = FKC.referenced_column_id AND ToColumn.object_id = ToTable.object_id
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_Indexes]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_Indexes]
GO

CREATE PROCEDURE [dbo].[RV_Indexes]
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT	Ind.[name] AS [Name], 
			OBJECT_NAME(Ind.[object_id]) AS [Table],
			COL_NAME(Col.object_id, Col.column_id) AS [Column],
			CAST(Col.key_ordinal AS int) AS [Order],
			Col.is_descending_key AS IsDescending,
			is_unique AS IsUnique,
			is_unique_constraint AS IsUniqueConstraint,
			Col.is_included_column AS IsIncludedColumn,
			[type_desc] AS IndexType
	FROM sys.indexes AS Ind
		INNER JOIN sys.index_columns AS Col
		ON Col.object_id = Ind.object_id AND Col.index_id = Ind.index_id
	WHERE OBJECT_SCHEMA_NAME(ind.[object_id]) = 'dbo' AND ind.is_primary_key = 0 AND 
		Ind.[type_desc] <> 'HEAP' AND OBJECTPROPERTY(Ind.[object_id], 'IsTable') = 1
	ORDER BY OBJECT_NAME(Ind.[object_id])
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_UserDefinedTableTypes]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_UserDefinedTableTypes]
GO

CREATE PROCEDURE [dbo].[RV_UserDefinedTableTypes]
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT	TP.[name] AS [Name],
			COL.[name] AS [Column],
			CAST(COL.column_id AS int) AS [Order],
			ST.[name] AS [DataType],
			CAST(COL.Is_Nullable AS bit) AS IsNullable,
			CAST(COL.is_identity AS bit) AS IsIdentity,
			CAST(COL.max_length AS int) AS [MaxLength]
	FROM sys.table_types AS TP
		INNER JOIN sys.columns AS COL
		ON TP.type_table_object_id = COL.object_id
		INNER JOIN sys.systypes AS ST  
		ON ST.xtype = COL.system_type_id
	where TP.is_user_defined = 1 AND ST.[name] <> 'sysname'
	ORDER BY TP.[name], COL.column_id
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RV_FullTextIndexes]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RV_FullTextIndexes]
GO

CREATE PROCEDURE [dbo].[RV_FullTextIndexes]
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT	OBJECT_NAME(Ind.object_id) AS [Table], 
			C.[name] AS [Column],
			T.[name] AS DataType,
			CAST(C.max_length AS int) AS [MaxLength],
			CAST(C.is_identity AS bit) AS IsIdentity
	FROM sys.fulltext_indexes AS Ind
		INNER JOIN sys.fulltext_index_columns AS Col
		ON Col.object_id = Ind.object_id
		INNER JOIN sys.columns AS C
		ON C.object_id = Col.object_id AND C.column_id = Col.column_id
		INNER JOIN sys.types AS T
		ON C.system_type_id = T.system_type_id
END

GO
