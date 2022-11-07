USE [Miliad]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[MSG_GetThreads]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[MSG_GetThreads]
GO

CREATE PROCEDURE [dbo].[MSG_GetThreads]
	@ApplicationID	UNIQUEIDENTIFIER,
    @UserID			UNIQUEIDENTIFIER,
    @Count			INT,
    @LastID			INT
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	;WITH BaseData AS (
		SELECT TOP(ISNULL(@Count, 10))
			D.ThreadID, 
			TN.[Name] AS ThreadName,
			UN.UserName, 
			UN.FirstName, 
			UN.LastName,
			UN.AvatarName,
			UN.UseAvatar,
			CAST((CASE WHEN UN.UserID IS NULL THEN 1 ELSE 0 END) AS bit) AS IsGroup,
			D.MessagesCount,
			D.SentCount,
			D.NotSeenCount,
			D.RowNumber
		FROM (
				SELECT ROW_NUMBER() OVER (ORDER BY Ref.MaxID DESC) AS RowNumber, Ref.*
				FROM (
						SELECT	MD.ThreadID, 
								MAX(MD.ID) AS MaxID,
								MIN(MD.ID) AS MinID,
								COUNT(MD.ID) AS MessagesCount, 
								SUM(CAST(MD.IsSender AS int)) AS SentCount,
								SUM(
									CAST((CASE WHEN MD.IsSender = 0 AND MD.Seen = 0 THEN 1 ELSE 0 END) AS int)
								) AS NotSeenCount
						FROM [dbo].[MSG_MessageDetails] AS MD
						WHERE MD.ApplicationID = @ApplicationID AND 
							MD.UserID = @UserID AND MD.Deleted = 0
						GROUP BY MD.ThreadID
					) AS Ref
			) AS D
			LEFT JOIN [dbo].[Users_Normal] AS UN
			ON UN.ApplicationID = @ApplicationID AND UN.UserID = D.ThreadID
			LEFT JOIN [dbo].[MSG_ThreadNames] AS TN
			ON TN.ApplicationID = @ApplicationID AND TN.ThreadID = D.ThreadID
		WHERE (@LastID IS NULL OR D.RowNumber > @LastID)
	),
	ExtremeIDs AS (
		SELECT B.ThreadID, MIN(D.ID) AS MinID, MAX(D.ID) AS MaxID
		FROM BaseData AS B
			INNER JOIN [dbo].[MSG_MessageDetails] AS D
			ON D.ApplicationID = @ApplicationID AND D.ThreadID = B.ThreadID
		GROUP BY B.ThreadID
	)
	SELECT	B.*,
			CAST(CASE
				WHEN B.IsGroup = 1 AND FirstMD.SenderUserID IS NOT NULL AND 
					@UserID IS NOT NULL AND FirstMD.SenderUserID = @UserID THEN 1
				ELSE 0
			END AS bit) AS IsCreator,
			CAST(CASE
				WHEN B.IsGroup = 1 AND TRDUser.UserID IS NULL THEN 1
				ELSE 0
			END AS bit) AS RemovedFromGroup
	FROM BaseData AS B
		INNER JOIN ExtremeIDs AS E
		ON E.ThreadID = B.ThreadID
		LEFT JOIN [dbo].[MSG_MessageDetails] AS FirstMSG
		ON FirstMSG.ApplicationID = @ApplicationID AND FirstMSG.ID = E.MinID
		LEFT JOIN [dbo].[MSG_Messages] AS FirstMD
		ON FirstMD.ApplicationID = @ApplicationID AND FirstMD.MessageID = FirstMSG.MessageID
		LEFT JOIN [dbo].[MSG_MessageDetails] AS LastMSG
		ON LastMSG.ApplicationID = @ApplicationID AND LastMSG.ID = E.MaxID
		LEFT JOIN [dbo].[MSG_MessageDetails] AS TRDUser
		ON TRDUser.ApplicationID = @ApplicationID AND 
			TRDUser.MessageID = LastMSG.MessageID AND TRDUser.UserID = @UserID
	ORDER BY B.RowNumber ASC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[MSG_GetThreadInfo]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[MSG_GetThreadInfo]
