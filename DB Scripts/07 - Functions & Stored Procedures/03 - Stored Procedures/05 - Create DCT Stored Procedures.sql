USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_CreateTree]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_CreateTree]
GO

CREATE PROCEDURE [dbo].[DCT_CreateTree]
	@ApplicationID		uniqueidentifier,
    @TreeID 			uniqueidentifier,
    @IsPrivate			bit,
    @OwnerID			uniqueidentifier,
    @Name				nvarchar(256),
    @Description		nvarchar(1000),
    @CreatorUserID		uniqueidentifier,
    @CreationDate		datetime,
    @Privacy			varchar(20),
    @IsTemplate			bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @Name = [dbo].[GFN_VerifyString](@Name)
	SET @Description = [dbo].[GFN_VerifyString](@Description)
	
	INSERT INTO [dbo].[DCT_Trees](
		ApplicationID,
		TreeID,
		IsPrivate,
		OwnerID,
		Name,
		[Description],
		CreatorUserID,
		CreationDate,
		Privacy,
		IsTemplate,
		Deleted
	)
	VALUES(
		@ApplicationID,
		@TreeID,
		@IsPrivate,
		@OwnerID,
		@Name,
		@Description,
		@CreatorUserID,
		@CreationDate,
		@Privacy,
		@IsTemplate,
		0
	)
	
    SELECT @@ROWCOUNT
END

GO



IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_ChangeTree]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_ChangeTree]
GO

CREATE PROCEDURE [dbo].[DCT_ChangeTree]
	@ApplicationID			uniqueidentifier,
    @TreeID					uniqueidentifier,
    @NewName				nvarchar(256),
    @NewDescription			nvarchar(1000),
    @LastModifierUserID		uniqueidentifier,
    @LastModificationDate	datetime,
    @IsTemplate				bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @NewName = [dbo].[GFN_VerifyString](@NewName)
	SET @NewDescription = [dbo].[GFN_VerifyString](@NewDescription)
	
	UPDATE [dbo].[DCT_Trees]
		SET Name = @NewName,
			[Description] = @NewDescription,
			LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate,
			IsTemplate = @IsTemplate
	WHERE ApplicationID = @ApplicationID AND TreeID = @TreeID
	
    SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_P_RemoveTrees]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_P_RemoveTrees]
GO

CREATE PROCEDURE [dbo].[DCT_P_RemoveTrees]
	@ApplicationID	uniqueidentifier,
    @TreeIDsTemp	GuidTableType readonly,
    @OwnerID		uniqueidentifier,
    @CurrentUserID	uniqueidentifier,
    @Now			datetime,
    @_Result		int output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @TreeIDs GuidTableType
	INSERT INTO @TreeIDs SELECT * FROM @TreeIDsTemp
	
	UPDATE T
		SET Deleted = 1,
			LastModifierUserID = @CurrentUserID,
			LastModificationDate = @Now
	FROM @TreeIDs AS IDs
		INNER JOIN [dbo].[DCT_Trees] AS T
		ON T.ApplicationID = @ApplicationID AND T.TreeID = IDs.Value AND
			((@OwnerID IS NULL AND T.OwnerID IS NULL) OR T.OwnerID = @OwnerID)
	
    SET @_Result = @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_ArithmeticDeleteTree]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_ArithmeticDeleteTree]
GO

CREATE PROCEDURE [dbo].[DCT_ArithmeticDeleteTree]
	@ApplicationID	uniqueidentifier,
    @strTreeIDs		varchar(max),
    @delimiter		char,
    @OwnerID		uniqueidentifier,
    @CurrentUserID	uniqueidentifier,
    @Now			datetime
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE @TreeIDs GuidTableType
	
	INSERT INTO @TreeIDs (Value)
	SELECT DISTINCT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strTreeIDs, @delimiter) AS Ref
	
	DECLARE @_Result int = 0
	
	EXEC [dbo].[DCT_P_RemoveTrees] @ApplicationID, @TreeIDs, 
		@OwnerID, @CurrentUserID, @Now, @_Result output
		
	IF (@_Result <> (SELECT COUNT(*) FROM @TreeIDs)) BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	SELECT @_Result
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_RecycleTree]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_RecycleTree]
GO

CREATE PROCEDURE [dbo].[DCT_RecycleTree]
	@ApplicationID	uniqueidentifier,
    @TreeID			uniqueidentifier,
    @CurrentUserID	uniqueidentifier,
    @Now			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[DCT_Trees]
		SET Deleted = 0,
			LastModifierUserID = @CurrentUserID,
			LastModificationDate = @Now
	WHERE ApplicationID = @ApplicationID AND TreeID = @TreeID
	
    SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_P_GetTreesByIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_P_GetTreesByIDs]
GO

CREATE PROCEDURE [dbo].[DCT_P_GetTreesByIDs]
	@ApplicationID	uniqueidentifier,
    @TreeIDsTemp	GuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @TreeIDs GuidTableType
	INSERT INTO @TreeIDs SELECT * FROM @TreeIDsTemp
	
	SELECT T.[TreeID] AS TreeID,
		   T.[Name] AS Name,
		   T.[Description] AS [Description],
		   T.[IsTemplate] AS IsTemplate
	FROM @TreeIDs AS ExternalIDs 
		INNER JOIN [dbo].[DCT_Trees] AS T
		ON T.ApplicationID = @ApplicationID AND ExternalIDs.Value = T.[TreeID]
	ORDER BY (CASE WHEN T.Deleted = 1 THEN T.SequenceNumber ELSE T.CreationDate END) ASC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_GetTreesByIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_GetTreesByIDs]
GO

CREATE PROCEDURE [dbo].[DCT_GetTreesByIDs]
	@ApplicationID	uniqueidentifier,
    @strTreeIDs		varchar(max),
    @delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @TreeIDs GuidTableType
	INSERT INTO @TreeIDs 
	SELECT DISTINCT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strTreeIDs, @delimiter) AS Ref
	
	UPDATE IDs
		SET Value = N.TreeID
	FROM @TreeIDs AS IDs
		INNER JOIN [dbo].[DCT_TreeNodes] AS N
		ON N.ApplicationID = @ApplicationID AND N.TreeNodeID = IDs.Value
	
	EXEC [dbo].[DCT_P_GetTreesByIDs] @ApplicationID, @TreeIDs
END

GO



IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_GetTrees]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_GetTrees]
GO

CREATE PROCEDURE [dbo].[DCT_GetTrees]
	@ApplicationID	uniqueidentifier,
    @OwnerID		uniqueidentifier,
    @Archive		bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @TreeIDs GuidTableType
	
	INSERT INTO @TreeIDs
	SELECT Ref.TreeID
	FROM [dbo].[DCT_Trees] AS Ref
	WHERE Ref.ApplicationID = @ApplicationID AND 
		((@OwnerID IS NULL AND Ref.IsPrivate = 0) OR Ref.OwnerID = @OwnerID) AND
		Ref.Deleted = ISNULL(@Archive, 0)
	
	EXEC [dbo].[DCT_P_GetTreesByIDs] @ApplicationID, @TreeIDs
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_AddTreeNode]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_AddTreeNode]
GO

CREATE PROCEDURE [dbo].[DCT_AddTreeNode]
	@ApplicationID	uniqueidentifier,
    @TreeNodeID		uniqueidentifier,
    @TreeID			uniqueidentifier,
    @ParentNodeID	uniqueidentifier,
    @Name			nvarchar(256),
    @Description	nvarchar(1000),
    @CreatorUserID	uniqueidentifier,
    @CreationDate	datetime,
    @Privacy		varchar(20)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @Name = [dbo].[GFN_VerifyString](@Name)
	SET @Description = [dbo].[GFN_VerifyString](@Description)
	
	INSERT INTO [dbo].[DCT_TreeNodes](
		ApplicationID,
		TreeNodeID,
		TreeID,
		ParentNodeID,
		Name,
		[Description],
		CreatorUserID,
		CreationDate,
		Privacy,
		Deleted
	)
	VALUES(
		@ApplicationID,
		@TreeNodeID,
		@TreeID,
		@ParentNodeID,
		@Name,
		@Description,
		@CreatorUserID,
		@CreationDate,
		@Privacy,
		0
	)
	
    SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_ChangeTreeNode]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_ChangeTreeNode]
GO

