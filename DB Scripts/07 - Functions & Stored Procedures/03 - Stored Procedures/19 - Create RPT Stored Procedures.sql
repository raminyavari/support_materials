USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RPT_SetGroupLimitsForAdmins]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RPT_SetGroupLimitsForAdmins]
GO

CREATE PROCEDURE [dbo].[RPT_SetGroupLimitsForAdmins]
	@ApplicationID		uniqueidentifier,
	@NodeTypeIDsTemp	GuidTableType readonly,
	@CurrentUserID		uniqueidentifier,
	@Now				datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeTypeIDs GuidTableType
	INSERT INTO @NodeTypeIDs SELECT * FROM @NodeTypeIDsTemp 

	INSERT INTO [dbo].[RPT_GroupLimitsForAdmins] (ApplicationID, NodeTypeID, LastModifierUserID, LastModificationDate, Deleted)
	SELECT @ApplicationID, NT.[Value], @CurrentUserID, @Now, 0
	FROM @NodeTypeIDs AS NT
		LEFT JOIN [dbo].[RPT_GroupLimitsForAdmins] AS G
		ON G.ApplicationID = @ApplicationID AND G.NodeTypeID = NT.[Value]
	WHERE G.NodeTypeID IS NULL

	UPDATE G
	SET Deleted = CASE WHEN NT.[Value] IS NULL THEN 1 ELSE 0 END,
		LastModifierUserID = @CurrentUserID,
		LastModificationDate = @Now
	FROM [dbo].[RPT_GroupLimitsForAdmins] AS G
		LEFT JOIN @NodeTypeIDs AS NT
		ON NT.[Value] = G.NodeTypeID
	WHERE G.ApplicationID = @ApplicationID
	
	SELECT 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[RPT_GetGroupLimitsForAdmins]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[RPT_GetGroupLimitsForAdmins]
GO

CREATE PROCEDURE [dbo].[RPT_GetGroupLimitsForAdmins]
	@ApplicationID	uniqueidentifier
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT G.NodeTypeID AS ID
	FROM [dbo].[RPT_GroupLimitsForAdmins] AS G
		INNER JOIN [dbo].[CN_NodeTypes] AS NT
		ON NT.ApplicationID = @ApplicationID AND NT.NodeTypeID = G.NodeTypeID AND ISNULL(NT.Deleted, 0) = 0
	WHERE G.ApplicationID = @ApplicationID
END

GO