GO

CREATE PROCEDURE [dbo].[MSG_GetThreadInfo]
	@ApplicationID	uniqueidentifier,
    @UserID			UNIQUEIDENTIFIER,
    @ThreadID		UNIQUEIDENTIFIER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT	COUNT(MD.ID) AS MessagesCount, 
			SUM(CAST(MD.IsSender AS int)) AS SentCount,
			SUM(
				CAST((CASE WHEN MD.IsSender = 0 AND MD.Seen = 0 THEN 1 ELSE 0 END) AS int)
			) AS NotSeenCount
	FROM [dbo].[MSG_MessageDetails] AS MD
	WHERE MD.ApplicationID = @ApplicationID AND 
		MD.UserID = @UserID AND MD.ThreadID = @ThreadID AND MD.Deleted = 0
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[MSG_GetMessages]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[MSG_GetMessages]
GO

CREATE PROCEDURE [dbo].[MSG_GetMessages]
	@ApplicationID	uniqueidentifier,
    @UserID			UNIQUEIDENTIFIER,
    @ThreadID		UNIQUEIDENTIFIER,
    @Sent			BIT,
    @Count			INT,
    @MinID			BIGINT
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	--@Sent IS NULL --> Sent and Received Messages
	--@Sent IS NOT NULL --> @Sent = 1 --> Sent Messages
	--                  --> @Sent = 0 --> Received Messages
	
	SELECT 
		M.MessageID,
		M.Title,
		M.MessageText,
		M.SendDate,
		M.SenderUserID,
		M.ForwardedFrom,
		D.ID,
		D.IsGroup,
		D.IsSender,
		D.Seen,
		D.ThreadID,
		UN.UserName,
		UN.FirstName,
		UN.LastName,
		M.HasAttachment
	FROM (
			SELECT TOP(ISNULL(@Count, 20)) *
			FROM [dbo].[MSG_MessageDetails] AS MD
			WHERE MD.ApplicationID = @ApplicationID AND
				(@MinID IS NULL OR  MD.ID < @MinID) AND 
				MD.UserID = @UserID AND
				(MD.ThreadID IS NULL OR ThreadID = @ThreadID) AND 
				(@Sent IS NULL OR IsSender = @Sent) AND 
				MD.Deleted = 0
			ORDER BY MD.ID DESC
		)AS D
		INNER JOIN [dbo].[MSG_Messages] AS M
		ON M.ApplicationID = @ApplicationID AND M.MessageID = D.MessageID
		INNER JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND UN.UserID = M.SenderUserID
	ORDER BY D.ID ASC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[MSG_HasMessage]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[MSG_HasMessage]
GO

CREATE PROCEDURE [dbo].[MSG_HasMessage]
	@ApplicationID	uniqueidentifier,
	@ID				BIGINT,
    @UserID			UNIQUEIDENTIFIER,
    @ThreadID		UNIQUEIDENTIFIER,
    @MessageID		UNIQUEIDENTIFIER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT
		CASE
			WHEN EXISTS(
				SELECT TOP(1) ID
				FROM [dbo].[MSG_MessageDetails]
				WHERE ApplicationID = @ApplicationID AND (@ID IS NULL OR ID = @ID) AND
					UserID = @UserID AND 
					(@ThreadID IS NULL OR ThreadID = @ThreadID) AND
					(@MessageID IS NULL OR MessageID = @MessageID)
			) THEN 1
			ELSE 0
		END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[MSG_SendNewMessage]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[MSG_SendNewMessage]
GO

