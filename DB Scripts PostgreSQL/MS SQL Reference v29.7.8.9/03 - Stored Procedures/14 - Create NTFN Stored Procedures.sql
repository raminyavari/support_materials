USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[NTFN_SendNotification]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[NTFN_SendNotification]
GO

CREATE PROCEDURE [dbo].[NTFN_SendNotification]
	@ApplicationID	uniqueidentifier,
    @UsersTemp		GuidStringTableType readonly,
    @SubjectID 		uniqueidentifier,
    @RefItemID 		uniqueidentifier,
    @SubjectType	varchar(20),
    @SubjectName	nvarchar(2000),
    @Action			varchar(20),
    @SenderUserID 	uniqueidentifier,
    @SendDate		datetime,
    @Description	nvarchar(2000),
    @Info			nvarchar(2000)
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Users GuidStringTableType
	INSERT INTO @Users SELECT * FROM @UsersTemp
	
	DECLARE @VU GuidStringTableType
	INSERT INTO @VU(FirstValue, SecondValue)
	SELECT Ref.FirstValue, Ref.SecondValue
	FROM @Users AS Ref
		INNER JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND UN.UserID = Ref.FirstValue

	INSERT INTO [dbo].[NTFN_Notifications](
		ApplicationID,
		UserID,
		SubjectID,
		RefItemID,
		SubjectType,
		SubjectName,
		[Action],
		SenderUserID,
		SendDate,
		[Description],
		Info,
		UserStatus,
		Seen,
		Deleted
	)
	SELECT @ApplicationID, Ref.FirstValue, @SubjectID, @RefItemID, @SubjectType, 
		@SubjectName, @Action, @SenderUserID, @SendDate, @Description, 
		@Info, Ref.SecondValue, 0, 0
	FROM @VU AS Ref
	WHERE Ref.FirstValue <> @SenderUserID AND 
		NOT EXISTS(
			SELECT TOP(1) * 
			FROM [dbo].[NTFN_Notifications]
			WHERE ApplicationID = @ApplicationID AND UserID = Ref.FirstValue AND 
				SubjectID = @SubjectID AND RefItemID = @RefItemID AND 
				[Action] = @Action AND SenderUserID = @SenderUserID AND Deleted = 0
		)
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[NTFN_SetNotificationsAsSeen]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[NTFN_SetNotificationsAsSeen]
GO

CREATE PROCEDURE [dbo].[NTFN_SetNotificationsAsSeen]
	@ApplicationID	uniqueidentifier,
	@UserID			uniqueidentifier,
    @strIDs			varchar(max),
    @delimiter		char,
    @ViewDate		datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @IDs BigIntTableType
	INSERT INTO @IDs
	SELECT DISTINCT Ref.Value 
	FROM [dbo].[GFN_StrToBigIntTable](@strIDs, @delimiter) AS Ref
	
	UPDATE N
		SET Seen = 1,
			ViewDate = @ViewDate
	FROM @IDs AS Ref
		INNER JOIN [dbo].[NTFN_Notifications] AS N
		ON N.[ID] = Ref.Value
	WHERE N.ApplicationID = @ApplicationID AND N.UserID = @UserID AND N.Seen = 0
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[NTFN_SetUserNotificationsAsSeen]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[NTFN_SetUserNotificationsAsSeen]
GO

CREATE PROCEDURE [dbo].[NTFN_SetUserNotificationsAsSeen]
	@ApplicationID	uniqueidentifier,
    @UserID			uniqueidentifier,
    @ViewDate		datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	UPDATE [dbo].[NTFN_Notifications]
		SET Seen = 1,
			ViewDate = @ViewDate
	WHERE ApplicationID = @ApplicationID AND UserID = @UserID AND Seen = 0
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[NTFN_ArithmeticDeleteNotification]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[NTFN_ArithmeticDeleteNotification]
GO

CREATE PROCEDURE [dbo].[NTFN_ArithmeticDeleteNotification]
	@ApplicationID	uniqueidentifier,
    @ID				bigint,
    @UserID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	UPDATE [dbo].[NTFN_Notifications]
		SET Deleted = 1
	WHERE ApplicationID = @ApplicationID AND ID = @ID AND UserID = @UserID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[NTFN_ArithmeticDeleteNotifications]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[NTFN_ArithmeticDeleteNotifications]
GO

CREATE PROCEDURE [dbo].[NTFN_ArithmeticDeleteNotifications]
	@ApplicationID	uniqueidentifier,
    @strSubjectIDs	varchar(max),
    @strRefItemIDs	varchar(max),
    @SenderUserID	uniqueidentifier,
    @strActions		varchar(max),
    @delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @SubjectIDs GuidTableType, @RefItemIDs GuidTableType
	
	INSERT INTO @SubjectIDs
	SELECT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strSubjectIDs, @delimiter) AS Ref
	
	INSERT INTO @RefItemIDs
	SELECT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strRefItemIDs, @delimiter) AS Ref
	
	DECLARE @Actions StringTableType
	INSERT INTO @Actions
	SELECT Ref.Value FROM [dbo].[GFN_StrToStringTable](@strActions, @delimiter) AS Ref
	
	DECLARE @ActionsCount int = (SELECT COUNT(*) FROM @Actions),
		@SubjectIDsCount int = (SELECT COUNT(*) FROM @SubjectIDs),
		@RefItemIDsCount int = (SELECT COUNT(*) FROM @RefItemIDs)
	
	IF @SubjectIDsCount > 0 AND @RefItemIDsCount > 0 BEGIN
		UPDATE N
			SET Deleted = 1
		FROM @SubjectIDs AS S
			INNER JOIN [dbo].[NTFN_Notifications] AS N
			ON N.[SubjectID] = S.Value
			INNER JOIN @RefItemIDs AS R
			ON R.Value = N.[RefItemID]
		WHERE N.ApplicationID = @ApplicationID AND
			(@SenderUserID IS NULL OR SenderUserID = @SenderUserID) AND
			(@ActionsCount = 0 OR [Action] IN(SELECT * FROM @Actions))
	END
	ELSE IF @SubjectIDsCount > 0 BEGIN
		UPDATE N
			SET Deleted = 1
		FROM @SubjectIDs AS S
			INNER JOIN [dbo].[NTFN_Notifications] AS N
			ON N.[SubjectID] = S.Value
		WHERE N.ApplicationID = @ApplicationID AND 
			(@SenderUserID IS NULL OR SenderUserID = @SenderUserID) AND
			(@ActionsCount = 0 OR [Action] IN(SELECT * FROM @Actions))
	END
	ELSE IF @RefItemIDsCount > 0 BEGIN
	select @SenderUserID
		UPDATE N
			SET Deleted = 1
		FROM @RefItemIDs AS R
			INNER JOIN [dbo].[NTFN_Notifications] AS N
			ON N.[RefItemID] = R.Value
		WHERE N.ApplicationID = @ApplicationID AND 
			(@SenderUserID IS NULL OR N.SenderUserID = @SenderUserID) AND
			(@ActionsCount = 0 OR N.[Action] IN(SELECT * FROM @Actions))
	END
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[NTFN_GetUserNotificationsCount]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[NTFN_GetUserNotificationsCount]
GO