CREATE PROCEDURE [dbo].[DCT_ChangeTreeNode]
	@ApplicationID			uniqueidentifier,
    @TreeNodeID				uniqueidentifier,
    @NewName				nvarchar(256),
    @NewDescription			nvarchar(1000),
    @LastModifierUserID		uniqueidentifier,
    @LastModificationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @NewName = [dbo].[GFN_VerifyString](@NewName)
	SET @NewDescription = [dbo].[GFN_VerifyString](@NewDescription)
	
	UPDATE [dbo].[DCT_TreeNodes]
		SET Name = (CASE WHEN ISNULL(@NewName, N'') = N'' THEN Name ELSE @NewName END),
			[Description] = @NewDescription,
			LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate
	WHERE ApplicationID = @ApplicationID AND TreeNodeID = @TreeNodeID
	
    SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_P_GetTreeNodeHierarchy]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_P_GetTreeNodeHierarchy]
GO

CREATE PROCEDURE [dbo].[DCT_P_GetTreeNodeHierarchy]
	@ApplicationID	uniqueidentifier,
	@TreeNodeID		uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @TreeID uniqueidentifier = (
		SELECT TOP(1) TreeID 
		FROM [dbo].[DCT_TreeNodes] 
		WHERE ApplicationID = @ApplicationID AND TreeNodeID = @TreeNodeID
	)
 	
	;WITH hierarchy (ID, ParentID, [Level], Name)
	AS
	(
		SELECT TreeNodeID AS ID, ParentNodeID AS ParentID, 0 AS [Level], Name
		FROM [dbo].[DCT_TreeNodes]
		WHERE ApplicationID = @ApplicationID AND TreeNodeID = @TreeNodeID
		
		UNION ALL
		
		SELECT Node.TreeNodeID AS ID, Node.ParentNodeID AS ParentID, [Level] + 1, Node.Name
		FROM [dbo].[DCT_TreeNodes] AS Node
			INNER JOIN hierarchy AS HR
			ON Node.TreeNodeID = HR.ParentID
		WHERE Node.ApplicationID = @ApplicationID AND 
			Node.TreeID = @TreeID AND Node.TreeNodeID <> HR.ID AND Node.Deleted = 0
	)
	
	SELECT * 
	FROM hierarchy
	ORDER BY hierarchy.[Level] ASC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_CopyTreesOrTreeNodes]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_CopyTreesOrTreeNodes]
GO

CREATE PROCEDURE [dbo].[DCT_CopyTreesOrTreeNodes]
	@ApplicationID		uniqueidentifier,
    @TreeIDOrTreeNodeID	uniqueidentifier,
    @strCopiedIDs		varchar(max),
    @delimiter			char,
    @CurrentUserID		uniqueidentifier,
    @Now				datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @CopiedIDs GuidTableType
	
	INSERT INTO @CopiedIDs (Value)
	SELECT DISTINCT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strCopiedIDs, @delimiter) AS Ref
	
	DECLARE @TBL TABLE (ID uniqueidentifier, Name nvarchar(500), 
		ParentID uniqueidentifier, [NewID] uniqueidentifier, [Level] int, Seq int)
	
	INSERT INTO @TBL (ID, Name, ParentID, [NewID], [Level], Seq)
	SELECT Ref.NodeID, Ref.Name, Ref.ParentID, NEWID(), Ref.[Level], Ref.SequenceNumber
	FROM [dbo].[DCT_FN_GetChildNodesHierarchy](@ApplicationID, @CopiedIDs, 0) AS Ref
	
	DECLARE @TreeID uniqueidentifier = NULL
	DECLARE @TreeNodeID uniqueidentifier = NULL
	
	SELECT @TreeID = T.TreeID
	FROM [dbo].[DCT_Trees] AS T
	WHERE T.ApplicationID = @ApplicationID AND T.TreeID = @TreeIDOrTreeNodeID
	
	SELECT @TreeID = TN.TreeID, @TreeNodeID = TN.TreeNodeID
	FROM [dbo].[DCT_TreeNodes] AS TN
	WHERE TN.ApplicationID = @ApplicationID AND TN.TreeNodeID = @TreeIDOrTreeNodeID
	
	IF @TreeID IS NULL BEGIN
		SELECT CAST(NULL AS uniqueidentifier) AS ID
		SELECT -1
		RETURN
	END
	
	DECLARE @RootSeq int = 1 + ISNULL((
		SELECT MAX(TN.SequenceNumber) + COUNT(TN.TreeNodeID)
		FROM [dbo].[DCT_TreeNodes] AS TN
		WHERE TN.ApplicationID = @ApplicationID AND TN.TreeID = @TreeID AND
			(
				(@TreeNodeID IS NULL AND TN.ParentNodeID IS NULL) OR
				TN.ParentNodeID = @TreeNodeID
			)
	), 0)
	
	UPDATE X
		SET Seq = Ref.RowNumber + @RootSeq
	FROM @TBL AS X
		INNER JOIN (
			SELECT	ROW_NUMBER() OVER(ORDER BY 
						ISNULL(T.SequenceNumber, 10000) ASC, 
						T.Name ASC,
						ISNULL(ND.Seq, 10000) ASC,
						ND.Name ASC,
						TN.CreationDate ASC
					) AS RowNumber,
					TN.TreeNodeID
			FROM @TBL AS ND
				INNER JOIN [dbo].[DCT_TreeNodes] AS TN
				ON TN.ApplicationID = @ApplicationID AND TN.TreeNodeID = ND.ID
				INNER JOIN [dbo].[DCT_Trees] AS T
				ON T.ApplicationID = @ApplicationID AND T.TreeID = TN.TreeID
			WHERE ND.[Level] = 0
		) AS Ref
		ON Ref.TreeNodeID = X.ID
	
	INSERT INTO [dbo].[DCT_TreeNodes](
		ApplicationID,
		TreeNodeID,
		TreeID,
		Name,
		SequenceNumber,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	SELECT @ApplicationID, T.[NewID], @TreeID, T.Name, T.Seq, @CurrentUserID, @Now, 0
	FROM @TBL AS T
	
	UPDATE TN
		SET ParentNodeID = CASE WHEN Node.[Level] = 0 THEN @TreeNodeID ELSE Parent.[NewID] END
	FROM @TBL AS Node
		LEFT JOIN @TBL AS Parent
		ON Parent.ID = Node.ParentID
		INNER JOIN [dbo].[DCT_TreeNodes] AS TN
		ON TN.ApplicationID = @ApplicationID AND TN.TreeNodeID = Node.[NewID]
	
    SELECT T.[NewID] AS ID
    FROM @TBL AS T
    WHERE T.[Level] = 0
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_MoveTreesOrTreeNodes]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_MoveTreesOrTreeNodes]
GO