CREATE PROCEDURE [dbo].[MSG_SendNewMessage]
	@ApplicationID		UNIQUEIDENTIFIER,
    @UserID				UNIQUEIDENTIFIER,
    @ThreadID			UNIQUEIDENTIFIER,
    @MessageID			UNIQUEIDENTIFIER,
    @ForwardedFrom		UNIQUEIDENTIFIER,
    @Title				NVARCHAR(500),
    @MessageText		NVARCHAR(MAX),
    @IsGroup			BIT,
    @Now				DATETIME,
    @ReceiversTemp		GuidTableType readonly,
    @AttachedFilesTemp	DocFileInfoTableType readonly,
	@AddUserIDsTemp		GuidTableType readonly,
	@RemoveUserIDsTemp	GuidTableType readonly,
	@NewThreadName		NVARCHAR(500)
WITH ENCRYPTION, RECOMPILE
AS
BEGIN TRANSACTION
	SET NOCOUNT ON

	SET @NewThreadName = [dbo].[GFN_VerifyString](@NewThreadName)
	
	DECLARE @Receivers GuidTableType
	INSERT INTO @Receivers SELECT * FROM @ReceiversTemp

	DECLARE @AddUserIDs GuidTableType
	INSERT INTO @AddUserIDs SELECT * FROM @AddUserIDsTemp

	DECLARE @RemoveUserIDs GuidTableType
	INSERT INTO @RemoveUserIDs SELECT * FROM @RemoveUserIDsTemp
    
    DECLARE @AttachedFiles DocFileInfoTableType
    INSERT INTO @AttachedFiles SELECT * FROM @AttachedFilesTemp

	DECLARE @AddUsersCount int = (SELECT COUNT(*) FROM @AddUserIDs)
	DECLARE @RemoveUsersCount int = (SELECT COUNT(*) FROM @RemoveUserIDs)
	DECLARE @AttachmentsCount int = (SELECT COUNT(*) FROM @AttachedFiles)
	
	IF @IsGroup IS NULL SET @IsGroup = 0
	
	IF @ThreadID IS NOT NULL BEGIN
		SET @IsGroup = ISNULL((
			SELECT TOP(1) MD.IsGroup
			FROM [dbo].[MSG_MessageDetails] AS MD
			WHERE MD.ApplicationID = @ApplicationID AND MD.ThreadID = @ThreadID
		), @IsGroup)
	END

	IF @ThreadID IS NULL OR EXISTS (
		SELECT TOP(1) 1
		FROM [dbo].[USR_View_Users] AS U
		WHERE U.UserID = @ThreadID
	) BEGIN
		SET @NewThreadName = NULL
	END
	
	DECLARE @ReceiverUserIDs GuidTableType
	
	INSERT INTO @ReceiverUserIDs SELECT * FROM @Receivers
	
	DECLARE @Count int = (SELECT COUNT(*) FROM @ReceiverUserIDs)
	
	IF @Count = 1 SET @IsGroup = 0
	
	IF(@Count > 1) DELETE FROM @ReceiverUserIDs WHERE Value = @UserID --Farzane Added
	
	IF (@ThreadID IS NULL AND @IsGroup = 0) AND @Count = 0 BEGIN
		SELECT -1
		RETURN
	END
	
	IF @ThreadID IS NOT NULL AND @Count = 0 AND EXISTS (
		SELECT TOP(1) UserID 
		FROM [dbo].[Users_Normal] 
		WHERE ApplicationID = @ApplicationID AND UserID = @ThreadID
	) BEGIN
		INSERT INTO @ReceiverUserIDs (Value)
		VALUES (@ThreadID)
		
		SET @Count = 1
	END
	
	IF @IsGroup = 1 BEGIN
		IF @Count = 1 SET @ThreadID = (SELECT TOP(1) Ref.Value FROM @ReceiverUserIDs AS Ref)
		ELSE IF (@ThreadID IS NULL AND @Count > 0) SET @ThreadID = NEWID()
	END
	
	IF @Count = 0 BEGIN
		DECLARE @TempThreadIDs GuidTableType
		INSERT INTO @TempThreadIDs ([Value]) VALUES (@ThreadID)

		INSERT INTO @ReceiverUserIDs ([Value])
		SELECT X.UserID
		FROM [dbo].[MSG_FN_GetThreadUsers](@ApplicationID, @TempThreadIDs) AS X
		WHERE X.UserID NOT IN (@UserID)

		SET @Count = (SELECT COUNT(*) FROM @ReceiverUserIDs)
	END
	
	INSERT INTO [dbo].[MSG_Messages] (
		ApplicationID,
		MessageID,
		Title,
		MessageText,
		SenderUserID,
		SendDate,
		ForwardedFrom,
		HasAttachment
	)
	VALUES (
		@ApplicationID,
		@MessageID,
		@Title,
		@MessageText,
		@UserID,
		@Now,
		@ForwardedFrom,
		CASE WHEN @AttachmentsCount > 0 THEN 1 ELSE 0 END
	)
	
	IF @@ROWCOUNT <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	DECLARE @_Result int
	
	IF @AttachmentsCount > 0 BEGIN
		EXEC [dbo].[DCT_P_AddFiles] @ApplicationID, @MessageID, 
			N'Message', @AttachedFiles, @UserID, @Now, @_Result output
		
		IF @_Result <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	IF @ForwardedFrom IS NOT NULL BEGIN
		EXEC [dbo].[DCT_P_CopyAttachments] @ApplicationID, @ForwardedFrom, 
			@MessageID, N'Message', @UserID, @Now, @_Result output
		
		IF @_Result > 0 BEGIN
			UPDATE [dbo].[MSG_Messages]
				SET HasAttachment = 1
			WHERE ApplicationID = @ApplicationID AND MessageID = @MessageID
		END 
	END
	
	INSERT INTO [dbo].[MSG_MessageDetails](
		ApplicationID,
		UserID,
		ThreadID,
		MessageID,
		Seen,
		IsSender,
		IsGroup,
		Deleted
	)
	(
		SELECT	TOP(CASE WHEN @IsGroup = 1 THEN 1 ELSE 1000000000 END)
				@ApplicationID,
				@UserID,
				CASE WHEN @IsGroup = 0 THEN R.Value ELSE @ThreadID END,
				@MessageID,
				1,
				1,
				@IsGroup,
				0
		FROM @ReceiverUserIDs AS R
		WHERE @AddUsersCount = 0 AND @RemoveUsersCount = 0 AND ISNULL(@NewThreadName, N'') = N''
		
		UNION ALL
		
		SELECT	@ApplicationID,
				R.Value,
				CASE WHEN @IsGroup = 0 THEN @UserID ELSE @ThreadID END,
				@MessageID,
				0,
				0,
				@IsGroup,
				0
		FROM @ReceiverUserIDs AS R
		WHERE @AddUsersCount = 0 AND @RemoveUsersCount = 0 AND ISNULL(@NewThreadName, N'') = N''

		UNION ALL

		SELECT	@ApplicationID,
				R.UserID,
				CASE WHEN @IsGroup = 0 THEN @UserID ELSE @ThreadID END,
				@MessageID,
				0,
				0,
				@IsGroup,
				0
		FROM (
				SELECT X.[Value] AS UserID
				FROM @ReceiverUserIDs AS X
				WHERE X.[Value] NOT IN (SELECT A.[Value] FROM @RemoveUserIDs AS A)

				UNION

				SELECT @UserID AS UserID
				WHERE @UserID NOT IN (SELECT A.[Value] FROM @RemoveUserIDs AS A)

				UNION

				SELECT A.[Value] AS UserID
				FROM @AddUserIDs AS A
			) AS R
		WHERE @AddUsersCount > 0 OR @RemoveUsersCount > 0 OR ISNULL(@NewThreadName, N'') <> N''
	)

	DECLARE @LastCreatedID bigint = @@IDENTITY;
	
	IF @@ROWCOUNT <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END

	IF ISNULL(@NewThreadName, N'') <> N'' BEGIN
		UPDATE TN
		SET [Name] = @NewThreadName,
			LastModifierUserID = @UserID,
			LastModificationDate = @Now
		FROM [dbo].[MSG_ThreadNames] AS TN
		WHERE TN.ApplicationID = @ApplicationID AND TN.ThreadID = @ThreadID

		INSERT INTO [dbo].[MSG_ThreadNames] (
			ApplicationID,
			ThreadID,
			[Name],
			LastModifierUserID,
			LastModificationDate
		)
		SELECT	@ApplicationID,
				@ThreadID,
				@NewThreadName,
				@UserID,
				@Now
		WHERE NOT EXISTS (
			SELECT TOP(1) 1
			FROM [dbo].[MSG_ThreadNames] AS TN
			WHERE TN.ApplicationID = @ApplicationID AND TN.ThreadID = @ThreadID
		)
	END
	
	SELECT @LastCreatedID - @Count
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[MSG_BulkSendMessage]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[MSG_BulkSendMessage]
GO