CREATE PROCEDURE [dbo].[NTFN_GetUserNotificationsCount]
	@ApplicationID	uniqueidentifier,
    @UserID			uniqueidentifier,
    @Seen			bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT COUNT(ID)
	FROM [dbo].[NTFN_Notifications]
	WHERE ApplicationID = @ApplicationID AND 
		UserID = @UserID AND (@Seen IS NULL OR Seen = @Seen) AND Deleted = 0
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[NTFN_P_GetNotificationsByIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[NTFN_P_GetNotificationsByIDs]
GO

CREATE PROCEDURE [dbo].[NTFN_P_GetNotificationsByIDs]
	@ApplicationID	uniqueidentifier,
    @IDsTemp		BigIntTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @IDs BigIntTableType
	INSERT INTO @IDs SELECT * FROM @IDsTemp

	SELECT NTFN.ID AS NotificationID,
		   NTFN.UserID AS UserID,
		   NTFN.SubjectID AS SubjectID,
		   NTFN.RefItemID AS RefItemID,
		   NTFN.SubjectName AS SubjectName,
		   NTFN.SubjectType AS SubjectType,
		   NTFN.SenderUserID AS SenderUserID,
		   UN.UserName AS SenderUserName,
		   UN.FirstName AS SenderFirstName,
		   UN.LastName AS SenderLastName,
		   NTFN.SendDate AS SendDate,
		   NTFN.[Action] AS [Action],
		   NTFN.[Description] AS [Description],
		   NTFN.Info AS Info,
		   NTFN.UserStatus AS UserStatus,
		   NTFN.Seen AS Seen,
		   NTFN.ViewDate AS ViewDate
	FROM @IDs AS Ref
		INNER JOIN [dbo].[NTFN_Notifications] AS NTFN
		ON NTFN.ApplicationID = @ApplicationID AND NTFN.ID = Ref.Value
		LEFT JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND UN.UserID = NTFN.UserID
	ORDER BY NTFN.Seen ASC, NTFN.ID DESC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[NTFN_GetUserNotifications]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[NTFN_GetUserNotifications]
GO

CREATE PROCEDURE [dbo].[NTFN_GetUserNotifications]
	@ApplicationID	uniqueidentifier,
    @UserID			uniqueidentifier,
    @Seen			bit,
    @LastNotSeenID	bigint,
    @LastSeenID		bigint,
    @LastViewDate	datetime,
    @LowerDateLimit datetime,
    @UpperDateLimit datetime,
    @Count			int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @IDs BigIntTableType
	
	INSERT INTO @IDs
	SELECT TOP(ISNULL(@Count, 20)) ID
	FROM [dbo].[NTFN_Notifications]
	WHERE ApplicationID = @ApplicationID AND UserID = @UserID AND
		(@LowerDateLimit IS NULL OR SendDate > @LowerDateLimit) AND
		(@UpperDateLimit IS NULL OR SendDate < @UpperDateLimit) AND
		(
			(
				(ViewDate IS NULL OR @LastViewDate IS NULL) AND 
				(@LastNotSeenID IS NULL OR ID < @LastNotSeenID)
			) OR
			(
				(ViewDate < @LastViewDate) AND 
				(@LastSeenID IS NULL OR ID < @LastSeenID)
			)
		) AND
		(@Seen IS NULL OR Seen = @Seen) AND Deleted = 0
	ORDER BY Seen ASC, ID DESC
	
	EXEC [dbo].[NTFN_P_GetNotificationsByIDs] @ApplicationID, @IDs
END

GO


-- Dashboard Procedures

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[NTFN_P_SendDashboards]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[NTFN_P_SendDashboards]
GO

CREATE PROCEDURE [dbo].[NTFN_P_SendDashboards]
	@ApplicationID	uniqueidentifier,
    @DashboardsTemp	DashboardTableType readonly,
    @_Result		int output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Dashboards DashboardTableType
	INSERT INTO @Dashboards SELECT * FROM @DashboardsTemp
	
	INSERT INTO [dbo].[NTFN_Dashboards](
		ApplicationID,
		UserID,
		NodeID,
		RefItemID,
		[Type],
		SubType,
		Info,
		Removable,
		SenderUserID,
		SendDate,
		ExpirationDate,
		Seen,
		ViewDate,
		Done,
		ActionDate,
		Deleted
	)
	SELECT DISTINCT
		@ApplicationID,
		Ref.UserID,
		Ref.NodeID,
		ISNULL(Ref.RefItemID, Ref.NodeID),
		Ref.[Type],
		Ref.SubType,
		ref.Info,
		ISNULL(Ref.Removable, 0),
		Ref.SenderUserID,
		Ref.SendDate,
		Ref.ExpirationDate,
		ISNULL(Ref.Seen, 0),
		Ref.ViewDate,
		ISNULL(Ref.Done, 0),
		Ref.ActionDate,
		0
	FROM @Dashboards AS Ref
		LEFT JOIN [dbo].[NTFN_Dashboards] AS D
		ON D.ApplicationID = @ApplicationID AND 
			D.UserID = Ref.UserID AND D.NodeID = Ref.NodeID AND 
			D.RefItemID = Ref.RefItemID AND D.[Type] = Ref.[Type] AND 
			((D.SubType IS NULL AND Ref.SubType IS NULL) OR D.SubType = Ref.SubType) AND
			Ref.Removable = D.Removable AND D.Done = 0 AND D.Deleted = 0
	WHERE D.ID IS NULL
	
	SET @_Result = 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[NTFN_SetDashboardsAsSeen]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[NTFN_SetDashboardsAsSeen]
GO

CREATE PROCEDURE [dbo].[NTFN_SetDashboardsAsSeen]
	@ApplicationID		uniqueidentifier,
	@UserID				uniqueidentifier,
    @strDashboardIDs	varchar(max),
    @delimiter			char,
    @Now				datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @DashboardIDs BigIntTableType
	
	INSERT INTO @DashboardIDs
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToBigIntTable](@strDashboardIDs, @delimiter) AS Ref
	
	UPDATE D
		SET Seen = 1,
			ViewDate = @Now
	FROM @DashboardIDs AS Ref
		INNER JOIN [dbo].[NTFN_Dashboards] AS D
		ON D.ID = Ref.Value
	WHERE D.ApplicationID = @ApplicationID AND D.UserID = @UserID
		
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[NTFN_P_SetDashboardsAsNotSeen]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[NTFN_P_SetDashboardsAsNotSeen]
GO