CREATE PROCEDURE [dbo].[DCT_MoveTreesOrTreeNodes]
	@ApplicationID		uniqueidentifier,
    @TreeIDOrTreeNodeID	uniqueidentifier,
    @strMovedIDs		varchar(max),
    @delimiter			char,
    @CurrentUserID		uniqueidentifier,
    @Now				datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @MovedIDs GuidTableType
	
	INSERT INTO @MovedIDs (Value)
	SELECT DISTINCT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strMovedIDs, @delimiter) AS Ref
	
	IF EXISTS(
		SELECT TOP(1) 1
		FROM @MovedIDs AS M
		WHERE M.Value = @TreeIDOrTreeNodeID
	) BEGIN
		SELECT CAST(NULL AS uniqueidentifier) AS ID
		SELECT -1, N'CannotTransferToChilds'
		RETURN
	END
	
	DECLARE @TBL TABLE (ID uniqueidentifier, Name nvarchar(500), 
		ParentID uniqueidentifier, [Level] int, Seq int)
	
	INSERT INTO @TBL (ID, Name, ParentID, [Level], Seq)
	SELECT Ref.NodeID, Ref.Name, Ref.ParentID, Ref.[Level], Ref.SequenceNumber
	FROM [dbo].[DCT_FN_GetChildNodesHierarchy](@ApplicationID, @MovedIDs, NULL) AS Ref
	
	IF EXISTS(
		SELECT TOP(1) 1
		FROM @TBL AS T
		WHERE T.ID = @TreeIDOrTreeNodeID
	) BEGIN
		SELECT CAST(NULL AS uniqueidentifier) AS ID
		SELECT -1, N'CannotTransferToChilds'
		RETURN
	END
	
	DECLARE @TreeID uniqueidentifier = NULL
	DECLARE @TreeNodeID uniqueidentifier = NULL
	
	SELECT @TreeID = T.TreeID
	FROM [dbo].[DCT_Trees] AS T
	WHERE T.ApplicationID = @ApplicationID AND T.TreeID = @TreeIDOrTreeNodeID
	
	SELECT @TreeID = TN.TreeID, @TreeNodeID = TN.TreeNodeID
	FROM [dbo].[DCT_TreeNodes] AS TN
	WHERE TN.ApplicationID = @ApplicationID AND TN.TreeNodeID = @TreeIDOrTreeNodeID
	
	IF @TreeID IS NULL BEGIN
		SELECT CAST(NULL AS uniqueidentifier) AS ID
		SELECT -1
		RETURN
	END
	
	DECLARE @RootSeq int = 1 + ISNULL((
		SELECT MAX(TN.SequenceNumber) + COUNT(TN.TreeNodeID)
		FROM [dbo].[DCT_TreeNodes] AS TN
		WHERE TN.ApplicationID = @ApplicationID AND TN.TreeID = @TreeID AND
			(
				(@TreeNodeID IS NULL AND TN.ParentNodeID IS NULL) OR
				TN.ParentNodeID = @TreeNodeID
			)
	), 0)
	
	UPDATE X
		SET Seq = Ref.RowNumber + @RootSeq
	FROM @TBL AS X
		INNER JOIN (
			SELECT	ROW_NUMBER() OVER(ORDER BY 
						ISNULL(T.SequenceNumber, 10000) ASC, 
						T.Name ASC,
						ISNULL(ND.Seq, 10000) ASC,
						ND.Name ASC,
						TN.CreationDate ASC
					) AS RowNumber,
					TN.TreeNodeID
			FROM @TBL AS ND
				INNER JOIN [dbo].[DCT_TreeNodes] AS TN
				ON TN.ApplicationID = @ApplicationID AND TN.TreeNodeID = ND.ID
				INNER JOIN [dbo].[DCT_Trees] AS T
				ON T.ApplicationID = @ApplicationID AND T.TreeID = TN.TreeID
			WHERE ND.[Level] = 0
		) AS Ref
		ON Ref.TreeNodeID = X.ID
	
	UPDATE TN
		SET TreeID = @TreeID,
			ParentNodeID = CASE WHEN Node.[Level] = 0 THEN @TreeNodeID ELSE ParentNodeID END,
			SequenceNumber = CASE WHEN Node.[Level] = 0 THEN Node.Seq ELSE SequenceNumber END,
			LastModifierUserID = @CurrentUserID,
			LastModificationDate = @Now
	FROM @TBL AS Node
		INNER JOIN [dbo].[DCT_TreeNodes] AS TN
		ON TN.ApplicationID = @ApplicationID AND TN.TreeNodeID = Node.ID
		
	UPDATE T
		SET Deleted = 1,
			LastModifierUserID = @CurrentUserID,
			LastModificationDate = @Now
	FROM @MovedIDs AS IDs
		INNER JOIN [dbo].[DCT_Trees] AS T
		ON T.ApplicationID = @ApplicationID AND T.TreeID = IDs.Value
	
    SELECT T.ID AS ID
    FROM @TBL AS T
    WHERE T.[Level] = 0
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_MoveTreeNode]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_MoveTreeNode]
GO

CREATE PROCEDURE [dbo].[DCT_MoveTreeNode]
	@ApplicationID			uniqueidentifier,
    @strTreeNodeIDs			varchar(max),
	@delimiter				char,
    @NewParentNodeID		uniqueidentifier,
    @LastModifierUserID		uniqueidentifier,
    @LastModificationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @TreeNodeIDs GuidTableType
	INSERT INTO @TreeNodeIDs
	SELECT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strTreeNodeIDs, @delimiter) AS Ref
	
	DECLARE @ParentHierarchy NodesHierarchyTableType
	
	IF @NewParentNodeID IS NOT NULL BEGIN
		INSERT INTO @ParentHierarchy
		EXEC [dbo].[DCT_P_GetTreeNodeHierarchy] @ApplicationID, @NewParentNodeID
	END
	
	IF EXISTS(
		SELECT TOP(1) 1
		FROM @ParentHierarchy AS P
			INNER JOIN @TreeNodeIDs AS N
			ON N.Value = P.NodeID
	) BEGIN
		SELECT -1, N'CannotTransferToChilds'
		RETURN
	END
	
	UPDATE TN
		SET LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate,
			ParentNodeID = @NewParentNodeID
	FROM @TreeNodeIDs AS Ref
		INNER JOIN [dbo].[DCT_TreeNodes] AS TN
		ON TN.[TreeNodeID] = Ref.Value
	WHERE TN.ApplicationID = @ApplicationID AND 
		(@NewParentNodeID IS NULL OR TN.[TreeNodeID] <> @NewParentNodeID)
	
    SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_P_RemoveTreeNodes]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_P_RemoveTreeNodes]
GO

CREATE PROCEDURE [dbo].[DCT_P_RemoveTreeNodes]
	@ApplicationID		uniqueidentifier,
    @TreeNodeIDsTemp	GuidTableType readonly,
    @TreeOwnerID		uniqueidentifier,
    @RemoveHierarchy	bit,
    @CurrentUserID		uniqueidentifier,
    @Now				datetime,
    @_Result			int output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @TreeNodeIDs GuidTableType
	INSERT INTO @TreeNodeIDs SELECT * FROM @TreeNodeIDsTemp
	
	IF ISNULL(@RemoveHierarchy, 0) = 0 BEGIN
		UPDATE TN
			SET Deleted = 1,
				LastModifierUserID = @CurrentUserID,
				LastModificationDate = @Now
		FROM @TreeNodeIDs AS Ref
			INNER JOIN [dbo].[DCT_TreeNodes] AS TN
			ON TN.ApplicationID = @ApplicationID AND 
				TN.[TreeNodeID] = Ref.Value AND TN.Deleted = 0
			INNER JOIN [dbo].[DCT_Trees] AS T
			ON T.ApplicationID = @ApplicationID AND T.TreeID = TN.TreeID AND
				((@TreeOwnerID IS NULL AND T.OwnerID IS NULL) OR T.OwnerID = @TreeOwnerID)
			
		SET @_Result = @@ROWCOUNT
		
		UPDATE TN
			SET ParentNodeID = NULL,
				LastModifierUserID = @CurrentUserID,
				LastModificationDate = @Now
		FROM [dbo].[DCT_TreeNodes] AS TN
			INNER JOIN [dbo].[DCT_Trees] AS T
			ON T.ApplicationID = @ApplicationID AND T.TreeID = TN.TreeID AND
				((@TreeOwnerID IS NULL AND T.OwnerID IS NULL) OR T.OwnerID = @TreeOwnerID)
		WHERE TN.ApplicationID = @ApplicationID AND 
			TN.ParentNodeID IN(SELECT * FROM @TreeNodeIDs) AND TN.Deleted = 0
		
		SET @_Result = MAX(@@ROWCOUNT + @_Result)
	END
	ELSE BEGIN
		UPDATE TN
			SET Deleted = 1,
				LastModifierUserID = @CurrentUserID,
				LastModificationDate = @Now
		FROM [dbo].[DCT_FN_GetChildNodesHierarchy](@ApplicationID, @TreeNodeIDs, 0) AS Ref
			INNER JOIN [dbo].[DCT_TreeNodes] AS TN
			ON TN.ApplicationID = @ApplicationID AND 
				TN.TreeNodeID = Ref.NodeID AND TN.Deleted = 0
			INNER JOIN [dbo].[DCT_Trees] AS T
			ON T.ApplicationID = @ApplicationID AND T.TreeID = TN.TreeID AND
				((@TreeOwnerID IS NULL AND T.OwnerID IS NULL) OR T.OwnerID = @TreeOwnerID)
			
		SET @_Result = @@ROWCOUNT
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_ArithmeticDeleteTreeNode]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_ArithmeticDeleteTreeNode]
GO

