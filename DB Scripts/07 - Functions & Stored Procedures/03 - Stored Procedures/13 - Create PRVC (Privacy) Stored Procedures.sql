USE [EKM_App]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[PRVC_InitializeConfidentialityLevels]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[PRVC_InitializeConfidentialityLevels]
GO

CREATE PROCEDURE [dbo].[PRVC_InitializeConfidentialityLevels]
	@ApplicationID		uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserID uniqueidentifier = (
		SELECT TOP(1) UserID 
		FROM [dbo].[Users_Normal]
		WHERE ApplicationId = @ApplicationID AND LoweredUserName = N'admin'
	)
	
	IF @UserID IS NULL BEGIN
		SELECT TOP(1) @UserID = A.CreatorUserID
		FROM [dbo].[aspnet_Applications] AS A
		WHERE A.ApplicationId = @ApplicationID
	END
	
	IF @UserID IS NULL RETURN 1
	
	DECLARE @Now datetime = GETDATE()
	
	DECLARE @TBL Table(LevelID int, Title nvarchar(100))
	
	INSERT INTO @TBL (LevelID, Title)
	VALUES	(1,	N'فاقد طبقه بندی'),
			(2,	N'محرمانه'),
			(3,	N'خیلی محرمانه'),
			(4,	N'سری'),
			(5,	N'به کلی سری')
	
	IF NOT EXISTS(
		SELECT TOP(1) *
		FROM [dbo].[PRVC_ConfidentialityLevels] AS L
		WHERE L.ApplicationID = @ApplicationID
	) BEGIN
		INSERT INTO [dbo].[PRVC_ConfidentialityLevels] (ApplicationID, ID, LevelID, Title, 
			CreatorUserID, CreationDate, Deleted)
		SELECT @ApplicationID, NEWID(), T.LevelID, T.Title, @UserID, @Now, 0
		FROM @TBL AS T
	END
    
    RETURN 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[PRVC_P_AddAudience]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[PRVC_P_AddAudience]
GO