CREATE PROCEDURE [dbo].[NTFN_P_SetDashboardsAsNotSeen]
	@ApplicationID	uniqueidentifier,
    @UserID			uniqueidentifier,
    @NodeID			uniqueidentifier,
    @RefItemID		uniqueidentifier,
    @Type			varchar(20),
    @SubType		varchar(20),
    @_Result		int output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM [dbo].[NTFN_Dashboards]
		WHERE ApplicationID = @ApplicationID AND
			(@UserID IS NULL OR UserID = @UserID) AND
			(@NodeID IS NULL OR NodeID = @NodeID) AND 
			(@RefItemID IS NULL OR RefItemID = @RefItemID) AND 
			(@Type IS NULL OR [Type] = @Type) AND
			(@SubType IS NULL OR SubType = @SubType) AND Done = 0 AND Deleted = 0
		) BEGIN
		UPDATE [dbo].[NTFN_Dashboards]
			SET Seen = 0
		WHERE ApplicationID = @ApplicationID AND 
			(@UserID IS NULL OR UserID = @UserID) AND
			(@NodeID IS NULL OR NodeID = @NodeID) AND 
			(@RefItemID IS NULL OR RefItemID = @RefItemID) AND 
			(@Type IS NULL OR [Type] = @Type) AND
			(@SubType IS NULL OR SubType = @SubType) AND Done = 0 AND Deleted = 0
			
		SET @_Result = @@ROWCOUNT
	END
	ELSE BEGIN
		SET @_Result = 1
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[NTFN_P_SetDashboardsAsDone]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[NTFN_P_SetDashboardsAsDone]
GO

CREATE PROCEDURE [dbo].[NTFN_P_SetDashboardsAsDone]
	@ApplicationID	uniqueidentifier,
    @UserID			uniqueidentifier,
    @NodeID			uniqueidentifier,
    @RefItemID		uniqueidentifier,
    @Type			varchar(20),
    @SubType		varchar(20),
    @Now			datetime,
    @_Result		int output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM [dbo].[NTFN_Dashboards]
		WHERE ApplicationID = @ApplicationID AND 
			(@UserID IS NULL OR UserID = @UserID) AND
			(@NodeID IS NULL OR NodeID = @NodeID) AND 
			(@RefItemID IS NULL OR RefItemID = @RefItemID) AND 
			(@Type IS NULL OR [Type] = @Type) AND
			(@SubType IS NULL OR SubType = @SubType) AND Done = 0 AND Deleted = 0
		) BEGIN
		
		UPDATE [dbo].[NTFN_Dashboards]
			SET Done = 1,
				ActionDate = @Now
		WHERE ApplicationID = @ApplicationID AND 
			(@UserID IS NULL OR UserID = @UserID) AND
			(@NodeID IS NULL OR NodeID = @NodeID) AND 
			(@RefItemID IS NULL OR RefItemID = @RefItemID) AND 
			(@Type IS NULL OR [Type] = @Type) AND
			(@SubType IS NULL OR SubType = @SubType) AND Done = 0 AND Deleted = 0
			
		SET @_Result = @@ROWCOUNT
	END
	ELSE BEGIN
		SET @_Result = 1
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[NTFN_P_ArithmeticDeleteDashboards]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[NTFN_P_ArithmeticDeleteDashboards]
GO

CREATE PROCEDURE [dbo].[NTFN_P_ArithmeticDeleteDashboards]
	@ApplicationID	uniqueidentifier,
    @UserID			uniqueidentifier,
    @NodeID			uniqueidentifier,
    @RefItemID		uniqueidentifier,
    @Type			varchar(20),
    @SubType		varchar(20),
    @_Result		int output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM [dbo].[NTFN_Dashboards]
		WHERE ApplicationID = @ApplicationID AND
			(@UserID IS NULL OR UserID = @UserID) AND
			(@NodeID IS NULL OR NodeID = @NodeID) AND 
			(@RefItemID IS NULL OR RefItemID = @RefItemID) AND 
			(@Type IS NULL OR [Type] = @Type) AND 
			(@SubType IS NULL OR SubType = @SubType) AND Done = 0 AND Deleted = 0
		) BEGIN
		
		UPDATE [dbo].[NTFN_Dashboards]
			SET Deleted = 1
		WHERE ApplicationID = @ApplicationID AND 
			(@UserID IS NULL OR UserID = @UserID) AND
			(@NodeID IS NULL OR NodeID = @NodeID) AND 
			(@RefItemID IS NULL OR RefItemID = @RefItemID) AND 
			(@SubType IS NULL OR SubType = @SubType) AND Done = 0 AND Deleted = 0
			
		SET @_Result = @@ROWCOUNT
	END
	ELSE BEGIN
		SET @_Result = 1
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[NTFN_ArithmeticDeleteDashboards]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[NTFN_ArithmeticDeleteDashboards]
GO

CREATE PROCEDURE [dbo].[NTFN_ArithmeticDeleteDashboards]
	@ApplicationID		uniqueidentifier,
	@UserID				uniqueidentifier,
    @strDashboardIDs	varchar(max),
    @delimiter			char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @DashboardIDs BigIntTableType
	
	INSERT INTO @DashboardIDs
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToBigIntTable](@strDashboardIDs, @delimiter) AS Ref
	
	UPDATE D
		SET Deleted = 1
	FROM @DashboardIDs AS Ref
		INNER JOIN [dbo].[NTFN_Dashboards] AS D
		ON D.ID = Ref.Value
	WHERE D.ApplicationID = @ApplicationID AND D.UserID = @UserID
		
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[NTFN_GetDashboardsCount]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[NTFN_GetDashboardsCount]
GO