CREATE PROCEDURE [dbo].[DCT_ArithmeticDeleteTreeNode]
	@ApplicationID		uniqueidentifier,
    @strTreeNodeIDs		varchar(max),
    @delimiter			char,
    @TreeOwnerID		uniqueidentifier,
    @RemoveHierarchy	bit,
    @CurrentUserID		uniqueidentifier,
    @Now				datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @TreeNodeIDs GuidTableType
	
	INSERT INTO @TreeNodeIDs
	SELECT DISTINCT Ref.Value FROM GFN_StrToGuidTable(@strTreeNodeIDs, @delimiter) AS Ref
	
	DECLARE @_Result int = 0
	
	EXEC [dbo].[DCT_P_RemoveTreeNodes] @ApplicationID, @TreeNodeIDs, @TreeOwnerID, 
		@RemoveHierarchy, @CurrentUserID, @Now, @_Result output
	
	SELECT @_Result
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_P_GetTreeNodesByIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_P_GetTreeNodesByIDs]
GO

CREATE PROCEDURE [dbo].[DCT_P_GetTreeNodesByIDs]
	@ApplicationID		uniqueidentifier,
    @TreeNodeIDsTemp	KeyLessGuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @TreeNodeIDs KeyLessGuidTableType
	INSERT INTO @TreeNodeIDs (Value) SELECT Value FROM @TreeNodeIDsTemp
	
	SELECT TN.[TreeNodeID] AS TreeNodeID,
		   TN.[TreeID] AS TreeID,
		   TN.[ParentNodeID] AS ParentNodeID,
		   TN.[Name] AS Name,
		   (
				SELECT CAST(1 AS bit) 
				WHERE EXISTS(
						SELECT TOP(1)* 
						FROM [dbo].[DCT_TreeNodes] AS TN
						WHERE TN.ApplicationID = @ApplicationID AND 
							TN.ParentNodeID = Ref.Value AND TN.Deleted = 0
					)
			) AS HasChild
	FROM @TreeNodeIDs AS Ref
		INNER JOIN [dbo].[DCT_TreeNodes] AS TN
		ON TN.[TreeNodeID] = Ref.Value
	WHERE TN.ApplicationID = @ApplicationID AND TN.[Deleted] = 0
	ORDER BY Ref.SequenceNumber ASC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_GetTreeNodesByIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_GetTreeNodesByIDs]
GO

CREATE PROCEDURE [dbo].[DCT_GetTreeNodesByIDs]
	@ApplicationID		uniqueidentifier,
    @strTreeNodeIDs		varchar(max),
    @delimiter			char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @TreeNodeIDs KeyLessGuidTableType
	
	INSERT INTO @TreeNodeIDs (Value)
	SELECT DISTINCT Ref.Value 
	FROM GFN_StrToGuidTable(@strTreeNodeIDs, @delimiter) AS Ref
	
	EXEC [dbo].[DCT_P_GetTreeNodesByIDs] @ApplicationID, @TreeNodeIDs
END

GO



IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_GetTreeNodes]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_GetTreeNodes]
GO

CREATE PROCEDURE [dbo].[DCT_GetTreeNodes]
	@ApplicationID	uniqueidentifier,
    @TreeID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @TreeNodeIDs KeyLessGuidTableType
	
	INSERT INTO @TreeNodeIDs (Value)
	SELECT TreeNodeID
	FROM [dbo].[DCT_TreeNodes]
	WHERE ApplicationID = @ApplicationID AND TreeID = @TreeID AND Deleted = 0
	ORDER BY ISNULL(SequenceNumber, 100000) ASC, Name ASC, CreationDate ASC
	
	EXEC [dbo].[DCT_P_GetTreeNodesByIDs] @ApplicationID, @TreeNodeIDs
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_GetRootNodes]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_GetRootNodes]
GO

CREATE PROCEDURE [dbo].[DCT_GetRootNodes]
	@ApplicationID	uniqueidentifier,
    @TreeID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @TreeNodeIDs KeyLessGuidTableType
	
	INSERT INTO @TreeNodeIDs (Value)
	SELECT TreeNodeID
	FROM [dbo].[DCT_TreeNodes]
	WHERE ApplicationID = @ApplicationID AND TreeID = @TreeID AND Deleted = 0 AND 
		(ParentNodeID IS NULL OR ParentNodeID = TreeNodeID)
	ORDER BY ISNULL(SequenceNumber, 100000) ASC, Name ASC, CreationDate ASC
	
	EXEC [dbo].[DCT_P_GetTreeNodesByIDs] @ApplicationID, @TreeNodeIDs
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_GetChildNodes]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_GetChildNodes]
GO

CREATE PROCEDURE [dbo].[DCT_GetChildNodes]
	@ApplicationID	uniqueidentifier,
    @ParentNodeID	uniqueidentifier,
    @TreeID			uniqueidentifier,
    @SearchText		nvarchar(500)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF @TreeID IS NULL AND @ParentNodeID IS NULL RETURN
	
	DECLARE @TreeNodeIDs KeyLessGuidTableType
	
	IF ISNULL(@SearchText, N'') = N'' BEGIN
		INSERT INTO @TreeNodeIDs (Value)
		SELECT TreeNodeID
		FROM [dbo].[DCT_TreeNodes]
		WHERE ApplicationID = @ApplicationID AND Deleted = 0 AND 
			(@TreeID IS NULL OR TreeID = @TreeID) AND
			(
				(@ParentNodeID IS NULL AND ParentNodeID IS NULL) OR 
				(@ParentNodeID IS NOT NULL AND ParentNodeID = @ParentNodeID)
			)
		ORDER BY ISNULL(SequenceNumber, 100000) ASC, Name ASC, CreationDate ASC
	END
	ELSE BEGIN
		DECLARE @IDs GuidTableType
	
		IF @ParentNodeID IS NOT NULL BEGIN
			INSERT INTO @IDs (Value)
			VALUES (@ParentNodeID)
			
			INSERT INTO @IDs (Value)
			SELECT DISTINCT H.NodeID
			FROM [dbo].[DCT_FN_GetChildNodesDeepHierarchy](@ApplicationID, @IDs) AS H
			WHERE H.NodeID <> @ParentNodeID
			
			DELETE @IDs
			WHERE Value = @ParentNodeID
		END
		
		DECLARE @NodeIDsCount int = (SELECT COUNT(*) FROM @IDs)
	
		INSERT INTO @TreeNodeIDs (Value)
		SELECT X.NodeID
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY SRCH.[Rank] DESC, SRCH.[Key] ASC) AS RowNumber,
						SRCH.[Key] AS NodeID
				FROM CONTAINSTABLE([dbo].[DCT_TreeNodes], (Name), @SearchText) AS SRCH
					INNER JOIN [dbo].[DCT_TreeNodes] AS TN
					ON TN.TreeNodeID = SRCH.[Key]
					LEFT JOIN @IDs AS I
					ON I.Value = TN.TreeNodeID
				WHERE TN.ApplicationID = @ApplicationID AND TN.Deleted = 0 AND 
					(@NodeIDsCount = 0 OR I.Value IS NOT NULL) AND 
					(@TreeID IS NULL OR TN.TreeID = @TreeID)
			) AS X
		ORDER BY X.RowNumber ASC
	END
	
	EXEC [dbo].[DCT_P_GetTreeNodesByIDs] @ApplicationID, @TreeNodeIDs
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_GetParentNode]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_GetParentNode]
GO

CREATE PROCEDURE [dbo].[DCT_GetParentNode]
	@ApplicationID	uniqueidentifier,
    @TreeNodeID		uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @TreeNodeIDs KeyLessGuidTableType
	
	INSERT INTO @TreeNodeIDs (Value)
	SELECT [First].ParentNodeID
	FROM [dbo].[DCT_TreeNodes] AS [First] 
		INNER JOIN [dbo].[DCT_TreeNodes] AS [Second]
		ON [Second].ApplicationID = @ApplicationID AND 
			[Second].TreeNodeID = [First].ParentNodeID
	WHERE [First].ApplicationID = @ApplicationID AND 
		[First].TreeNodeID = @TreeNodeID AND [Second].Deleted = 0
	
	EXEC [dbo].[DCT_P_GetTreeNodesByIDs] @ApplicationID, @TreeNodeIDs
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_P_AddFiles]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_P_AddFiles]
GO