CREATE PROCEDURE [dbo].[MSG_BulkSendMessage]
	@ApplicationID	uniqueidentifier,
    @MessagesTemp	MessageTableType readonly,
    @ReceiversTemp	GuidPairTableType readonly,
    @Now			DATETIME
WITH ENCRYPTION, RECOMPILE
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE @Messages MessageTableType
	INSERT INTO @Messages SELECT * FROM @MessagesTemp
    
    DECLARE @Receivers GuidPairTableType
    INSERT INTO @Receivers SELECT * FROM @ReceiversTemp
	
	INSERT INTO [dbo].[MSG_Messages](
		ApplicationID,
		MessageID,
		Title,
		MessageText,
		SenderUserID,
		SendDate,
		HasAttachment
	)
	SELECT	@ApplicationID,
			M.MessageID,
			M.Title,
			M.MessageText,
			M.SenderUserID,
			@Now,
			0
	FROM @Messages AS M
	WHERE M.MessageID IN (SELECT DISTINCT R.FirstValue FROM @Receivers AS R)
	
	IF @@ROWCOUNT <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	INSERT INTO [dbo].[MSG_MessageDetails](
		ApplicationID,
		UserID,
		ThreadID,
		MessageID,
		Seen,
		IsSender,
		IsGroup,
		Deleted
	)
	SELECT *
	FROM (
			SELECT	@ApplicationID AS ApplicationID,
					M.SenderUserID,
					R.SecondValue,
					M.MessageID,
					1 AS Seen,
					1 AS IsSender,
					0 AS IsGroup,
					0 AS Deleted
			FROM @Messages AS M
				INNER JOIN @Receivers AS R
				ON R.FirstValue = M.MessageID
			
			UNION ALL
			
			SELECT	@ApplicationID,
					R.SecondValue,
					M.SenderUserID,
					M.MessageID,
					0,
					0,
					0,
					0
			FROM @Messages AS M
				INNER JOIN @Receivers AS R
				ON R.FirstValue = M.MessageID
		) AS Ref
	ORDER BY Ref.IsSender DESC
	
	IF @@ROWCOUNT <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	SELECT @@IDENTITY
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[MSG_GetThreadUsers]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[MSG_GetThreadUsers]
GO