CREATE PROCEDURE [dbo].[NTFN_GetDashboardsCount]
	@ApplicationID		uniqueidentifier,
	@UserID				uniqueidentifier,
	@NodeTypeID			uniqueidentifier,
	@NodeID				uniqueidentifier,
	@NodeAdditionalID	varchar(50),
	@Type				varchar(50)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF @NodeID IS NOT NULL SET @NodeTypeID = NULL
	IF @NodeID IS NOT NULL OR @NodeAdditionalID = N'' SET @NodeAdditionalID = NULL

	DECLARE @Results TABLE (SeenOrder int, ID bigint, UserID uniqueidentifier, 
		NodeID uniqueidentifier, NodeAdditionalID varchar(50), NodeName nvarchar(255), 
		NodeTypeID uniqueidentifier, NodeType nvarchar(255), [Type] varchar(50), SubType nvarchar(500), 
		WFState nvarchar(1000), Removable bit, SenderUserID uniqueidentifier, SendDate datetime, 
		ExpirationDate datetime, Seen bit, ViewDate datetime, Done bit, ActionDate datetime, 
		InWorkFlow bit, DoneAndInWorkFlow int, DoneAndNotInWorkFlow int,
		PRIMARY KEY CLUSTERED(nodeid, [type], id))


	INSERT INTO @Results (SeenOrder, ID, UserID, NodeID, NodeAdditionalID, NodeName, 
		NodeTypeID, NodeType, [Type], SubType, WFState, Removable, SenderUserID, SendDate, 
		ExpirationDate, Seen, ViewDate, Done, ActionDate)
	SELECT
		CASE WHEN D.Seen = 0 THEN 0 ELSE 1 END AS SeenOrder,
		D.ID, 
		D.UserID, 
		D.NodeID, 
		ND.NodeAdditionalID, 
		ISNULL(ND.NodeName, Q.Title) AS NodeName,
		ND.NodeTypeID,
		ND.TypeName AS NodeType, 
		D.[Type], 
		D.SubType, 
		ND.WFState, 
		D.Removable,
		D.SenderUserID, 
		D.SendDate, 
		D.ExpirationDate,
		D.Seen, 
		D.ViewDate, 
		D.Done, 
		D.ActionDate
	FROM [dbo].[NTFN_Dashboards] AS D
		LEFT JOIN [dbo].[CN_View_Nodes_Normal] AS ND
		ON ND.ApplicationID = @ApplicationID AND 
			ND.NodeID = D.NodeID AND ND.Deleted = 0
		LEFT JOIN [dbo].[QA_Questions] AS Q
		ON Q.ApplicationID = @ApplicationID AND 
			Q.QuestionID = D.NodeID AND Q.Deleted = 0
	WHERE D.ApplicationID = @ApplicationID AND D.Deleted = 0 AND
		(ND.NodeID IS NOT NULL OR Q.QuestionID IS NOT NULL) AND
		(@UserID IS NULL OR D.UserID = @UserID) AND 
		(@NodeID IS NULL OR D.NodeID = @NodeID) AND
		(@NodeTypeID IS NULL OR ND.NodeTypeID = @NodeTypeID) AND
		(@NodeAdditionalID IS NULL OR ND.NodeAdditionalID = @NodeAdditionalID) AND
		(@Type IS NULL OR D.[Type] = @Type)
			
			
	-- Remove Invalid WorkFlow Items
	IF ISNULL(@Type, N'') = N'' OR @Type = N'WorkFlow' BEGIN
		DELETE R
		FROM @Results AS R
			LEFT JOIN [dbo].[WF_WorkFlowOwners] AS WO
			ON WO.ApplicationID = @ApplicationID AND WO.NodeTypeID = R.NodeTypeID AND WO.Deleted = 0
			LEFT JOIN [dbo].[CN_Services] AS S
			ON S.ApplicationID = @ApplicationID AND S.NodeTypeID = R.NodeTypeID
		WHERE R.NodeTypeID IS NOT NULL AND R.[Type] = N'WorkFlow' AND 
			(WO.WorkFlowID IS NULL OR S.IsKnowledge = 1)
	END
	-- end of Remove Invalid WorkFlow Items


	-- Remove Invalid Knowledge Items
	IF ISNULL(@Type, N'') = N'' OR @Type = N'Knowledge' BEGIN
		DELETE R
		FROM @Results AS R
			LEFT JOIN [dbo].[CN_Services] AS S
			ON S.ApplicationID = @ApplicationID AND S.NodeTypeID = R.NodeTypeID
		WHERE R.NodeTypeID IS NOT NULL AND R.[Type] = N'Knowledge' AND ISNULL(S.IsKnowledge, 0) = 0
	END
	-- end of Remove Invalid Knowledge Items


	-- Remove Invalid Wiki Items
	IF ISNULL(@Type, N'') = N'' OR @Type = N'Wiki' BEGIN
		DELETE R
		FROM @Results AS R
			LEFT JOIN [dbo].[CN_Extensions] AS S
			ON S.ApplicationID = @ApplicationID AND S.OwnerID = R.NodeTypeID AND 
				S.Extension = N'Wiki' AND S.Deleted = 0
		WHERE R.NodeTypeID IS NOT NULL AND R.[Type] = N'Wiki' AND S.OwnerID IS NULL
	END
	-- end of Remove Invalid Wiki Items


	UPDATE R
		SET InWorkFlow = 1
	FROM @Results AS R
		INNER JOIN (
			SELECT R.NodeID, R.[Type]
			FROM @Results AS R
				INNER JOIN [dbo].[NTFN_Dashboards] AS D
				ON D.ApplicationID = @ApplicationID AND R.NodeID IS NOT NULL AND R.[Type] IN (N'WorkFlow', N'Knowledge') AND
					D.NodeID = R.NodeID AND D.[Type] = R.[Type] AND D.Done = 0 AND D.Deleted = 0 AND ISNULL(D.Removable, 0) = 0
			GROUP BY R.NodeID, R.[Type]
		) AS X
		ON X.NodeID = R.NodeID AND X.[Type] = R.[Type]


	UPDATE X
		SET DoneAndInWorkFlow = A.DoneAndInWorkFlow,
			DoneAndNotInWorkFlow = A.DoneAndNotInWorkFlow
	FROM @Results AS X
		INNER JOIN (
			SELECT U.UserID, U.[Type], U.NodeTypeID,
				COUNT(DISTINCT (CASE WHEN U.DoneAndInWorkFlow = 1 THEN U.NodeID ELSE NULL END)) AS DoneAndInWorkFlow,
				COUNT(DISTINCT (CASE WHEN U.DoneAndNotInWorkFlow = 1 THEN U.NodeID ELSE NULL END)) AS DoneAndNotInWorkFlow
			FROM (
					SELECT R.UserID, R.[Type], R.NodeID, R.NodeTypeID, 
						CASE 
							WHEN MAX(CAST(ISNULL(R.Done, 0) AS int)) = 1 AND
								ISNULL(MAX(CAST(R.InWorkFlow AS int)), 0) > 0 THEN 1
							ELSE 0
						END AS DoneAndInWorkFlow,
						CASE 
							WHEN MAX(CAST(ISNULL(R.Done, 0) AS int)) = 1 AND
								ISNULL(MAX(CAST(R.InWorkFlow AS int)), 0) = 0 THEN 1
							ELSE 0
						END AS DoneAndNotInWorkFlow
					FROM @Results AS R
					GROUP BY R.UserID, R.[Type], R.NodeID, R.NodeTypeID
				) AS U
			GROUP BY U.UserID, U.[Type], U.NodeTypeID
		) AS A
		ON A.UserID = X.UserID AND A.[Type] = X.[Type] AND 
			((A.NodeTypeID IS NULL AND X.NodeTypeID IS NULL) OR (A.NodeTypeID = X.NodeTypeID))

	UPDATE @Results
		SET SubType = WFState
	WHERE [Type] = N'WorkFlow' 

	SELECT	R.[Type], 
			R.SubType, 
			R.NodeTypeID, 
			MAX(R.NodeType) AS NodeType,
			ISNULL(MAX(CASE WHEN ISNULL(R.Done, 0) = 0 THEN R.SendDate ELSE NULL END),
				MAX(CASE WHEN R.Done = 1 THEN R.SendDate ELSE NULL END)) AS DateOfEffect, -- تاریخ موثر
			COUNT(CASE WHEN ISNULL(R.Done, 0) = 0 AND ISNULL(R.Seen, 0) = 0 THEN R.NodeID ELSE NULL END) AS NotSeen, -- منتظر اقدام و دیده نشده
			COUNT(CASE WHEN ISNULL(R.Done, 0) = 0 THEN R.NodeID ELSE NULL END) AS ToBeDone, -- منتظر اقدام
			COUNT(CASE WHEN R.Done = 1 THEN R.NodeID ELSE NULL END) AS Done, -- تعداد کل اقدامات انجام شده
			MAX(R.DoneAndInWorkFlow) AS DoneAndInWorkFlow, -- اقدام شده و از جریان خارج شده
			MAX(R.DoneAndNotInWorkFlow) AS DoneAndNotInWorkFlow -- اقدام شده و همچنان در جریان
	FROM @Results AS R
	GROUP BY R.UserID, R.[Type], R.SubType, R.NodeTypeID
	ORDER BY DateOfEffect DESC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[NTFN_P_GetDashboardsCount]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[NTFN_P_GetDashboardsCount]