CREATE PROCEDURE [dbo].[DCT_P_AddFiles]
	@ApplicationID	uniqueidentifier,
    @OwnerID		uniqueidentifier,
    @OwnerType		varchar(20),
    @DocFilesTemp	DocFileInfoTableType readonly,
    @CurrentUserID	uniqueidentifier,
    @Now			datetime,
    @_Result		int output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @DocFiles DocFileInfoTableType
	INSERT INTO @DocFiles SELECT * FROM @DocFilesTemp
	
	UPDATE D
		SET Deleted = 0
	FROM @DocFiles AS F
		INNER JOIN [dbo].[DCT_Files] AS D
		ON D.ApplicationID = @ApplicationID AND (D.ID = F.FileID OR D.FileNameGuid = F.FileID) AND
			((F.OwnerID IS NULL AND D.OwnerID IS NULL) OR (D.OwnerID = ISNULL(@OwnerID, F.OwnerID)))
	
	INSERT INTO [dbo].[DCT_Files] (
		ApplicationID,
		ID,
		OwnerID,
		OwnerType,
		FileNameGuid,
		Extension,
		[FileName],
		MIME,
		Size,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	SELECT	@ApplicationID, 
			NEWID(),
			ISNULL(@OwnerID, F.OwnerID),
			ISNULL(@OwnerType, F.OwnerType),
			F.FileID,
			F.Extension,
			F.[FileName],
			F.MIME,
			F.Size,
			@CurrentUserID,
			@Now,
			0
	FROM @DocFiles AS F
		LEFT JOIN [dbo].[DCT_Files] AS D
		ON D.ApplicationID = @ApplicationID AND (D.ID = F.FileID OR D.FileNameGuid = F.FileID) AND
			((F.OwnerID IS NULL AND D.OwnerID IS NULL) OR (D.OwnerID = ISNULL(@OwnerID, F.OwnerID)))
	WHERE D.ID IS NULL
	
	SET @_Result = @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_P_SaveAllOwnerFiles]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_P_SaveAllOwnerFiles]
GO

CREATE PROCEDURE [dbo].[DCT_P_SaveAllOwnerFiles]
	@ApplicationID	uniqueidentifier,
    @OwnerID		uniqueidentifier,
    @OwnerType		varchar(20),
    @DocFilesTemp	DocFileInfoTableType readonly,
    @CurrentUserID	uniqueidentifier,
    @Now			datetime,
    @_Result		int output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @DocFiles DocFileInfoTableType
	INSERT INTO @DocFiles SELECT * FROM @DocFilesTemp

	IF @OwnerID IS NULL OR @OwnerType IS NULL BEGIN
		SET @_Result = -1
		RETURN
	END
	
	UPDATE D
	SET Deleted = CASE WHEN F.FileID IS NULL THEN 1 ELSE 0 END
	FROM [dbo].[DCT_Files] AS D
		LEFT JOIN @DocFiles AS F
		ON F.FileID = D.ID OR F.FileID = D.FileNameGuid
	WHERE D.ApplicationID = @ApplicationID AND D.OwnerID = @OwnerID AND D.OwnerType = @OwnerType

	SET @_Result = @@ROWCOUNT
	
	INSERT INTO [dbo].[DCT_Files] (
		ApplicationID,
		ID,
		OwnerID,
		OwnerType,
		FileNameGuid,
		Extension,
		[FileName],
		MIME,
		Size,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	SELECT	@ApplicationID, 
			NEWID(),
			ISNULL(@OwnerID, F.OwnerID),
			ISNULL(@OwnerType, F.OwnerType),
			F.FileID,
			F.Extension,
			F.[FileName],
			F.MIME,
			F.Size,
			@CurrentUserID,
			@Now,
			0
	FROM @DocFiles AS F
		LEFT JOIN [dbo].[DCT_Files] AS D
		ON D.ApplicationID = @ApplicationID AND (D.ID = F.FileID OR D.FileNameGuid = F.FileID) AND
			D.OwnerID = ISNULL(@OwnerID, F.OwnerID)
	WHERE D.ID IS NULL
	
	SET @_Result = @@ROWCOUNT + @_Result
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_AddFiles]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_AddFiles]
GO

CREATE PROCEDURE [dbo].[DCT_AddFiles]
	@ApplicationID	uniqueidentifier,
    @OwnerID		uniqueidentifier,
    @OwnerType		varchar(50),
    @DocFilesTemp	DocFileInfoTableType readonly,
    @CurrentUserID	uniqueidentifier,
    @Now			datetime
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @DocFiles DocFileInfoTableType
	INSERT INTO @DocFiles SELECT * FROM @DocFilesTemp
	
	DECLARE @_Result int
	
	EXEC [dbo].[DCT_P_AddFiles] @ApplicationID, @OwnerID, @OwnerType, @DocFiles,
		@CurrentUserID, @Now, @_Result output
	
	SELECT @_Result
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_P_RemoveOwnerFiles]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_P_RemoveOwnerFiles]
GO

CREATE PROCEDURE [dbo].[DCT_P_RemoveOwnerFiles]
	@ApplicationID	uniqueidentifier,
    @OwnerID		uniqueidentifier,
    @_Result		int output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM [dbo].[DCT_Files]
		WHERE ApplicationID = @ApplicationID AND OwnerID = @OwnerID AND Deleted = 0
	) BEGIN
		UPDATE [dbo].[DCT_Files]
			SET Deleted = 1
		WHERE ApplicationID = @ApplicationID AND OwnerID = @OwnerID AND Deleted = 0
		
		SET @_Result = @@ROWCOUNT
	END
	ELSE BEGIN
		SET @_Result = 1
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_P_RemoveOwnersFiles]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_P_RemoveOwnersFiles]
GO

CREATE PROCEDURE [dbo].[DCT_P_RemoveOwnersFiles]
	@ApplicationID	uniqueidentifier,
    @OwnerIDsTemp	GuidTableType readonly,
    @_Result		int output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @OwnerIDs GuidTableType
	INSERT INTO @OwnerIDs SELECT * FROM @OwnerIDsTemp
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM @OwnerIDs AS IDs
			INNER JOIN [dbo].[DCT_Files] AS F
			ON F.ApplicationID = @ApplicationID AND F.OwnerID = IDs.Value AND F.Deleted = 0
	) BEGIN
		UPDATE F
			SET Deleted = 1
		FROM @OwnerIDs AS IDs
			INNER JOIN [dbo].[DCT_Files] AS F
			ON F.ApplicationID = @ApplicationID AND F.OwnerID = IDs.Value AND F.Deleted = 0
		
		SET @_Result = @@ROWCOUNT
	END
	ELSE BEGIN
		SET @_Result = 1
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_RenameFile]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_RenameFile]
GO

CREATE PROCEDURE [dbo].[DCT_RenameFile]
	@ApplicationID	uniqueidentifier,
    @FileID			uniqueidentifier,
    @Name			nvarchar(255)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE AF
		SET [FileName] = [dbo].[GFN_VerifyString](ISNULL(@Name, N'file'))
	FROM [dbo].[DCT_Files] AS AF
	WHERE AF.ApplicationID = @ApplicationID AND  (AF.[ID] = @FileID OR AF.[FileNameGuid] = @FileID)
		
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_ArithmeticDeleteFiles]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_ArithmeticDeleteFiles]
GO

CREATE PROCEDURE [dbo].[DCT_ArithmeticDeleteFiles]
	@ApplicationID	uniqueidentifier,
	@OwnerID		uniqueidentifier,
    @strFileIDs		varchar(max),
    @delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @FileIDs GuidTableType
	INSERT INTO @FileIDs
	SELECT DISTINCT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strFileIDs, @delimiter) AS Ref
	
	IF @OwnerID IS NULL BEGIN
		UPDATE AF
			SET Deleted = 1
		FROM @FileIDs AS ExternalIDs
			INNER JOIN [dbo].[DCT_Files] AS AF
			ON AF.ApplicationID = @ApplicationID AND 
				(AF.[ID] = ExternalIDs.Value OR AF.[FileNameGuid] = ExternalIDs.Value)
	END
	ELSE BEGIN
		UPDATE AF
			SET Deleted = 1
		FROM @FileIDs AS ExternalIDs
			INNER JOIN [dbo].[DCT_Files] AS AF
			ON AF.[ID] = ExternalIDs.Value OR AF.[FileNameGuid] = ExternalIDs.Value
		WHERE AF.ApplicationID = @ApplicationID AND AF.OwnerID = @OwnerID AND AF.Deleted = 0
	END
		
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_CopyFile]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_CopyFile]
GO