CREATE PROCEDURE [dbo].[MSG_GetThreadUsers]
	@ApplicationID	uniqueidentifier,
	@UserID			UNIQUEIDENTIFIER,
    @ThreadIDsTemp	GuidTableType readonly,
	@Count			INT,
	@LastID			INT
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @ThreadIDs GuidTableType
	INSERT INTO @ThreadIDs SELECT * FROM @ThreadIDsTemp

	;WITH Threads AS (
		SELECT	Ref.RowNumber, Ref.ThreadID, Ref.UserID
		FROM (
				SELECT	ROW_NUMBER() OVER (PARTITION BY X.ThreadID ORDER BY X.SequenceNumber ASC) AS RowNumber,
						X.ThreadID,
						X.UserID
				FROM (
						SELECT	U.SequenceNumber,
								U.ThreadID,
								U.UserID
						FROM [dbo].[MSG_FN_GetThreadUsers](@ApplicationID, @ThreadIDs) AS U
						WHERE @UserID IS NULL OR U.UserID NOT IN (@UserID)
					) AS X
			) AS Ref
		WHERE Ref.RowNumber > ISNULL(@LastID, 0) AND Ref.RowNumber <= (ISNULL(@LastID, 0) + ISNULL(@Count, 3))
	),
	Total AS (
		SELECT COUNT(T.ThreadID) AS [Value]
		FROM Threads AS T
	)
	SELECT	Y.ThreadID, 
			Y.UserID, 
			UN.UserName, 
			UN.FirstName, 
			UN.LastName,
			(T.[Value] - Y.RowNumber + 1) AS RevRowNumber
	FROM Threads AS Y
		INNER JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND UN.UserID = Y.UserID
		CROSS JOIN Total AS T
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[MSG_RemoveMessages]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[MSG_RemoveMessages]
GO

