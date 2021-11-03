USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_NodeVisitDetailsReport]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_NodeVisitDetailsReport]
GO

CREATE PROCEDURE [dbo].[CN_NodeVisitDetailsReport]
	@ApplicationID			uniqueidentifier,
	@CurrentUserID			uniqueidentifier,
	@NodeTypeID				uniqueidentifier,
	@NodeIDsTemp			GuidTableType readonly,
	@GrabSubNodeTypes		bit,
	@CreatorGroupIDsTemp	GuidTableType readonly,
	@CreatorUserIDsTemp		GuidTableType readonly,
	@DateFrom				datetime,
	@DateTo					datetime
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @NodeIDs GuidTableType
	INSERT INTO @NodeIDs (Value) SELECT Ref.Value FROM @NodeIDsTemp AS Ref

	DECLARE @CreatorGroupIDs GuidTableType
	INSERT INTO @CreatorGroupIDs (Value) SELECT Ref.Value FROM @CreatorGroupIDsTemp AS Ref

	DECLARE @CreatorUserIDs GuidTableType
	INSERT INTO @CreatorUserIDs (Value) SELECT Ref.Value FROM @CreatorUserIDsTemp AS Ref

	SELECT X.*
	FROM [dbo].[CN_FN_NodeVisitDetailsReport](@ApplicationID, @CurrentUserID, @NodeTypeID, 
		@NodeIDs, @GrabSubNodeTypes, @CreatorGroupIDs, @CreatorUserIDs, @DateFrom, @DateTo) AS X

	SELECT ('{' +
		'"GroupName": {"Action": "Link", "Type": "Node",' +
			'"Requires": {"ID": "GroupID_Hide"}' +
		'},' +
		'"FullName": {"Action": "Link", "Type": "User",' +
			'"Requires": {"ID": "UserID_Hide"}' +
		'}' +
	   '}') AS Actions
END

GO