CREATE PROCEDURE [dbo].[DCT_CopyFile]
	@ApplicationID	uniqueidentifier,
	@OwnerID		uniqueidentifier,
    @FileID			uniqueidentifier,
    @OwnerType		varchar(50),
    @CurrentUserID	uniqueidentifier,
    @Now			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM [dbo].[DCT_Files] AS AF
		WHERE AF.ApplicationID = @ApplicationID AND 
			AF.OwnerID = @OwnerID AND (AF.ID = @FileID OR AF.FileNameGuid = @FileID)
	) BEGIN
		UPDATE AF
			SET Deleted = 0
		FROM [dbo].[DCT_Files] AS AF
		WHERE AF.ApplicationID = @ApplicationID AND 
			AF.OwnerID = @OwnerID AND (AF.ID = @FileID OR AF.FileNameGuid = @FileID)
		
		SELECT @@ROWCOUNT
	END
	ELSE BEGIN
		INSERT INTO [dbo].[DCT_Files] (
			ApplicationID,
			ID,
			OwnerID,
			OwnerType,
			FileNameGuid,
			Extension,
			[FileName],
			MIME,
			Size,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		SELECT TOP(1) 
			@ApplicationID, 
			NEWID(), 
			@OwnerID,
			@OwnerType,
			AF.FileNameGuid, 
			AF.Extension, 
			AF.[FileName], 
			AF.MIME, 
			AF.Size, 
			@CurrentUserID,
			@Now,
			0
		FROM [dbo].[DCT_Files] AS AF
		WHERE AF.ApplicationID = @ApplicationID AND 
			(AF.ID = @FileID OR AF.FileNameGuid = @FileID)
	
		SELECT @@ROWCOUNT
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_P_CopyAttachments]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_P_CopyAttachments]
GO

CREATE PROCEDURE [dbo].[DCT_P_CopyAttachments]
	@ApplicationID	uniqueidentifier,
	@FromOwnerID	uniqueidentifier,
    @ToOwnerID		uniqueidentifier,
    @ToOwnerType	varchar(50),
    @CurrentUserID	uniqueidentifier,
    @Now			datetime,
    @_Result		int output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	INSERT INTO [dbo].[DCT_Files] (
		ApplicationID,
		ID,
		OwnerID,
		OwnerType,
		FileNameGuid,
		Extension,
		[FileName],
		MIME,
		Size,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	SELECT	@ApplicationID,
			NEWID(),
			@ToOwnerID,
			@ToOwnerType,
			AF.FileNameGuid,
			AF.Extension,
			AF.[FileName],
			AF.MIME,
			AF.Size,
			@CurrentUserID,
			@Now,
			AF.Deleted
	FROM [dbo].[DCT_Files] AS AF
	WHERE AF.ApplicationID = @ApplicationID AND AF.OwnerID = @FromOwnerID AND AF.Deleted = 0
	
	SET @_Result = @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_P_GetFilesByIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_P_GetFilesByIDs]
GO

CREATE PROCEDURE [dbo].[DCT_P_GetFilesByIDs]
	@ApplicationID	uniqueidentifier,
    @FileIDsTemp	GuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @FileIDs GuidTableType
	INSERT INTO @FileIDs SELECT * FROM @FileIDsTemp
	
	SELECT AF.OwnerID,
		   AF.OwnerType,
		   AF.FileNameGuid AS FileID,
		   AF.[FileName],
		   AF.Extension,
		   AF.MIME,
		   AF.Size
	FROM @FileIDs AS ExternalIDs
		INNER JOIN [dbo].[DCT_Files] AS AF
		ON AF.ApplicationID = @ApplicationID AND 
			ExternalIDs.Value = AF.ID OR ExternalIDs.Value = AF.FileNameGuid
	ORDER BY AF.CreationDate ASC, AF.[FileName] ASC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_GetOwnerFiles]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_GetOwnerFiles]
GO

CREATE PROCEDURE [dbo].[DCT_GetOwnerFiles]
	@ApplicationID	uniqueidentifier,
    @strOwnerIDs	varchar(max),
    @delimiter		char,
    @Type			varchar(50)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @OwnerIDs GuidTableType
	INSERT INTO @OwnerIDs
	SELECT DISTINCT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strOwnerIDs, @delimiter) AS Ref
	
	DECLARE @FileIDs GuidTableType
	
	INSERT INTO @FileIDs
	SELECT AF.ID
	FROM @OwnerIDs AS ExternalIDs
		INNER JOIN [dbo].[DCT_Files] AS AF
		ON AF.ApplicationID = @ApplicationID AND 
			AF.OwnerID = ExternalIDs.Value AND AF.Deleted = 0 AND
			(@Type IS NULL OR AF.OwnerType = @Type)
		
	EXEC [dbo].[DCT_P_GetFilesByIDs] @ApplicationID, @FileIDs
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_GetFilesByIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_GetFilesByIDs]
GO

CREATE PROCEDURE [dbo].[DCT_GetFilesByIDs]
	@ApplicationID	uniqueidentifier,
    @strFileIDs		varchar(max),
    @delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @FileIDs GuidTableType
	INSERT INTO @FileIDs
	SELECT DISTINCT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strFileIDs, @delimiter) AS Ref
	
	EXEC [dbo].[DCT_P_GetFilesByIDs] @ApplicationID, @FileIDs
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_GetFileOwnerNodes]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_GetFileOwnerNodes]
GO

CREATE PROCEDURE [dbo].[DCT_GetFileOwnerNodes]
	@ApplicationID	uniqueidentifier,
	@strFileIDs		varchar(max),
	@delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @IDs GuidTableType
	
	INSERT INTO @IDs (Value)
	SELECT DISTINCT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strFileIDs, @delimiter) AS Ref
	
	SELECT Ref.FileID, Ref.NodeID, Ref.NodeName AS [Name], Ref.NodeType, Ref.CreationDate, Ref.Size
	FROM [dbo].[DCT_FN_GetFileOwnerNodes](@ApplicationID, @IDs) AS Ref
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_GetNotExtractedFiles]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_GetNotExtractedFiles]
GO

CREATE PROCEDURE [dbo].[DCT_GetNotExtractedFiles]
	@ApplicationID		uniqueidentifier,
	@AllowedExtensions	varchar(max),
	@Delimiter			char,
	@Count				int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Ext stringTableType
	
	INSERT INTO @Ext 
	SELECT LOWER(Ref.Value) 
	FROM dbo.GFN_StrToStringTable(@AllowedExtensions,@Delimiter) AS Ref
	
	DECLARE @FileIDs GuidTableType
	
	INSERT INTO @FileIDs (Value)
	SELECT TOP (ISNULL(@Count, 20)) AF.ID
	FROM @Ext AS Ex
		INNER JOIN [dbo].[DCT_Files] AS AF
		ON Ex.Value = LOWER(AF.Extension)
		LEFT JOIN [dbo].[DCT_FileContents] AS FC
		ON FC.ApplicationID = @ApplicationID AND FC.FileID = AF.FileNameGuid
	WHERE AF.ApplicationID = @ApplicationID AND AF.Deleted = 0 AND FC.FileID IS NULL AND 
		(AF.OwnerType = N'Node' OR AF.OwnerType = N'WikiContent' OR 
			AF.OwnerType = N'FormElement')
		
	EXEC [dbo].[DCT_P_GetFilesByIDs] @ApplicationID, @FileIDs
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_SaveFileContent]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_SaveFileContent]
GO

CREATE PROCEDURE [dbo].[DCT_SaveFileContent]
	@ApplicationID	uniqueidentifier,
	@FileID			UNIQUEIDENTIFIER,
	@Content		NVARCHAR(MAX),
	@NotExtractable BIT,
	@FileNotFount	BIT,
	@Duration		BIGINT,
	@ExtractionDate DATETIME,
	@Error			NVARCHAR(MAX)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @Content = [dbo].[GFN_VerifyString](ISNULL(@Content, N''))
	
    INSERT INTO DCT_FileContents (
		ApplicationID,
		FileID, 
		Content, 
		NotExtractable,
		FileNotFound, 
		Duration, 
		ExtractionDate, 
		Error
	)
    VALUES (@ApplicationID, @FileID, @Content, @NotExtractable, @FileNotFount, 
		@Duration , @ExtractionDate, @Error)
    
    SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_GetTreeNodeHierarchy]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_GetTreeNodeHierarchy]