CREATE PROCEDURE [dbo].[PRVC_P_AddAudience]
	@ApplicationID		uniqueidentifier,
	@ObjectID			uniqueidentifier,
	@RoleID				uniqueidentifier,
	@PermissionType		varchar(50),
	@Allow				bit,
	@ExpirationDate		datetime,
	@CreatorUserID		uniqueidentifier,
	@CreationDate		datetime,
	@_Result			int output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM [dbo].[PRVC_Audience]
		WHERE ApplicationID = @ApplicationID AND RoleID = @RoleID AND ObjectID = @ObjectID
	) BEGIN
		UPDATE [dbo].[PRVC_Audience]
			SET Allow = @Allow,
				ExpirationDate = @ExpirationDate,
				LastModifierUserID = @CreatorUserID,
				LastModificationDate = @CreationDate,
				Deleted = 0
		WHERE ApplicationID = @ApplicationID AND ObjectID = @ObjectID AND 
			RoleID = @RoleID AND PermissionType = @PermissionType
	END
	ELSE BEGIN
		INSERT INTO [dbo].[PRVC_Audience](
			ApplicationID,
			ObjectID,
			RoleID,
			PermissionType,
			Allow,
			ExpirationDate,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES(
			@ApplicationID,
			@ObjectID, 
			@RoleID, 
			@PermissionType,
			@Allow, 
			@ExpirationDate, 
			@CreatorUserID, 
			@CreationDate, 
			0
		)
	END
	
	SET @_Result = @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[PRVC_SetAudience]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[PRVC_SetAudience]
GO

CREATE PROCEDURE [dbo].[PRVC_SetAudience]
	@ApplicationID			uniqueidentifier,
	@ObjectIDsTemp			GuidTableType readonly,
	@DefaultPermissionsTemp	GuidStringPairTableType readonly,
	@AudienceTemp			PrivacyAudienceTableType readonly,
	@SettingsTemp			GuidPairBitTableType readonly,
	@CurrentUserID		uniqueidentifier,
	@Now				datetime
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @ObjectIDs GuidTableType
	INSERT INTO @ObjectIDs SELECT * FROM @ObjectIDsTemp
	
	DECLARE @DefaultPermissions GuidStringPairTableType
	INSERT INTO @DefaultPermissions SELECT * FROM @DefaultPermissionsTemp
	
	DECLARE @Audience PrivacyAudienceTableType
	INSERT INTO @Audience SELECT * FROM @AudienceTemp
	
	DECLARE @Settings GuidPairBitTableType
	INSERT INTO @Settings SELECT * FROM @SettingsTemp
	
	-- Update Settings
	DELETE S
	FROM @ObjectIDs AS IDs
		INNER JOIN [dbo].[PRVC_Settings] AS S
		ON S.ObjectID = IDs.Value
		LEFT JOIN @Settings AS T
		ON T.FirstValue = IDs.Value
	WHERE T.FirstValue IS NULL
	
	UPDATE S
		SET CalculateHierarchy = ISNULL(T.BitValue, 0),
			ConfidentialityID = T.SecondValue,
			LastModifierUserID = @CurrentUserID,
			LastModificationDate = @Now
	FROM [dbo].[PRVC_Settings] AS S
		INNER JOIN @Settings AS T
		ON T.FirstValue = S.ObjectID
	
	INSERT INTO [dbo].[PRVC_Settings] (ApplicationID, ObjectID, 
		CalculateHierarchy, ConfidentialityID, CreatorUserID, CreationDate)
	SELECT @ApplicationID, T.FirstValue, ISNULL(T.BitValue, 0), T.SecondValue, @CurrentUserID, @Now
	FROM @Settings AS T
		LEFT JOIN [dbo].[PRVC_Settings] AS S
		ON S.ObjectID = T.FirstValue
	WHERE S.ObjectID IS NULL
	-- end of Update Settings
	
	
	-- Update Default Permissions
	DELETE P
	FROM @ObjectIDs AS IDs
		INNER JOIN [dbo].[PRVC_DefaultPermissions] AS P
		ON P.ObjectID = IDs.Value
		LEFT JOIN @DefaultPermissions AS D
		ON D.GuidValue = IDs.Value AND D.FirstValue = P.PermissionType
	WHERE D.GuidValue IS NULL
	
	UPDATE P
		SET DefaultValue = D.SecondValue,
			LastModifierUserID = @CurrentUserID,
			LastModificationDate = @Now
	FROM [dbo].[PRVC_DefaultPermissions] AS P
		INNER JOIN @DefaultPermissions AS D
		ON D.GuidValue = P.ObjectID AND D.FirstValue = P.PermissionType
	
	INSERT INTO [dbo].[PRVC_DefaultPermissions] (ApplicationID, ObjectID, 
		PermissionType, DefaultValue, CreatorUserID, CreationDate)
	SELECT @ApplicationID, D.GuidValue, D.FirstValue, D.SecondValue, @CurrentUserID, @Now
	FROM @DefaultPermissions AS D
		LEFT JOIN [dbo].[PRVC_DefaultPermissions] AS P
		ON P.ObjectID = D.GuidValue AND P.PermissionType = D.FirstValue
	WHERE P.ObjectID IS NULL
	-- end of Update Default Permissions
	
	
	-- Update Audience
	UPDATE A
		SET Deleted = 1,
			LastModifierUserID = @CurrentUserID,
			LastModificationDate = @Now
	FROM @ObjectIDs AS IDs
		INNER JOIN [dbo].[PRVC_Audience] AS A
		ON A.ObjectID = IDs.Value
		LEFT JOIN @Audience AS D
		ON D.ObjectID = A.ObjectID AND D.RoleID = A.RoleID AND D.PermissionType = A.PermissionType
	WHERE D.ObjectID IS NULL
	
	UPDATE A
		SET Allow = ISNULL(D.Allow, 0),
			PermissionType = D.PermissionType,
			ExpirationDate = D.ExpirationDate,
			Deleted = 0,
			LastModifierUserID = @CurrentUserID,
			LastModificationDate = @Now
	FROM [dbo].[PRVC_Audience] AS A
		INNER JOIN @Audience AS D
		ON D.ObjectID = A.ObjectID AND D.RoleID = A.RoleID AND D.PermissionType = A.PermissionType
	
	INSERT INTO [dbo].[PRVC_Audience] (ApplicationID, ObjectID, 
		RoleID, Allow, PermissionType, ExpirationDate, CreatorUserID, CreationDate, Deleted)
	SELECT @ApplicationID, D.ObjectID, D.RoleID, ISNULL(D.Allow, 0), 
		D.PermissionType, D.ExpirationDate, @CurrentUserID, @Now, 0
	FROM @Audience AS D
		LEFT JOIN [dbo].[PRVC_Audience] AS A
		ON A.ObjectID = D.ObjectID AND A.RoleID = D.RoleID AND D.PermissionType = A.PermissionType
	WHERE A.ObjectID IS NULL
	-- end of Update Audience
	
	SELECT 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[PRVC_CheckAccess]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[PRVC_CheckAccess]
GO

CREATE PROCEDURE [dbo].[PRVC_CheckAccess]
	@ApplicationID		uniqueidentifier,
	@UserID				uniqueidentifier,
	@ObjectType			varchar(50),
    @ObjectIDsTemp		GuidTableType readonly,
    @PermissionsTemp	StringPairTableType readonly,
    @Now				datetime
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @ObjectIDs GuidTableType
	INSERT INTO @ObjectIDs SELECT DISTINCT * FROM @ObjectIDsTemp
	
    DECLARE @Permissions StringPairTableType
    INSERT INTO @Permissions SELECT * FROM @PermissionsTemp
	
	DECLARE @IDs KeyLessGuidTableType
	
	INSERT INTO @IDs (Value)
	SELECT O.Value
	FROM @ObjectIDs AS O
	
	SELECT Ref.ID, Ref.[Type]
	FROM [dbo].[PRVC_FN_CheckAccess](@ApplicationID, @UserID, 
		@IDs, @ObjectType, @Now, @Permissions) AS Ref
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[PRVC_GetAudienceRoleIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[PRVC_GetAudienceRoleIDs]
GO

CREATE PROCEDURE [dbo].[PRVC_GetAudienceRoleIDs]
	@ApplicationID	uniqueidentifier,
	@ObjectID		uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT Ref.RoleID AS ID
	FROM [dbo].[PRVC_Audience] AS Ref
	WHERE Ref.ApplicationID = @ApplicationID AND Ref.ObjectID = @ObjectID AND Ref.Deleted = 0
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[PRVC_GetAudience]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[PRVC_GetAudience]
GO

CREATE PROCEDURE [dbo].[PRVC_GetAudience]
	@ApplicationID	uniqueidentifier,
	@strObjectIDs	varchar(max),
	@delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @ObjectIDs GuidTableType
	
	INSERT INTO @ObjectIDs (Value)
	SELECT DISTINCT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strObjectIDs, @delimiter) AS Ref
	
	DECLARE @Audience Table(ObjectID uniqueidentifier, RoleID uniqueidentifier, 
		PermissionType varchar(50), Allow bit, ExpirationDate datetime)
	
	INSERT INTO @Audience (ObjectID, RoleID, PermissionType, Allow, ExpirationDate)
	SELECT Ref.ObjectID, Ref.RoleID, Ref.PermissionType, Ref.Allow, Ref.ExpirationDate
	FROM @ObjectIDs AS IDs
		INNER JOIN [dbo].[PRVC_Audience] AS Ref
		ON Ref.ApplicationID = @ApplicationID AND Ref.ObjectID = IDs.Value AND Ref.Deleted = 0

	SELECT	ExternalIDs.*,
			RTRIM(LTRIM((ISNULL(UN.FirstName, N'') + N' ' + ISNULL(UN.LastName, N'')))) AS Name,
			N'User' AS [Type],
			NULL AS NodeType,
			NULL AS NodeTypeID,
			UN.UserName AS AdditionalID
	FROM @Audience AS ExternalIDs
		INNER JOIN [dbo].[Users_Normal] AS UN
		ON UN.UserID = ExternalIDs.RoleID
	WHERE UN.ApplicationID = @ApplicationID AND UN.IsApproved = 1
	
	UNION ALL
	
	SELECT	ExternalIDs.*,
			ND.NodeName AS Name,
			N'Node' AS [Type],
			ND.TypeName AS NodeType,
			ND.NodeTypeID,
			ND.NodeAdditionalID AS AdditionalID
	FROM @Audience AS ExternalIDs
		INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
		ON ND.NodeID = ExternalIDs.RoleID
	WHERE ND.ApplicationID = @ApplicationID AND ND.Deleted = 0
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[PRVC_GetDefaultPermissions]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[PRVC_GetDefaultPermissions]
GO

CREATE PROCEDURE [dbo].[PRVC_GetDefaultPermissions]
	@ApplicationID	uniqueidentifier,
	@strObjectIDs	varchar(max),
	@delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @ObjectIDs GuidTableType
	
	INSERT INTO @ObjectIDs (Value)
	SELECT DISTINCT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strObjectIDs, @delimiter) AS Ref
	
	SELECT P.ObjectID AS ID, P.PermissionType AS [Type], P.DefaultValue
	FROM @ObjectIDs AS IDs
		INNER JOIN [dbo].[PRVC_DefaultPermissions] AS P
		ON P.ApplicationID = @ApplicationID AND P.ObjectID = IDs.Value
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[PRVC_GetSettings]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[PRVC_GetSettings]
GO