GO

CREATE PROCEDURE [dbo].[NTFN_P_GetDashboardsCount]
	@ApplicationID	uniqueidentifier,
    @UserID			uniqueidentifier,
    @NodeID			uniqueidentifier,
    @RefItemID		uniqueidentifier,
    @Type			varchar(20),
    @SubType		varchar(20),
    @_Result		int output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @_Result = ISNULL(
		(
			SELECT COUNT(ID)
			FROM [dbo].[NTFN_Dashboards]
			WHERE ApplicationID = @ApplicationID AND
				(@UserID IS NULL OR UserID = @UserID) AND
				(@NodeID IS NULL OR NodeID = @NodeID) AND 
				(@RefItemID IS NULL OR RefItemID = @RefItemID) AND 
				(@Type IS NULL OR [Type] = @Type) AND
				(@SubType IS NULL OR SubType = @SubType) AND Done = 0 AND Deleted = 0
		), 0
	)
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[NTFN_GetDashboards]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[NTFN_GetDashboards]
GO

CREATE PROCEDURE [dbo].[NTFN_GetDashboards]
	@ApplicationID		uniqueidentifier,
	@UserID				uniqueidentifier,
	@NodeTypeID			uniqueidentifier,
	@NodeID				uniqueidentifier,
	@NodeAdditionalID	varchar(50),
	@Type				varchar(50),
	@SubType			nvarchar(500),
	@DoneState			bit,
	@DateFrom			datetime,
	@DateTo				datetime,
	@SearchText			nvarchar(500),
	@GetDistinctItems	bit,
	@InWorkFlowState	bit,
	@LowerBoundary		int,
	@Count				int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF @NodeID IS NOT NULL SET @NodeTypeID = NULL
	IF @NodeID IS NOT NULL OR @NodeAdditionalID = N'' SET @NodeAdditionalID = NULL

	DECLARE @Results TABLE (SeenOrder int, ID bigint, UserID uniqueidentifier, 
		NodeID uniqueidentifier, NodeAdditionalID varchar(50), NodeName nvarchar(255), 
		NodeTypeID uniqueidentifier, NodeType nvarchar(255), [Type] varchar(50), 
		SubType nvarchar(500), WFState nvarchar(1000),
		Info nvarchar(1000), Removable bit, SenderUserID uniqueidentifier, SendDate datetime, 
		ExpirationDate datetime, Seen bit, ViewDate datetime, Done bit, ActionDate datetime, 
		InWorkFlow bit, DoneAndInWorkFlow int, DoneAndNotInWorkFlow int)


	INSERT INTO @Results (SeenOrder, ID, UserID, NodeID, NodeAdditionalID, NodeName, 
		NodeTypeID, NodeType, [Type], SubType, WFState, Info, Removable, SenderUserID, SendDate, 
		ExpirationDate, Seen, ViewDate, Done, ActionDate)
	SELECT
		CASE WHEN D.Seen = 0 THEN 0 ELSE 1 END AS SeenOrder,
		D.ID, 
		D.UserID, 
		D.NodeID, 
		ND.NodeAdditionalID, 
		ISNULL(ND.NodeName, Q.Title) AS NodeName,
		ND.NodeTypeID,
		ND.TypeName AS NodeType, 
		D.[Type], 
		D.SubType, 
		ND.WFState,
		D.Info, 
		D.Removable,
		D.SenderUserID, 
		D.SendDate, 
		D.ExpirationDate,
		D.Seen, 
		D.ViewDate, 
		D.Done, 
		D.ActionDate
	FROM [dbo].[NTFN_Dashboards] AS D
		LEFT JOIN [dbo].[CN_View_Nodes_Normal] AS ND
		ON ND.ApplicationID = @ApplicationID AND 
			ND.NodeID = D.NodeID AND ND.Deleted = 0
		LEFT JOIN [dbo].[QA_Questions] AS Q
		ON Q.ApplicationID = @ApplicationID AND 
			Q.QuestionID = D.NodeID AND Q.Deleted = 0
	WHERE D.ApplicationID = @ApplicationID AND D.Deleted = 0 AND
		(ND.NodeID IS NOT NULL OR Q.QuestionID IS NOT NULL) AND
		(@UserID IS NULL OR D.UserID = @UserID) AND 
		(@NodeID IS NULL OR D.NodeID = @NodeID) AND
		(@NodeTypeID IS NULL OR ND.NodeTypeID = @NodeTypeID) AND
		(@NodeAdditionalID IS NULL OR ND.NodeAdditionalID = @NodeAdditionalID) AND
		(@Type IS NULL OR D.[Type] = @Type)
			
			
	-- Remove Invalid WorkFlow Items
	IF ISNULL(@Type, N'') = N'' OR @Type = N'WorkFlow' BEGIN
		DELETE R
		FROM @Results AS R
			LEFT JOIN [dbo].[WF_WorkFlowOwners] AS WO
			ON WO.ApplicationID = @ApplicationID AND WO.NodeTypeID = R.NodeTypeID AND WO.Deleted = 0
			LEFT JOIN [dbo].[CN_Services] AS S
			ON S.ApplicationID = @ApplicationID AND S.NodeTypeID = R.NodeTypeID
		WHERE R.NodeTypeID IS NOT NULL AND R.[Type] = N'WorkFlow' AND 
			(WO.WorkFlowID IS NULL OR S.IsKnowledge = 1)
	END
	-- end of Remove Invalid WorkFlow Items


	-- Remove Invalid Knowledge Items
	IF ISNULL(@Type, N'') = N'' OR @Type = N'Knowledge' BEGIN
		DELETE R
		FROM @Results AS R
			LEFT JOIN [dbo].[CN_Services] AS S
			ON S.ApplicationID = @ApplicationID AND S.NodeTypeID = R.NodeTypeID
		WHERE R.NodeTypeID IS NOT NULL AND R.[Type] = N'Knowledge' AND ISNULL(S.IsKnowledge, 0) = 0
	END
	-- end of Remove Invalid Knowledge Items


	-- Remove Invalid Wiki Items
	IF ISNULL(@Type, N'') = N'' OR @Type = N'Wiki' BEGIN
		DELETE R
		FROM @Results AS R
			LEFT JOIN [dbo].[CN_Extensions] AS S
			ON S.ApplicationID = @ApplicationID AND S.OwnerID = R.NodeTypeID AND 
				S.Extension = N'Wiki' AND S.Deleted = 0
		WHERE R.NodeTypeID IS NOT NULL AND R.[Type] = N'Wiki' AND S.OwnerID IS NULL
	END
	-- end of Remove Invalid Wiki Items
	
	
	IF ISNULL(@SearchText, N'') <> N'' BEGIN
		IF @Type = N'Wiki' OR @Type = N'WorkFlow' OR @Type = N'Knowledge' OR @Type = N'MembershipRequest' BEGIN
			DELETE R
			FROM @Results AS R
				LEFT JOIN CONTAINSTABLE([dbo].[CN_Nodes], ([Name]), @SearchText) AS SRCH
				ON SRCH.[Key] = R.NodeID
			WHERE SRCH.[Key] IS NULL
		END
		ELSE IF @Type = N'Question' BEGIN
			DELETE R
			FROM @Results AS R
				LEFT JOIN CONTAINSTABLE([dbo].[QA_Questions], ([Title]), @SearchText) AS SRCH
				ON SRCH.[Key] = R.NodeID
			WHERE SRCH.[Key] IS NULL
		END
	END
	

	IF ISNULL(@GetDistinctItems, 0) = 1 BEGIN
		IF @InWorkFlowState IS NOT NULL BEGIN
			UPDATE R
				SET InWorkFlow = 1
			FROM @Results AS R
				INNER JOIN [dbo].[NTFN_Dashboards] AS D
				ON D.ApplicationID = @ApplicationID AND 
					D.NodeID = R.NodeID AND D.[Type] = R.[Type] AND D.Done = 0 AND D.Deleted = 0 AND ISNULL(D.Removable, 0) = 0
			WHERE R.NodeID IS NOT NULL AND R.[Type] IN (N'WorkFlow', N'Knowledge')
		END
		
		SELECT TOP(ISNULL(@Count, 50))
			(X.RowNumber + X.RevRowNumber - 1) AS TotalCount,
			X.NodeID AS ID
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY Ref.SendDate DESC, Ref.NodeID DESC) AS RowNumber,
						ROW_NUMBER() OVER (ORDER BY Ref.SendDate ASC, Ref.NodeID ASC) AS RevRowNumber,
						Ref.NodeID
				FROM (
						SELECT	R.NodeID, 
								MAX(R.SendDate) AS SendDate, 
								MAX(CAST(R.InWorkFlow AS int)) AS InWorkFlow
						FROM @Results AS R
						WHERE R.NodeID IS NOT NULL AND R.Done = 1
						GROUP BY R.NodeID
					) AS Ref
				WHERE @InWorkFlowState IS NULL OR
					(@InWorkFlowState = 0 AND ISNULL(Ref.InWorkFlow, 0) = 0) OR
					(@InWorkFlowState = 1 AND ISNULL(Ref.InWorkFlow, 0) = 1)
			) AS X
		WHERE X.RowNumber >= ISNULL(@LowerBoundary, 0)
		ORDER BY X.RowNumber ASC
	END -- end of 'IF @InWorkFlowState IS NOT NULL BEGIN'
	ELSE BEGIN
		SELECT TOP(ISNULL(@Count, 50)) 
			(X.RowNumber + X.RevRowNumber - 1) AS TotalCount,
			X.*
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY R.SeenOrder ASC, R.SendDate DESC, R.ID DESC) AS RowNumber,
						ROW_NUMBER() OVER (ORDER BY R.SeenOrder DESC, R.SendDate ASC, R.ID ASC) AS RevRowNumber,
						R.*
				FROM @Results AS R
				WHERE (@DoneState IS NULL OR ISNULL(R.Done, 0) = @DoneState) AND
					(@DateFrom IS NULL OR R.SendDate >= @DateFrom) AND
					(@DateTo IS NULL OR R.SendDate < @DateTo) AND
					(@SubType IS NULL OR R.SubType = @SubType OR R.WFState = @SubType)
			) AS X
		WHERE X.RowNumber >= ISNULL(@LowerBoundary, 0)
		ORDER BY X.RowNumber ASC
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[NTFN_P_DashboardExists]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[NTFN_P_DashboardExists]
GO