GO

CREATE PROCEDURE [dbo].[DCT_GetTreeNodeHierarchy]
	@ApplicationID	uniqueidentifier,
	@TreeNodeID		uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	;WITH hierarchy (ID, ParentID, [Level], Name)
	AS
	(
		SELECT TreeNodeID AS ID, ParentNodeID, 0 AS [Level], Name
		FROM [dbo].[DCT_TreeNodes]
		WHERE ApplicationID = @ApplicationID AND TreeNodeID = @TreeNodeID
		
		UNION ALL
		
		SELECT TN.TreeNodeID AS ID, TN.ParentNodeID, [Level] + 1, TN.Name
		FROM [dbo].[DCT_TreeNodes] AS TN
			INNER JOIN hierarchy AS HR
			ON TN.TreeNodeID = HR.ParentID
		WHERE TN.ApplicationID = @ApplicationID AND TN.TreeNodeID <> HR.ID AND TN.Deleted = 0
	)
	
	SELECT * FROM hierarchy
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_SetTreeNodesOrder]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_SetTreeNodesOrder]
GO

CREATE PROCEDURE [dbo].[DCT_SetTreeNodesOrder]
	@ApplicationID	uniqueidentifier,
	@strTreeNodeIDs	varchar(max),
	@delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @TreeNodeIDs TABLE (
		SequenceNo int identity(1, 1) primary key, 
		TreeNodeID uniqueidentifier
	)
	
	INSERT INTO @TreeNodeIDs (TreeNodeID)
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strTreeNodeIDs, @delimiter) AS Ref
	
	DECLARE @ParentNodeID uniqueidentifier = NULL, @TreeID uniqueidentifier = NULL
	
	SELECT TOP(1) @ParentNodeID = ParentNodeID, @TreeID = TreeID
	FROM [dbo].[DCT_TreeNodes]
	WHERE ApplicationID = @ApplicationID AND 
		TreeNodeID = (SELECT TOP (1) Ref.TreeNodeID FROM @TreeNodeIDs AS Ref)
	
	INSERT INTO @TreeNodeIDs (TreeNodeID)
	SELECT TN.TreeNodeID
	FROM @TreeNodeIDs AS Ref
		RIGHT JOIN [dbo].[DCT_TreeNodes] AS TN
		ON TN.ApplicationID = @ApplicationID AND TN.TreeNodeID = Ref.TreeNodeID
	WHERE TN.ApplicationID = @ApplicationID AND TN.TreeID = @TreeID AND (
			(TN.ParentNodeID IS NULL AND @ParentNodeID IS NULL) OR 
			TN.ParentNodeID = @ParentNodeID
		) AND Ref.TreeNodeID IS NULL
	ORDER BY TN.SequenceNumber
	
	UPDATE [dbo].[DCT_TreeNodes]
		SET SequenceNumber = Ref.SequenceNo
	FROM @TreeNodeIDs AS Ref
		INNER JOIN [dbo].[DCT_TreeNodes] AS TN
		ON TN.TreeNodeID = Ref.TreeNodeID
	WHERE TN.ApplicationID = @ApplicationID AND TN.TreeID = @TreeID AND (
			(TN.ParentNodeID IS NULL AND @ParentNodeID IS NULL) OR 
			TN.ParentNodeID = @ParentNodeID
		)
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_IsPrivateTree]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_IsPrivateTree]
GO

CREATE PROCEDURE [dbo].[DCT_IsPrivateTree]
	@ApplicationID		uniqueidentifier,
	@TreeIDOrTreeNodeID	uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT CAST(1 AS bit)
	WHERE EXISTS(
			SELECT TOP(1) TreeID
			FROM [dbo].[DCT_Trees]
			WHERE ApplicationID = @ApplicationID AND 
				TreeID = @TreeIDOrTreeNodeID AND IsPrivate = 1
		) OR EXISTS(
			SELECT TOP(1) N.TreeNodeID
			FROM [dbo].[DCT_TreeNodes] AS N
				INNER JOIN [dbo].[DCT_Trees] AS T
				ON T.ApplicationID = @ApplicationID AND T.TreeID = N.TreeID
			WHERE N.ApplicationID = @ApplicationID AND 
				N.TreeNodeID = @TreeIDOrTreeNodeID AND T.IsPrivate = 1
		)
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_AddOwnerTree]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_AddOwnerTree]
GO

CREATE PROCEDURE [dbo].[DCT_AddOwnerTree]
	@ApplicationID	uniqueidentifier,
	@OwnerID		uniqueidentifier,
	@TreeID			uniqueidentifier,
	@CurrentUserID	uniqueidentifier,
	@Now			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM [dbo].[DCT_TreeOwners]
		WHERE ApplicationID = @ApplicationID AND
			OwnerID = @OwnerID AND TreeID = @TreeID
	) BEGIN
		UPDATE [dbo].[DCT_TreeOwners]
			SET Deleted = 0,
				LastModifierUserID = @CurrentUserID,
				LastModificationDate = @Now
		WHERE ApplicationID = @ApplicationID AND 
			OwnerID = @OwnerID AND TreeID = @TreeID
	END
	ELSE BEGIN
		INSERT INTO [dbo].[DCT_TreeOwners](
			ApplicationID,
			OwnerID,
			TreeID,
			UniqueID,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES(
			@ApplicationID,
			@OwnerID,
			@TreeID,
			NEWID(),
			@CurrentUserID,
			@Now,
			0
		)
	END
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_ArithmeticDeleteOwnerTree]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_ArithmeticDeleteOwnerTree]
GO

CREATE PROCEDURE [dbo].[DCT_ArithmeticDeleteOwnerTree]
	@ApplicationID	uniqueidentifier,
	@OwnerID		uniqueidentifier,
	@TreeID			uniqueidentifier,
	@CurrentUserID	uniqueidentifier,
	@Now			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[DCT_TreeOwners]
		SET Deleted = 1,
			LastModifierUserID = @CurrentUserID,
			LastModificationDate = @Now
	WHERE ApplicationID = @ApplicationID AND 
		OwnerID = @OwnerID AND TreeID = @TreeID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_GetTreeOwnerID]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_GetTreeOwnerID]
GO

CREATE PROCEDURE [dbo].[DCT_GetTreeOwnerID]
	@ApplicationID		uniqueidentifier,
	@TreeIDOrTreeNodeID	uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @TreeIDOrTreeNodeID = ISNULL((
		SELECT TOP(1) TreeID
		FROM [dbo].[DCT_TreeNodes]
		WHERE ApplicationID = @ApplicationID AND TreeNodeID = @TreeIDOrTreeNodeID
	), @TreeIDOrTreeNodeID)
	
	SELECT TOP(1) OwnerID AS ID
	FROM [dbo].[DCT_Trees]
	WHERE TreeID = @TreeIDOrTreeNodeID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_GetOwnerTrees]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_GetOwnerTrees]
GO

CREATE PROCEDURE [dbo].[DCT_GetOwnerTrees]
	@ApplicationID	uniqueidentifier,
	@OwnerID		uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @TreeIDs GuidTableType
	
	INSERT INTO @TreeIDs
	SELECT TreeID
	FROM [dbo].[DCT_TreeOwners]
	WHERE ApplicationID = @ApplicationID AND OwnerID = @OwnerID AND Deleted = 0
	
	EXEC [dbo].[DCT_P_GetTreesByIDs] @ApplicationID, @TreeIDs
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_CloneTrees]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_CloneTrees]
GO