CREATE PROCEDURE [dbo].[MSG_RemoveMessages]
	@ApplicationID	uniqueidentifier,
    @UserID			UNIQUEIDENTIFIER,
    @ThreadID		UNIQUEIDENTIFIER,
    @ID				BIGINT
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	UPDATE [dbo].[MSG_MessageDetails]
		SET Deleted = 1
	WHERE ApplicationID = @ApplicationID AND (@ID IS NOT NULL AND ID = @ID) OR  
		(@ID IS NULL AND UserID = @UserID AND ThreadID = @ThreadID)
		
		
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[MSG_SetMessagesAsSeen]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[MSG_SetMessagesAsSeen]
GO

CREATE PROCEDURE [dbo].[MSG_SetMessagesAsSeen]
	@ApplicationID	uniqueidentifier,
    @UserID			uniqueidentifier,
    @ThreadID		uniqueidentifier,
    @Now			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	IF @UserID IS NOT NULL AND @ThreadID IS NOT NULL BEGIN
		UPDATE MD
			SET Seen = 1,
				ViewDate = ISNULL(ViewDate, @Now)
		FROM [dbo].[MSG_MessageDetails] AS MD
		WHERE MD.ApplicationID = @ApplicationID AND
			MD.UserID = @UserID AND MD.ThreadID = @ThreadID AND ViewDate IS NULL
		
		SELECT 1
	END
	ELSE SELECT 0
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[MSG_GetNotSeenMessagesCount]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[MSG_GetNotSeenMessagesCount]
GO

CREATE PROCEDURE [dbo].[MSG_GetNotSeenMessagesCount]
	@ApplicationID	uniqueidentifier,
    @UserID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT COUNT(MD.ID)
	FROM [dbo].[MSG_MessageDetails] AS MD
	WHERE MD.ApplicationID = @ApplicationID AND
		MD.UserID = @UserID AND MD.IsSender = 0 AND MD.Seen = 0 AND MD.Deleted = 0
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[MSG_GetMessageReceivers]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[MSG_GetMessageReceivers]
GO