CREATE PROCEDURE [dbo].[PRVC_GetSettings]
	@ApplicationID	uniqueidentifier,
	@strObjectIDs	varchar(max),
	@delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @ObjectIDs GuidTableType
	
	INSERT INTO @ObjectIDs (Value)
	SELECT DISTINCT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strObjectIDs, @delimiter) AS Ref
	
	SELECT IDs.Value AS ObjectID, S.CalculateHierarchy, S.ConfidentialityID, CL.LevelID, CL.[Title] AS [Level]
	FROM @ObjectIDs AS IDs
		LEFT JOIN [dbo].[PRVC_Settings] AS S
		ON S.ApplicationID = @ApplicationID AND S.ObjectID = IDs.Value
		LEFT JOIN [dbo].[PRVC_ConfidentialityLevels] AS CL
		ON CL.ApplicationID = @ApplicationID AND CL.ID = S.ConfidentialityID AND CL.Deleted = 0
END

GO


-- Confidentiality

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[PRVC_AddConfidentialityLevel]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[PRVC_AddConfidentialityLevel]
GO

CREATE PROCEDURE [dbo].[PRVC_AddConfidentialityLevel]
	@ApplicationID	uniqueidentifier,
	@ID				uniqueidentifier,
	@LevelID		int,
	@Title			nvarchar(256),
	@CurrentUserID	uniqueidentifier,
	@Now			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @Title = [dbo].[GFN_VerifyString](@Title)
	
	IF EXISTS(
		SELECT TOP(1) 1 
		FROM [dbo].[PRVC_ConfidentialityLevels] 
		WHERE ApplicationID = @ApplicationID AND LevelID = @LevelID AND Deleted = 0
	) BEGIN
		SELECT -1, N'LevelCodeAlreadyExists'
		RETURN
	END
	
	INSERT INTO [dbo].[PRVC_ConfidentialityLevels](
		ApplicationID,
		ID,
		LevelID,
		Title,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	VALUES(
		@ApplicationID,
		@ID,
		@LevelID,
		@Title,
		@CurrentUserID,
		@Now,
		0
	)
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[PRVC_ModifyConfidentialityLevel]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[PRVC_ModifyConfidentialityLevel]
GO

CREATE PROCEDURE [dbo].[PRVC_ModifyConfidentialityLevel]
	@ApplicationID	uniqueidentifier,
	@ID				uniqueidentifier,
	@NewLevelID		int,
	@NewTitle		nvarchar(256),
	@CurrentUserID	uniqueidentifier,
	@Now			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @NewTitle = [dbo].[GFN_VerifyString](@NewTitle)
	
	IF EXISTS(
		SELECT TOP(1) 1 
		FROM [dbo].[PRVC_ConfidentialityLevels] 
		WHERE ApplicationID = @ApplicationID AND 
			ID <> @ID AND LevelID = @NewLevelID AND Deleted = 0
	) BEGIN
		SELECT -1, N'LevelCodeAlreadyExists'
		RETURN
	END
	
	UPDATE [dbo].[PRVC_ConfidentialityLevels]
		SET LevelID = @NewLevelID,
			Title = @NewTitle,
			LastModifierUserID = @CurrentUserID,
			LastModificationDate = @Now
	WHERE ApplicationID = @ApplicationID AND ID = @ID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[PRVC_RemoveConfidentialityLevel]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[PRVC_RemoveConfidentialityLevel]
GO

CREATE PROCEDURE [dbo].[PRVC_RemoveConfidentialityLevel]
	@ApplicationID	uniqueidentifier,
	@ID				uniqueidentifier,
	@CurrentUserID	uniqueidentifier,
	@Now			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[PRVC_ConfidentialityLevels]
		SET Deleted = 1,
			LastModifierUserID = @CurrentUserID,
			LastModificationDate = @Now
	WHERE ApplicationID = @ApplicationID AND ID = @ID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[PRVC_GetConfidentialityLevels]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[PRVC_GetConfidentialityLevels]
GO

CREATE PROCEDURE [dbo].[PRVC_GetConfidentialityLevels]
	@ApplicationID	uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT CONF.ID AS ID,
		   CONF.[LevelID] AS LevelID,
		   CONF.[Title] AS Title
	FROM [dbo].[PRVC_ConfidentialityLevels] AS CONF
	WHERE CONF.ApplicationID = @ApplicationID AND CONF.Deleted = 0
	ORDER BY CONF.LevelID ASC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[PRVC_SetConfidentialityLevel]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[PRVC_SetConfidentialityLevel]
GO

CREATE PROCEDURE [dbo].[PRVC_SetConfidentialityLevel]
	@ApplicationID			uniqueidentifier,
	@ItemID					uniqueidentifier,
	@LevelID				uniqueidentifier,
	@LastModifierUserID		uniqueidentifier,
	@LastModificationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM [dbo].[PRVC_Settings] 
		WHERE ApplicationID = @ApplicationID AND ObjectID = @ItemID
	) BEGIN
		UPDATE [dbo].[PRVC_Settings]
			SET ConfidentialityID = @LevelID,
				LastModifierUserID = @LastModifierUserID,
				LastModificationDate = @LastModificationDate
		WHERE ApplicationID = @ApplicationID AND ObjectID = @ItemID
	END
	ELSE BEGIN
		INSERT INTO [dbo].[PRVC_Settings](
			ApplicationID,
			ObjectID,
			ConfidentialityID,
			CreatorUserID,
			CreationDate
		)
		VALUES(
			@ApplicationID,
			@ItemID,
			@LevelID,
			@LastModifierUserID,
			@LastModificationDate
		)
	END
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[PRVC_UnsetConfidentialityLevel]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[PRVC_UnsetConfidentialityLevel]
GO