CREATE PROCEDURE [dbo].[NTFN_P_DashboardExists]
	@ApplicationID		uniqueidentifier,
    @UserID				uniqueidentifier,
	@NodeID				uniqueidentifier,
	@DashboardType		varchar(20),
	@SubType			varchar(20),
	@Seen				bit,
	@Done				bit,
	@LowerDateLimit		datetime,
	@UpperDateLimit		datetime,
	@_Result			int output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @_Result = -1
	
	SELECT @_Result = 1
	WHERE EXISTS (
		SELECT TOP(1) ID
		FROM [dbo].[NTFN_Dashboards]
		WHERE ApplicationID = @ApplicationID AND 
			(@UserID IS NULL OR UserID = @UserID) AND
			(@NodeID IS NULL OR NodeID = @NodeID) AND
			(@DashboardType IS NULL OR [Type] = @DashboardType) AND
			(@SubType IS NULL OR SubType = @SubType) AND
			(@Seen IS NULL OR Seen = @Seen) AND
			(@Done IS NULL OR Done = @Done) AND
			(@LowerDateLimit IS NULL OR SendDate >= @LowerDateLimit) AND
			(@UpperDateLimit IS NULL OR SendDate <= @UpperDateLimit) AND Deleted = 0
	)
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[NTFN_DashboardExists]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[NTFN_DashboardExists]
GO

