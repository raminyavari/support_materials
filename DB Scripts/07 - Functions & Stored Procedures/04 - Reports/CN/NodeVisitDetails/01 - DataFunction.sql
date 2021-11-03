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
	UserID				uniqueidentifier,
	FullName			nvarchar(500),
	NodeID				uniqueidentifier,
	NodeName			nvarchar(500),
	NodeAdditionalID	varchar(100),
	NodeType			nvarchar(2000),
	VisitDate			datetime
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

	DECLARE @NodeTypeIDs GuidTableType

	IF @NodeTypeID IS NOT NULL BEGIN
		INSERT INTO @NodeTypeIDs ([Value])
		SELECT @NodeTypeID
	END

	IF @NodeTypeID IS NOT NULL AND @GrabSubNodeTypes = 1 BEGIN
		INSERT INTO @NodeTypeIDs ([Value])
		SELECT X.NodeTypeID
		FROM [dbo].[CN_FN_GetChildNodeTypesDeepHierarchy](@ApplicationID, @NodeTypeIDs) AS X
		WHERE X.NodeTypeID <> @NodeTypeID
	END

	DECLARE @NodeTypesCount int = (SELECT COUNT(*) FROM @NodeTypeIDs)

	DECLARE @UsersCount int = (SELECT COUNT(*) FROM @CreatorUserIDs)

	IF @UsersCount = 0 BEGIN
		INSERT INTO @CreatorUserIDs ([Value])
		SELECT DISTINCT NM.UserID
		FROM @CreatorGroupIDs AS G
			INNER JOIN [dbo].[CN_View_NodeMembers] AS NM
			ON NM.ApplicationID = @ApplicationID AND NM.NodeID = G.[Value] AND NM.IsPending = 0
	END

	SET @UsersCount = (SELECT COUNT(*) FROM @CreatorUserIDs)

	;WITH Nodes AS 
	(
		SELECT ND.NodeID, ND.NodeName, ND.NodeAdditionalID, ND.TypeName
		FROM [dbo].[CN_View_Nodes_Normal] AS ND
		WHERE ND.ApplicationID = @ApplicationID AND ND.Deleted = 0 AND
			(@NodeTypesCount = 0 OR ND.NodeTypeID IN (SELECT X.[Value] FROM @NodeTypeIDs AS X)) AND
			(@NodesCount = 0 OR ND.NodeID IN (SELECT X.[Value] FROM @NodeIDs AS X))
	),
	XNodes AS 
	(
		SELECT	ND.NodeID, 
				MAX(ND.NodeName) AS NodeName,
				MAX(ND.NodeAdditionalID) AS NodeAdditionalID,
				MAX(ND.TypeName) AS TypeName
		FROM Nodes AS ND
			LEFT JOIN [dbo].[CN_NodeCreators] AS NC
			ON @UsersCount > 0 AND NC.ApplicationID = @ApplicationID AND NC.NodeID = ND.NodeID AND NC.Deleted = 0
		WHERE @UsersCount = 0 OR NC.NodeID IS NOT NULL
		GROUP BY ND.NodeID
	)
	INSERT INTO @outputTable (UserID, FullName, NodeID, NodeName, NodeAdditionalID, NodeType, VisitDate)
	SELECT	IV.UserID, 
			LTRIM(RTRIM(ISNULL(UN.FirstName, N'') + N' ' + ISNULL(UN.LastName, N''))) AS FullName,
			ND.NodeID, 
			ND.NodeName,
			ND.NodeAdditionalID,
			ND.TypeName, 
			IV.VisitDate
	FROM [dbo].[USR_ItemVisits] AS IV
		INNER JOIN XNodes AS ND
		ON ND.NodeID = IV.ItemID
		INNER JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND UN.UserID = IV.UserID
	WHERE IV.ApplicationID = @ApplicationID AND
		(@DateFrom IS NULL OR IV.VisitDate >= @DateFrom) AND
		(@DateTo IS NULL OR IV.VisitDate < @DateTo)
	
	RETURN
END

GO