CREATE PROCEDURE [dbo].[PRVC_UnsetConfidentialityLevel]
	@ApplicationID			uniqueidentifier,
	@ItemID					uniqueidentifier,
	@LastModifierUserID		uniqueidentifier,
	@LastModificationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[PRVC_Settings]
		SET LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate,
			ConfidentialityID = null
	WHERE ApplicationID = @ApplicationID AND ObjectID = @ItemID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[PRVC_GetConfidentialityLevelUserIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[PRVC_GetConfidentialityLevelUserIDs]
GO

CREATE PROCEDURE [dbo].[PRVC_GetConfidentialityLevelUserIDs]
	@ApplicationID			uniqueidentifier,
	@ConfidentialityID		uniqueidentifier,
	@SearchText				nvarchar(500),
	@Count					int,
	@LowerBoundary			bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF ISNULL(@Count, 0) <= 0 SET @Count = 1000000
	
	IF ISNULL(@SearchText, N'') = N'' BEGIN
		SELECT TOP(@Count)
			Ref.UserID,
			(Ref.RowNumber + Ref.RevRowNumber - 1) AS TotalCount
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY USR.UserID DESC) AS RowNumber,
						ROW_NUMBER() OVER (ORDER BY USR.UserID ASC) AS RevRowNumber,
						USR.UserID
				FROM [dbo].[PRVC_View_Confidentialities] AS C
					INNER JOIN [dbo].[Users_Normal] AS USR
					ON USR.ApplicationID = @ApplicationID AND USR.UserID = C.ObjectID
				WHERE C.ApplicationID = @ApplicationID AND C.ConfidentialityID = @ConfidentialityID
			) AS Ref
		WHERE Ref.RowNumber >= ISNULL(@LowerBoundary, 0)
		ORDER BY Ref.RowNumber ASC
	END
	ELSE BEGIN
		SELECT TOP(@Count)
			Ref.UserID,
			(Ref.RowNumber + Ref.RevRowNumber - 1) AS TotalCount
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY SRCH.[RANK] DESC, USR.UserID DESC) AS RowNumber,
						ROW_NUMBER() OVER (ORDER BY SRCH.[RANK] ASC, USR.UserID ASC) AS RevRowNumber,
						USR.UserID
				FROM CONTAINSTABLE([dbo].[USR_View_Users], (FirstName, LastName, UserName), @SearchText) AS SRCH 
					INNER JOIN [dbo].[PRVC_View_Confidentialities] AS C
					INNER JOIN [dbo].[Users_Normal] AS USR
					ON USR.ApplicationID = @ApplicationID AND USR.UserID = C.ObjectID
					ON USR.UserID = SRCH.[Key]
				WHERE C.ApplicationID = @ApplicationID AND C.ConfidentialityID = @ConfidentialityID
			) AS Ref
		WHERE Ref.RowNumber >= ISNULL(@LowerBoundary, 0)
		ORDER BY Ref.RowNumber ASC	
	END
END

GO

-- end of Confidentiality