CREATE PROCEDURE [dbo].[NTFN_DashboardExists]
	@ApplicationID		uniqueidentifier,
    @UserID				uniqueidentifier,
	@NodeID				uniqueidentifier,
	@DashboardType		varchar(20),
	@SubType			varchar(20),
	@Seen				bit,
	@Done				bit,
	@LowerDateLimit		datetime,
	@UpperDateLimit		datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @_Result int
	
	EXEC [dbo].[NTFN_P_DashboardExists] @ApplicationID, @UserID, @NodeID, @DashboardType, 
		@SubType, @Seen, @Done, @LowerDateLimit, @UpperDateLimit, @_Result output
		
	SELECT @_Result
END

GO

-- end of Dashboard Procedures


-- Message Template Procedures

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[NTFN_SetMessageTemplate]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[NTFN_SetMessageTemplate]
GO

CREATE PROCEDURE [dbo].[NTFN_SetMessageTemplate]
	@ApplicationID		uniqueidentifier,
	@TemplateID			uniqueidentifier,
	@OwnerID			uniqueidentifier,
	@BodyText			nvarchar(4000),
	@AudienceType		varchar(20),
	@AudienceRefOwnerID	uniqueidentifier,
	@AudienceNodeID		uniqueidentifier,
	@AudienceNodeAdmin	bit,
	@CreatorUserID		uniqueidentifier,
	@CreationDate		datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM [dbo].[NTFN_MessageTemplates] 
		WHERE ApplicationID = @ApplicationID AND TemplateID = @TemplateID
	) BEGIN
		UPDATE [dbo].[NTFN_MessageTemplates]
			SET	BodyText = [dbo].[GFN_VerifyString](@BodyText),
				AudienceType = @AudienceType,
				AudienceRefOwnerID = @AudienceRefOwnerID,
				AudienceNodeID = @AudienceNodeID,
				AudienceNodeAdmin = ISNULL(@AudienceNodeAdmin, 0),
				LastModifierUserID = @CreatorUserID,
				LastModificationDate = @CreationDate
		WHERE ApplicationID = @ApplicationID AND TemplateID = @TemplateID
	END
	ELSE BEGIN
		INSERT INTO [dbo].[NTFN_MessageTemplates](
			ApplicationID,
			TemplateID,
			OwnerID,
			BodyText,
			AudienceType,
			AudienceRefOwnerID,
			AudienceNodeID,
			AudienceNodeAdmin,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES(
			@ApplicationID,
			@TemplateID,
			@OwnerID,
			[dbo].[GFN_VerifyString](@BodyText),
			@AudienceType,
			@AudienceRefOwnerID,
			@AudienceNodeID,
			ISNULL(@AudienceNodeAdmin, 0),
			@CreatorUserID,
			@CreationDate,
			0
		)
	END
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[NTFN_ArithmeticDeleteMessageTemplate]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[NTFN_ArithmeticDeleteMessageTemplate]
GO

CREATE PROCEDURE [dbo].[NTFN_ArithmeticDeleteMessageTemplate]
	@ApplicationID			uniqueidentifier,
	@TemplateID				uniqueidentifier,
	@LastModifierUserID		uniqueidentifier,
	@LastModificationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[NTFN_MessageTemplates]
		SET	Deleted = 1,
			LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate
	WHERE ApplicationID = @ApplicationID AND TemplateID = @TemplateID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[NTFN_P_GetOwnerMessageTemplates]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[NTFN_P_GetOwnerMessageTemplates]
GO

CREATE PROCEDURE [dbo].[NTFN_P_GetOwnerMessageTemplates]
	@ApplicationID	uniqueidentifier,
	@OwnerIDsTemp	GuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @OwnerIDs GuidTableType
	INSERT INTO @OwnerIDs SELECT * FROM @OwnerIDsTemp
	
	SELECT MT.TemplateID,
		   MT.OwnerID,
		   MT.BodyText,
		   MT.AudienceType,
		   MT.AudienceRefOwnerID,
		   MT.AudienceNodeID,
		   ND.NodeName AS AudienceNodeName,
		   ND.NodeTypeID AS AudienceNodeTypeID,
		   ND.TypeName AS AudienceNodeType,
		   MT.AudienceNodeAdmin
	FROM @OwnerIDs AS Ref
		INNER JOIN [dbo].[NTFN_MessageTemplates] AS MT
		ON MT.OwnerID = Ref.Value
		LEFT JOIN [dbo].[CN_View_Nodes_Normal] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.NodeID = MT.AudienceNodeID
	WHERE MT.ApplicationID = @ApplicationID AND MT.Deleted = 0
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[NTFN_GetOwnerMessageTemplates]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[NTFN_GetOwnerMessageTemplates]
GO

CREATE PROCEDURE [dbo].[NTFN_GetOwnerMessageTemplates]
	@ApplicationID	uniqueidentifier,
	@strOwnerIDs	varchar(max),
	@delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @OwnerIDs GuidTableType
	INSERT INTO @OwnerIDs
	SELECT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strOwnerIDs, @delimiter) AS Ref
	
	EXEC [dbo].[NTFN_P_GetOwnerMessageTemplates] @ApplicationID, @OwnerIDs
END

GO

-- end of Message Template Procedures


-- Notification Messages (EMail & SMS)

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'NTFN_GetNotificationMessagesInfo') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1 )
DROP PROCEDURE [dbo].[NTFN_GetNotificationMessagesInfo]
GO

CREATE PROCEDURE [dbo].[NTFN_GetNotificationMessagesInfo]
	@ApplicationID		uniqueidentifier,
	@RefAppID			uniqueidentifier,
	@UserStatusPairTemp GuidStringTableType readOnly,
    @SubjectType		VARCHAR(50),
	@Action				VARCHAR(50)
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserStatusPair GuidStringTableType
	INSERT INTO @UserStatusPair SELECT * FROM @UserStatusPairTemp

	SELECT	UST.FirstValue AS UserID, 
			MT.Media,
			MT.[Lang],
			MT.[Subject],
			MT.[Text]
	FROM @UserStatusPair AS UST
		INNER JOIN [dbo].[NTFN_UserMessagingActivation] AS SO
		ON SO.ApplicationID = @ApplicationID AND SO.UserID = UST.FirstValue
		RIGHT JOIN [dbo].[NTFN_NotificationMessageTemplates] AS MT
		ON MT.ApplicationID = ISNULL(@RefAppID, @ApplicationID) AND MT.UserStatus = UST.SecondValue AND 
			MT.[Action] = SO.[Action] AND MT.SubjectType = SO.SubjectType AND 
			MT.Media = SO.Media AND MT.[Lang] = SO.[Lang]
	WHERE MT.ApplicationID = ISNULL(@RefAppID, @ApplicationID) AND 
		MT.[Action] = @Action AND MT.SubjectType = @SubjectType AND 
		MT.[Enable] = 1 AND ISNULL(SO.[Enable], 1) = 1 
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[dbo].[NTFN_SetUserMessagingActivation]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1 )
DROP PROCEDURE [dbo].[NTFN_SetUserMessagingActivation]
GO

