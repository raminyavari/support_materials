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
	@UniqueVisitors			bit,
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
	
	IF @UniqueVisitors = 1 BEGIN
		SELECT	Ref.UserID AS UserID_Hide,
				MAX(Ref.FullName) AS FullName,
				Ref.NodeID AS NodeID_Hide,
				MAX(Ref.NodeName) AS NodeName,
				MAX(Ref.NodeAdditionalID) AS NodeAdditionalID,
				MAX(Ref.NodeType) AS NodeType,
				MAX(Ref.VisitDate) AS LastVisitDate
		FROM (
				SELECT	X.*
				FROM [dbo].[CN_FN_NodeVisitDetailsReport](@ApplicationID, @CurrentUserID, @NodeTypeID, 
					@NodeIDs, @GrabSubNodeTypes, @CreatorGroupIDs, @CreatorUserIDs, @DateFrom, @DateTo) AS X
			) AS Ref
		GROUP BY Ref.UserID, NodeID
		ORDER BY MAX(Ref.VisitDate) DESC, Ref.NodeID ASC
	END
	ELSE BEGIN
		SELECT	X.UserID AS UserID_Hide,
				X.FullName,
				X.NodeID AS NodeID_Hide,
				X.NodeName,
				X.NodeAdditionalID,
				X.NodeType,
				X.VisitDate
		FROM [dbo].[CN_FN_NodeVisitDetailsReport](@ApplicationID, @CurrentUserID, @NodeTypeID, 
			@NodeIDs, @GrabSubNodeTypes, @CreatorGroupIDs, @CreatorUserIDs, @DateFrom, @DateTo) AS X
		ORDER BY X.VisitDate DESC, X.NodeID ASC
	END

	SELECT ('{' +
		'"FullName": {"Action": "Link", "Type": "User",' +
			'"Requires": {"ID": "UserID_Hide"}' +
		'},' +
		'"NodeName": {"Action": "Link", "Type": "Node",' +
			'"Requires": {"ID": "NodeID_Hide"}' +
		'}' +
	   '}') AS Actions
END

GO