CREATE PROCEDURE [dbo].[MSG_GetMessageReceivers]
	@ApplicationID	uniqueidentifier,
    @strMessageIDs	NVARCHAR(MAX),
    @delimiter		CHAR,
	@Count			INT,
	@LastID			INT
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @MessageIDs GuidTableType

	INSERT INTO @MessageIDs
	SELECT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strMessageIDs, @delimiter) AS Ref
	
	;WITH Y AS (
		SELECT *
		FROM (
				SELECT  ROW_NUMBER() OVER (PARTITION BY MD.MessageID ORDER BY MD.ID DESC) AS RowNumber, 
						ROW_NUMBER() OVER (PARTITION BY MD.MessageID ORDER BY MD.ID ASC) AS RevRowNumber,
						MD.MessageID, MD.UserID
				FROM @MessageIDs AS R
					INNER JOIN [dbo].[MSG_MessageDetails] AS MD
					ON MD.MessageID = R.Value
				WHERE MD.ApplicationID = @ApplicationID AND MD.IsSender = 0
			) AS Ref
		WHERE Ref.RowNumber > ISNULL(@LastID, 0) AND Ref.RowNumber <= (ISNULL(@LastID, 0) + ISNULL(@Count, 3))
	)
	SELECT	Y.MessageID, 
			Y.UserID, 
			UN.UserName, 
			UN.FirstName, 
			UN.LastName,
			Y.RevRowNumber
	FROM Y
		INNER JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND UN.UserID = Y.UserID
END

Go


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[MSG_GetForwardedMessages]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[MSG_GetForwardedMessages]
GO

CREATE PROCEDURE [dbo].[MSG_GetForwardedMessages]
	@ApplicationID	uniqueidentifier,
	@MessageID		UNIQUEIDENTIFIER
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @hierarchyMessages AS TABLE (
		MessageID UNIQUEIDENTIFIER,
		IsGroup BIT,
		ForwardedFrom UNIQUEIDENTIFIER,
		[Level] INT
	)
	
	;WITH hierarchy (MessageID, ForwardedFrom, [Level])
	AS
	(
		SELECT m.MessageID AS MessageID, ForwardedFrom, 0 AS [Level]
		FROM [dbo].[MSG_Messages] as m
		WHERE m.ApplicationID = @ApplicationID AND MessageID = @MessageID
		
		UNION ALL
		
		SELECT m.MessageID AS MessageID, m.ForwardedFrom , [Level] + 1
		FROM [dbo].[MSG_Messages] AS m
			INNER JOIN hierarchy AS HR
			ON m.MessageID = HR.ForwardedFrom
		WHERE m.ApplicationID = @ApplicationID AND m.MessageID <> HR.MessageID
	)
	INSERT INTO @hierarchyMessages(
		MessageID, 
		IsGroup, 
		ForwardedFrom, 
		[Level]
	)
	SELECT 
		Ref.MessageID AS MessageID, 
		MD.IsGroup, 
		Ref.ForwardedFrom,
		Ref.[Level]
	FROM (
			SELECT hm.MessageID, hm.ForwardedFrom, hm.[Level] , MAX(MD.ID) AS ID
			FROM hierarchy AS hm
				INNER JOIN [dbo].[MSG_MessageDetails] AS MD
				ON MD.ApplicationID = @ApplicationID AND MD.MessageID = hm.MessageID
			GROUP BY hm.MessageID, hm.ForwardedFrom, hm.[Level]
		) AS Ref
		INNER JOIN [dbo].[MSG_MessageDetails] AS MD
		ON MD.ApplicationID = @ApplicationID AND MD.ID = Ref.ID
	
	SELECT 
		M.MessageID,
		M.MessageText,
		M.Title,
		M.SendDate,
		M.HasAttachment,
		H.ForwardedFrom,
		H.[Level],
		H.IsGroup,
		M.SenderUserID,
		UN.UserName AS SenderUserName,
		UN.FirstName AS SenderFirstName,
		UN.LastName AS SenderLastName
	FROM @hierarchyMessages AS H
		INNER JOIN [dbo].[MSG_Messages] AS M
		ON M.ApplicationID = @ApplicationID AND M.MessageID = H.MessageID
		INNER JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND UN.UserID = M.SenderUserID
	ORDER BY H.[Level] ASC
END

GO