CREATE PROCEDURE [dbo].[NTFN_SetUserMessagingActivation]
	@ApplicationID			uniqueidentifier,
	@OptionID				UNIQUEIDENTIFIER,
	@UserID					UNIQUEIDENTIFIER,
	@LastModifierUserId		UNIQUEIDENTIFIER,
	@LastModificationDate	DATETIME,
	@SubjectType			VARCHAR(50),
	@UserStatus				VARCHAR(50),
	@Action					VARCHAR(50),
	@Media					VARCHAR(50),
	@Lang					VARCHAR(50),
	@Enable					BIT
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	IF(EXISTS(
		SELECT * 
		FROM [dbo].[NTFN_UserMessagingActivation]
		WHERE ApplicationID = @ApplicationID AND OptionID = @OptionID
	))BEGIN
		UPDATE [dbo].[NTFN_UserMessagingActivation]
			SET LastModifierUserId = @LastModifierUserId,
				LastModificationDate = @LastModificationDate,
				[Enable] = @Enable
		WHERE ApplicationID = @ApplicationID AND OptionID = @OptionID
	END
	ELSE BEGIN
		INSERT INTO [dbo].[NTFN_UserMessagingActivation](
			ApplicationID,
			OptionID,
			UserID,
			SubjectType,
			UserStatus,
			[Action],
			Media,
			[Lang],
			[Enable]
		)
		VALUES(
			@ApplicationID,
			@OptionID,
			@UserID,
			@SubjectType,
			@UserStatus,
			@Action,
			@Media,
			@Lang,
			@Enable
		)
	END
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[NTFN_GetNotificationMessageTemplatesInfo]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[NTFN_GetNotificationMessageTemplatesInfo]
GO

CREATE PROCEDURE [dbo].[NTFN_GetNotificationMessageTemplatesInfo]
	@ApplicationID	uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT	[TemplateID],
			[SubjectType],
			[Action],
			[Media],
			UserStatus,
			[Lang],
			[Subject],
			[Text],
			[Enable]
	FROM [dbo].[NTFN_NotificationMessageTemplates]
	WHERE ApplicationID = @ApplicationID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[NTFN_GetUserMessagingActivation]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[NTFN_GetUserMessagingActivation]
GO

CREATE PROCEDURE [dbo].[NTFN_GetUserMessagingActivation]
	@ApplicationID	uniqueidentifier,
	@RefAppID		uniqueidentifier,
	@UserID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT
		UMA.OptionID,
		CASE
			WHEN UMA.[SubjectType] IS NULL THEN NMT.[SubjectType]
			ELSE UMA.[SubjectType]
		END AS SubjectType,
		UMA.UserID,
		CASE
			WHEN UMA.[UserStatus] IS NULL THEN NMT.[UserStatus]
			ELSE UMA.[UserStatus]
		END AS UserStatus,
		CASE
			WHEN UMA.[Action] IS NULL THEN NMT.[Action]
			ELSE UMA.[Action]
		END AS [Action],
		CASE
			WHEN UMA.[Media] IS NULL THEN NMT.[Media]
			ELSE UMA.[Media]
		END AS Media,
		CASE
			WHEN UMA.[Lang] IS NULL THEN NMT.[Lang]
			ELSE UMA.[Lang]
		END AS [Lang],
		UMA.[Enable],
		NMT.[Enable] AS AdminEnable
	FROM [dbo].[NTFN_UserMessagingActivation] AS UMA
		FULL OUTER JOIN [dbo].[NTFN_NotificationMessageTemplates] AS NMT
		ON UMA.ApplicationID = @ApplicationID AND NMT.ApplicationID = ISNULL(@RefAppID, @ApplicationID) AND 
			UMA.UserID = @UserID AND NMT.[Action] = UMA.[Action] AND 
			NMT.[Lang] = UMA.[Lang] AND NMT.Media = UMA.Media AND 
			NMT.SubjectType = UMA.SubjectType AND NMT.UserStatus = UMA.UserStatus
	WHERE UMA.ApplicationID = @ApplicationID AND 
		NMT.ApplicationID = ISNULL(@RefAppID, @ApplicationID) AND 
		UMA.UserID IS NULL OR UMA.UserID = @UserID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[NTFN_SetAdminMessagingActivation]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[NTFN_SetAdminMessagingActivation]
GO

CREATE PROCEDURE [dbo].[NTFN_SetAdminMessagingActivation]
	@ApplicationID			uniqueidentifier,
	@TemplateID				UNIQUEIDENTIFIER,
	@LastModifierUserID		UNIQUEIDENTIFIER,
	@LastModificationDate	DATETIME,
	@SubjectType			VARCHAR(50),
	@Action					VARCHAR(50),
	@Media					VARCHAR(50),
	@UserStatus				VARCHAR(50),
	@Lang					VARCHAR(50),
	@Enable					BIT
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	IF(EXISTS(
		SELECT * 
		FROM [dbo].[NTFN_NotificationMessageTemplates]
		WHERE ApplicationID = @ApplicationID AND TemplateID = @TemplateID
	))BEGIN
		UPDATE [dbo].[NTFN_NotificationMessageTemplates]
			SET LastModifierUserId = @LastModifierUserId,
				LastModificationDate = @LastModificationDate,
				[Enable] = @Enable
		WHERE ApplicationID = @ApplicationID AND TemplateID = @TemplateID
	END
	ELSE BEGIN
		INSERT INTO [dbo].[NTFN_NotificationMessageTemplates](
			ApplicationID,
			TemplateID,
			SubjectType,
			[Action],
			Media,
			UserStatus,
			[Lang],
			[Enable]
		)
		VALUES(
			@ApplicationID,
			@TemplateID,
			@SubjectType,
			@Action,
			@Media,
			@UserStatus,
			@Lang,
			1
		)
	END
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[NTFN_SetNotificationMessageTemplateText]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[NTFN_SetNotificationMessageTemplateText]
GO

CREATE PROCEDURE [dbo].[NTFN_SetNotificationMessageTemplateText]
	@ApplicationID			uniqueidentifier,
	@TemplateID				UNIQUEIDENTIFIER,
	@LastModifierUserID		UNIQUEIDENTIFIER,
	@LastModificationDate	DATETIME,
	@Subject				NVARCHAR (512),
	@Text					NVARCHAR (max)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	UPDATE [dbo].[NTFN_NotificationMessageTemplates]
		SET LastModifierUserId = @LastModifierUserID,
			LastModificationDate = @LastModificationDate,
			[Subject] = @Subject,
			[Text] = @Text
	WHERE ApplicationID = @ApplicationID AND TemplateID = @TemplateID
	
	SELECT @@ROWCOUNT
END
GO

-- end of Notification Messages (EMail & SMS)