CREATE PROCEDURE [dbo].[DCT_CloneTrees]
	@ApplicationID	uniqueidentifier,
	@strTreeIDs		varchar(max),
	@delimiter		char,
	@OwnerID		uniqueidentifier,
	@AllowMultiple	bit,
	@CurrentUserID	uniqueidentifier,
	@Now			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @TreeIDs TABLE (
		TreeID uniqueidentifier, 
		TreeID_New uniqueidentifier,
		AlreadyCreated bit,
		Seq int IDENTITY(1, 1)
	)

	INSERT INTO @TreeIDs (TreeID, TreeID_New, AlreadyCreated)
	SELECT	Ref.Value, 
			ISNULL(T.TreeID, NEWID()), 
			CASE WHEN T.TreeID IS NULL THEN 0 ELSE 1 END
	FROM [dbo].[GFN_StrToGuidTable](@strTreeIDs, @delimiter) AS Ref
		LEFT JOIN [dbo].[DCT_Trees] AS T
		ON T.ApplicationID = @ApplicationID AND T.OwnerID = @OwnerID AND 
			T.RefTreeID = Ref.Value AND ISNULL(@AllowMultiple, 0) = 0

	INSERT INTO [dbo].[DCT_Trees] (
		ApplicationID,
		TreeID,
		RefTreeID,
		IsPrivate,
		OwnerID,
		Name,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	SELECT	T.ApplicationID, 
			ID.TreeID_New, 
			ID.TreeID, 
			CASE WHEN @OwnerID IS NULL THEN 0 ELSE 1 END, 
			@OwnerID, 
			T.Name, 
			@CurrentUserID, 
			@Now, 
			0
	FROM @TreeIDs AS ID
		INNER JOIN [dbo].[DCT_Trees] AS T
		ON T.ApplicationID = @ApplicationID AND T.TreeID = ID.TreeID
	WHERE ID.AlreadyCreated = 0

	DECLARE @TreeNodes TABLE (
		TreeID uniqueidentifier, 
		ID uniqueidentifier, 
		ParentID uniqueidentifier,
		TreeID_New uniqueidentifier, 
		ID_New uniqueidentifier, 
		ParentID_New uniqueidentifier
	)
		
	INSERT INTO @TreeNodes (TreeID, ID, ParentID, TreeID_New, ID_New)
	SELECT N.TreeID, N.TreeNodeID, N.ParentNodeID, ID.TreeID_New, NEWID()
	FROM @TreeIDs AS ID
		INNER JOIN [dbo].[DCT_TreeNodes] AS N
		ON N.ApplicationID = @ApplicationID AND 
			N.TreeID = ID.TreeID AND N.Deleted = 0
	WHERE ID.AlreadyCreated = 0

	UPDATE T
		SET ParentID_New = P.ID_New
	FROM @TreeNodes AS T
		INNER JOIN @TreeNodes AS P
		ON P.TreeID = T.TreeID AND P.ID = T.ParentID

	INSERT INTO [dbo].[DCT_TreeNodes] (
		ApplicationID,
		TreeNodeID,
		TreeID,
		Name,
		CreatorUserID,
		CreationDate,
		SequenceNumber,
		Deleted
	)
	SELECT @ApplicationID, T.ID_New, T.TreeID_New, 
		N.Name, @CurrentUserID, @Now, N.SequenceNumber, 0
	FROM @TreeNodes AS T
		INNER JOIN [dbo].[DCT_TreeNodes] AS N
		ON N.ApplicationID = @ApplicationID AND N.TreeNodeID = T.ID

	UPDATE N
		SET ParentNodeID = T.ParentID_New
	FROM @TreeNodes AS T
		INNER JOIN [dbo].[DCT_TreeNodes] AS N
		ON N.ApplicationID = @ApplicationID AND N.TreeNodeID = T.ID_New
	WHERE T.ParentID_New IS NOT NULL AND T.ID_New <> T.ParentID_New

	DECLARE @IDs GuidTableType
	
	INSERT INTO @IDs (Value)
	SELECT T.TreeID_New
	FROM @TreeIDs AS T

	EXEC [dbo].[DCT_P_GetTreesByIDs] @ApplicationID, @IDs
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_P_AddTreeNodeContents]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_P_AddTreeNodeContents]
GO

CREATE PROCEDURE [dbo].[DCT_P_AddTreeNodeContents]
	@ApplicationID	uniqueidentifier,
	@TreeNodeID		uniqueidentifier,
	@NodeIDsTemp	GuidTableType readonly,
	@RemoveFrom		uniqueidentifier,
	@CurrentUserID	uniqueidentifier,
	@Now			datetime,
	@_Result		int output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeIDs GuidTableType
	INSERT INTO @NodeIDs SELECT * FROM @NodeIDsTemp

	IF @RemoveFrom IS NOT NULL AND @RemoveFrom <> @TreeNodeID BEGIN
		UPDATE C
			SET Deleted = 1,
				LastModifierUserID = @CurrentUserID,
				LastModificationDate = @Now
		FROM @NodeIDs AS IDs
			INNER JOIN [dbo].[DCT_TreeNodeContents] AS C
			ON C.ApplicationID = @ApplicationID AND C.TreeNodeID = @RemoveFrom AND 
				C.NodeID = IDs.Value AND C.Deleted = 0
	END
	
	UPDATE C
		SET Deleted = 0,
			LastModifierUserID = @CurrentUserID,
			LastModificationDate = @Now
	FROM @NodeIDs AS IDs
		INNER JOIN [dbo].[DCT_TreeNodeContents] AS C
		ON C.ApplicationID = @ApplicationID AND 
			C.TreeNodeID = @TreeNodeID AND C.NodeID = IDs.Value
			
	INSERT INTO [dbo].[DCT_TreeNodeContents] (
		ApplicationID,
		TreeNodeID,
		NodeID,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	SELECT @ApplicationID, @TreeNodeID, IDs.Value, @CurrentUserID, @Now, 0
	FROM @NodeIDs AS IDs
		LEFT JOIN [dbo].[DCT_TreeNodeContents] AS C
		ON C.ApplicationID = @ApplicationID AND 
			C.TreeNodeID = @TreeNodeID AND C.NodeID = IDs.Value
	WHERE C.TreeNodeID IS NULL
	
	SET @_Result = 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_AddTreeNodeContents]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_AddTreeNodeContents]
GO

CREATE PROCEDURE [dbo].[DCT_AddTreeNodeContents]
	@ApplicationID	uniqueidentifier,
	@TreeNodeID		uniqueidentifier,
	@strNodeIDs		varchar(max),
	@delimiter		char,
	@RemoveFrom		uniqueidentifier,
	@CurrentUserID	uniqueidentifier,
	@Now			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @NodeIDs GuidTableType
	
	INSERT INTO @NodeIDs (Value)
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strNodeIDs, @delimiter) AS Ref
	
	DECLARE @_Result int = 0
	
	EXEC [dbo].[DCT_P_AddTreeNodeContents] @ApplicationID, @TreeNodeID, @NodeIDs, 
		@RemoveFrom, @CurrentUserID, @Now, @_Result output
		
	SELECT @_Result
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_P_RemoveTreeNodeContents]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_P_RemoveTreeNodeContents]
GO

CREATE PROCEDURE [dbo].[DCT_P_RemoveTreeNodeContents]
	@ApplicationID	uniqueidentifier,
	@TreeNodeID		uniqueidentifier,
	@NodeIDsTemp	GuidTableType readonly,
	@CurrentUserID	uniqueidentifier,
	@Now			datetime,
	@_Result		int output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeIDs GuidTableType
	INSERT INTO @NodeIDs SELECT * FROM @NodeIDsTemp

	UPDATE C
		SET Deleted = 1,
			LastModifierUserID = @CurrentUserID,
			LastModificationDate = @Now
	FROM @NodeIDs AS IDs
		INNER JOIN [dbo].[DCT_TreeNodeContents] AS C
		ON C.ApplicationID = @ApplicationID AND 
			C.TreeNodeID = @TreeNodeID AND C.NodeID = IDs.Value
	
	SET @_Result = @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DCT_RemoveTreeNodeContents]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DCT_RemoveTreeNodeContents]
GO

CREATE PROCEDURE [dbo].[DCT_RemoveTreeNodeContents]
	@ApplicationID	uniqueidentifier,
	@TreeNodeID		uniqueidentifier,
	@strNodeIDs		varchar(max),
	@delimiter		char,
	@CurrentUserID	uniqueidentifier,
	@Now			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @NodeIDs GuidTableType
	
	INSERT INTO @NodeIDs (Value)
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strNodeIDs, @delimiter) AS Ref
	
	DECLARE @_Result int = 0
	
	EXEC [dbo].[DCT_P_RemoveTreeNodeContents] @ApplicationID, @TreeNodeID, 
		@NodeIDs, @CurrentUserID, @Now, @_Result output
	
	SELECT @_Result
END

GO