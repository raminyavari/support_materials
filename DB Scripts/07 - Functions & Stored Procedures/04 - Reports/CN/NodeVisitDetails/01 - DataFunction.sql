USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CN_FN_NodeVisitDetailsReport]') 
    AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[CN_FN_NodeVisitDetailsReport]
GO

CREATE FUNCTION [dbo].[CN_FN_NodeVisitDetailsReport](
	@ApplicationID			uniqueidentifier,
	@CurrentUserID			uniqueidentifier,
	@NodeTypeID				uniqueidentifier,
	@NodeIDsTemp			GuidTableType readonly,
	@GrabSubNodeTypes		bit,
	@CreatorGroupIDsTemp	GuidTableType readonly,
	@CreatorUserIDsTemp		GuidTableType readonly,
	@DateFrom				datetime,
	@DateTo					datetime
)
RETURNS @outputTable TABLE (
	UserID		uniqueidentifier,
	FullName	nvarchar(500),
	NodeID		uniqueidentifier,
	NodeName	nvarchar(500),
	NodeTypeID	uniqueidentifier,
	NodeType	nvarchar(2000),
	VisitDate	datetime
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @NodeIDs GuidTableType
	INSERT INTO @NodeIDs (Value) SELECT Ref.Value FROM @NodeIDsTemp AS Ref

	DECLARE @CreatorGroupIDs GuidTableType
	INSERT INTO @CreatorGroupIDs (Value) SELECT Ref.Value FROM @CreatorGroupIDsTemp AS Ref

	DECLARE @CreatorUserIDs GuidTableType
	INSERT INTO @CreatorUserIDs (Value) SELECT Ref.Value FROM @CreatorUserIDsTemp AS Ref

	DECLARE @NodesCount int = (SELECT COUNT(*) FROM @NodeIDs)

	INSERT INTO @outputTable (UserID, FullName, NodeID, NodeName, NodeTypeID, NodeType, VisitDate)
	SELECT	IV.UserID, 
			LTRIM(RTRIM(ISNULL(UN.FirstName, N'') + N' ' + ISNULL(UN.LastName, N''))) AS FullName,
			ND.NodeID, 
			ND.NodeName,
			ND.NodeTypeID, 
			ND.TypeName, 
			IV.VisitDate
	FROM [dbo].[USR_ItemVisits] AS IV
		INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.Deleted = 0 AND
			(@NodeTypeID IS NULL OR ND.NodeTypeID = @NodeTypeID) AND
			(@NodesCount = 0 OR ND.NodeID IN (SELECT X.[Value] FROM @NodeIDs AS X))
		INNER JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND UN.UserID = IV.UserID
	WHERE IV.ApplicationID = @ApplicationID AND IV.ItemType = N'Node' AND
		(@DateFrom IS NULL OR IV.VisitDate >= @DateFrom) AND
		(@DateTo IS NULL OR IV.VisitDate < @DateTo)
	
	RETURN
END

GO

