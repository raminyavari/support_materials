USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_InitializeNodeTypes]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_InitializeNodeTypes]
GO

CREATE PROCEDURE [dbo].[CN_P_InitializeNodeTypes]
	@ApplicationID	uniqueidentifier,
	@Now			datetime,
	@_Result		int output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @CurNodeTypesCount int = (
		SELECT COUNT(*) 
		FROM [dbo].[CN_NodeTypes] 
		WHERE ApplicationID = @ApplicationID AND ISNUMERIC(ISNULL(AdditionalID, N'__')) = 1
	)
	
	IF @CurNodeTypesCount > 2 BEGIN
		SELECT 1
		RETURN
	END

	DECLARE @UserID uniqueidentifier = (
		SELECT TOP(1) UserID
		FROM [dbo].[Users_Normal] AS UN
		WHERE UN.ApplicationID = @ApplicationID AND LOWER(UN.UserName) = N'admin'
	)

	SET @Now = ISNULL(@Now, GETDATE())

	DECLARE @NodeTypes Table (AdditionalID varchar(20), Name nvarchar(500))

	INSERT INTO @NodeTypes (AdditionalID, Name)
	VALUES ('1', N'حوزه دانش'), ('2', N'پروژه'), ('3', N'فرآيند'), ('4', N'انجمن دانايي'), 
		('5', N'دانش'), ('6', N'واحد سازمانی'), ('7', N'تخصص'), ('11', N'تگ')

	INSERT INTO [dbo].[CN_NodeTypes] (
		[ApplicationID],
		[NodeTypeID], 
		[Name], 
		[Deleted], 
		[CreatorUserID], 
		[CreationDate],
		[AdditionalID]
	) 
	SELECT  @ApplicationID, 
			NEWID(), 
			[dbo].[GFN_VerifyString](NT.Name), 
			0, 
			@UserID, 
			@Now, 
			NT.AdditionalID
	FROM @NodeTypes AS NT
		LEFT JOIN [dbo].[CN_NodeTypes] AS T
		ON T.ApplicationID = @ApplicationID AND T.AdditionalID = NT.AdditionalID
	WHERE T.NodeTypeID IS NULL
	
	
	DECLARE @KnowledgeTypes Table (AdditionalID varchar(20), Name nvarchar(500))

	INSERT INTO @KnowledgeTypes (AdditionalID, Name)
	VALUES ('8', N'مهارت'), ('9', N'تجربه'), ('10', N'مستند')
	
	DECLARE @KnowledgeTypeID uniqueidentifier = (
		SELECT TOP(1) NodeTypeID
		FROM [dbo].[CN_NodeTypes]
		WHERE ApplicationID = @ApplicationID AND AdditionalID = '5'
	)
	
	IF @KnowledgeTypeID IS NOT NULL BEGIN
		INSERT INTO [dbo].[CN_NodeTypes] (
			[ApplicationID],
			[NodeTypeID], 
			[Name], 
			[Deleted], 
			[CreatorUserID], 
			[CreationDate],
			[AdditionalID],
			[ParentID]
		) 
		SELECT  @ApplicationID, 
				NEWID(), 
				[dbo].[GFN_VerifyString](NT.Name), 
				0, 
				@UserID, 
				@Now, 
				NT.AdditionalID,
				@KnowledgeTypeID
		FROM @KnowledgeTypes AS NT
			LEFT JOIN [dbo].[CN_NodeTypes] AS T
			ON T.ApplicationID = @ApplicationID AND T.AdditionalID = NT.AdditionalID
		WHERE T.NodeTypeID IS NULL	
	END

	SET @_Result = 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_InitializeRelationTypes]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_InitializeRelationTypes]
GO

CREATE PROCEDURE [dbo].[CN_P_InitializeRelationTypes]
	@ApplicationID	uniqueidentifier,
	@_Result		int	output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @TBL Table(AdditionalID int, Name nvarchar(100))
	
	INSERT INTO @TBL (AdditionalID, Name)
	VALUES	(1,	N'شمول پدری'),
			(2,	N'شمول فرزندی'),
			(3,	N'ربط')
	
	INSERT INTO [dbo].[CN_Properties] (ApplicationID, PropertyID, AdditionalID, Name, Deleted)
	SELECT @ApplicationID, NEWID(), T.AdditionalID, T.Name, 0
	FROM @TBL AS T
		LEFT JOIN [dbo].[CN_Properties] AS P
		ON P.ApplicationID = @ApplicationID AND P.AdditionalID = T.AdditionalID
	WHERE P.PropertyID IS NULL
	
	SET @_Result = 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_Initialize]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_Initialize]
GO

CREATE PROCEDURE [dbo].[CN_Initialize]
	@ApplicationID	uniqueidentifier,
	@Now			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @_Result int
	
	EXEC [dbo].[CN_P_InitializeNodeTypes] @ApplicationID, @Now, @_Result output
	EXEC [dbo].[CN_P_InitializeRelationTypes] @ApplicationID, @_Result output
	
	SELECT 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_AddNodeType]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_AddNodeType]
GO

CREATE PROCEDURE [dbo].[CN_AddNodeType]
	@ApplicationID		uniqueidentifier,
    @NodeTypeID 		uniqueidentifier,
    @AdditionalID		varchar(50),
    @Name				nvarchar(255),
    @ParentID			uniqueidentifier,
    @SetupService		bit,
    @TemplateNodeTypeID uniqueidentifier,
    @TemplateFormID 	uniqueidentifier,
    @CreatorUserID		uniqueidentifier,
    @CreationDate		datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SET @Name = [dbo].[GFN_VerifyString](@Name)
	IF(@AdditionalID = N'') SET @AdditionalID = NULL
	
	IF @AdditionalID IS NULL OR NOT EXISTS(
		SELECT TOP(1) * 
		FROM [dbo].[CN_NodeTypes]
		WHERE ApplicationID = @ApplicationID AND AdditionalID = @AdditionalID
	) BEGIN
		INSERT INTO [dbo].[CN_NodeTypes](
			ApplicationID,
			NodeTypeID,
			TemplateTypeID,
			AdditionalID,
			Name,
			ParentID,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES(
			@ApplicationID,
			@NodeTypeID,
			@TemplateNodeTypeID,
			@AdditionalID,
			@Name,
			@ParentID,
			@CreatorUserID,
			@CreationDate,
			0
		)
		
		DECLARE @_Result int = 0
		
		IF ISNULL(@SetupService, 0) = 1 BEGIN
			EXEC [dbo].[CN_P_InitializeService] @ApplicationID, @NodeTypeID, @_Result output
			
			UPDATE [dbo].[CN_Services]
				SET ServiceTitle = [dbo].[GFN_VerifyString](@Name)
			WHERE ApplicationID = @ApplicationID AND NodeTypeID = @NodeTypeID
			
			DECLARE @FormID uniqueidentifier = NEWID()
			
			DECLARE @FormTitle nvarchar(255) = [dbo].[GFN_VerifyString](@Name) + N' - ' + 
				CAST(FLOOR((RAND() * (99998 - 10001)) + 10001) AS nvarchar(100))
			
			EXEC [dbo].[FG_P_CreateForm] @ApplicationID, @FormID, @TemplateFormID, 
				@FormTitle, @CreatorUserID, @CreationDate, @_Result output
			
			EXEC [dbo].[FG_P_SetFormOwner] @ApplicationID, @NodeTypeID, @FormID, @CreatorUserID, @CreationDate, @_Result output
		END
		
		SELECT 1
	END

	SELECT 0
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_RenameNodeType]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_RenameNodeType]
GO

CREATE PROCEDURE [dbo].[CN_RenameNodeType]
	@ApplicationID			uniqueidentifier,
    @NodeTypeID 			uniqueidentifier,
    @Name					nvarchar(255),
    @LastModifierUserID		uniqueidentifier,
    @LastModificationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @Name = [dbo].[GFN_VerifyString](@Name)
	
	UPDATE [dbo].[CN_NodeTypes]
		SET Name = @Name,
			LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate
	WHERE ApplicationID = @ApplicationID AND NodeTypeID = @NodeTypeID

	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_SetNodeTypeAdditionalID]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_SetNodeTypeAdditionalID]
GO

CREATE PROCEDURE [dbo].[CN_SetNodeTypeAdditionalID]
	@ApplicationID			uniqueidentifier,
    @NodeTypeID 			uniqueidentifier,
    @AdditionalID			varchar(255),
    @LastModifierUserID		uniqueidentifier,
    @LastModificationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @CurrentAdditionalID varchar(255) = (
		SELECT TOP(1) AdditionalID
		FROM [dbo].[CN_NodeTypes]
		WHERE ApplicationID = @ApplicationID AND NodeTypeID = @NodeTypeID
	)
	
	IF LTRIM(RTRIM(ISNULL(@CurrentAdditionalID, ''))) = '6' BEGIN
		SELECT -1, N'CannotChangeTheAdditionalIDOFThisNodeType'
		RETURN
	END
	
	IF Exists(
		SELECT TOP(1) *
		FROM [dbo].[CN_NodeTypes]
		WHERE ApplicationID = @ApplicationID AND NodeTypeID <> @NodeTypeID AND 
			LOWER(AdditionalID) = LOWER(@AdditionalID)
	) BEGIN
		SELECT -1, N'ThereIsAlreadyANodeTypeWithTheSameAdditionalID'
		RETURN
	END
	
	UPDATE [dbo].[CN_NodeTypes]
		SET AdditionalID = @AdditionalID,
			LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate
	WHERE ApplicationID = @ApplicationID AND NodeTypeID = @NodeTypeID

	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_SetAdditionalIDPattern]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_SetAdditionalIDPattern]
GO

CREATE PROCEDURE [dbo].[CN_SetAdditionalIDPattern]
	@ApplicationID			uniqueidentifier,
    @NodeTypeID 			uniqueidentifier,
    @AdditionalIDPattern	varchar(255),
    @LastModifierUserID		uniqueidentifier,
    @LastModificationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[CN_NodeTypes]
		SET AdditionalIDPattern = @AdditionalIDPattern,
			LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate
	WHERE ApplicationID = @ApplicationID AND NodeTypeID = @NodeTypeID

	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_MoveNodeType]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_MoveNodeType]
GO

CREATE PROCEDURE [dbo].[CN_MoveNodeType]
	@ApplicationID			uniqueidentifier,
    @strNodeTypeIDs			varchar(max),
	@delimiter				char,
    @ParentID				uniqueidentifier,
    @LastModifierUserID		uniqueidentifier,
    @LastModificationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeTypeIDs GuidTableType
	INSERT INTO @NodeTypeIDs
	SELECT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strNodeTypeIDs, @delimiter) AS Ref
	
	UPDATE [dbo].[CN_NodeTypes]
		SET ParentID = @ParentID,
			LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate
	WHERE ApplicationID = @ApplicationID AND 
		NodeTypeID IN(SELECT NT.Value FROM @NodeTypeIDs AS NT)

	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_GetNodeTypesByIDs]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_GetNodeTypesByIDs]
GO

CREATE PROCEDURE [dbo].[CN_P_GetNodeTypesByIDs]
	@ApplicationID		uniqueidentifier,
	@NodeTypeIDsTemp	KeyLessGuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeTypeIDs KeyLessGuidTableType
	INSERT INTO @NodeTypeIDs (Value) SELECT Value FROM @NodeTypeIDsTemp
	
	SELECT NT.NodeTypeID,
		   NT.ParentID,
		   NT.Name,
		   NT.AdditionalID,
		   NT.AdditionalIDPattern,
		   NT.Deleted AS Archive,
		   CAST((CASE WHEN ISNULL(S.ServiceTitle, N'') = N'' THEN 0 ELSE 1 END) AS bit) AS IsService
	FROM @NodeTypeIDs AS Ref
		INNER JOIN [dbo].[CN_NodeTypes] AS NT
		ON NT.ApplicationID = @ApplicationID AND NT.NodeTypeID = Ref.Value
		LEFT JOIN [dbo].[CN_Services] AS S
		ON S.ApplicationID = @ApplicationID AND S.NodeTypeID = NT.NodeTypeID AND S.Deleted = 0
	ORDER BY (CASE WHEN NT.Deleted = 1 THEN NT.LastModificationDate ELSE Ref.SequenceNumber END) ASC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetNodeTypesByIDs]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetNodeTypesByIDs]
GO

CREATE PROCEDURE [dbo].[CN_GetNodeTypesByIDs]
	@ApplicationID		uniqueidentifier,
	@strNodeTypeIDs		varchar(max),
	@delimiter			char,
	@GrabSubNodeTypes	bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeTypeIDs KeyLessGuidTableType
	
	INSERT INTO @NodeTypeIDs (Value)
	SELECT DISTINCT Ref.Value 
	FROM [dbo].[GFN_StrToGuidTable](@strNodeTypeIDs, @delimiter) AS Ref
	
	IF @GrabSubNodeTypes = 1 BEGIN
		DECLARE @TempIDs GuidTableType
		
		INSERT INTO @TempIDs (Value)
		SELECT IDs.Value
		FROM @NodeTypeIDs AS IDs
	
		INSERT INTO @NodeTypeIDs (Value)
		SELECT DISTINCT Ref.NodeTypeID
		FROM @NodeTypeIDs AS IDs
			RIGHT JOIN [dbo].[CN_FN_GetChildNodeTypesDeepHierarchy](@ApplicationID, @TempIDs) AS Ref
			ON Ref.NodeTypeID = IDs.Value
		WHERE IDs.Value IS NULL
	END
	
	EXEC [dbo].[CN_P_GetNodeTypesByIDs] @ApplicationID, @NodeTypeIDs
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetNodeTypes]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetNodeTypes]
GO

CREATE PROCEDURE [dbo].[CN_GetNodeTypes]
	@ApplicationID				uniqueidentifier,
	@SearchText					nvarchar(1000),
	@IsKnowledge				bit,
	@IsDocument					bit,
	@Archive					bit,
	@ExtensionsTemp				StringTableType readonly,
	@IgnoreExtensionsTemp		StringTableType readonly,
	@IgnoreAdditionalIDsTemp	StringTableType readonly,
	@Count						int,
	@LowerBoundary				bigint
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Extensions StringTableType
	INSERT INTO @Extensions SELECT * FROM @ExtensionsTemp

	DECLARE @IgnoreExtensions StringTableType
	INSERT INTO @IgnoreExtensions SELECT * FROM @IgnoreExtensionsTemp

	DECLARE @IgnoreAdditionalIDs StringTableType
	INSERT INTO @IgnoreAdditionalIDs SELECT * FROM @IgnoreAdditionalIDsTemp

	DECLARE @ExtensionsCount int = (SELECT TOP(1) COUNT(X.Value) FROM @Extensions AS X)
	DECLARE @IgnoreExtensionsCount int = (SELECT TOP(1) COUNT(X.Value) FROM @IgnoreExtensions AS X)
	DECLARE @IgnoreAdditionalIDsCount int = (SELECT TOP(1) COUNT(X.Value) FROM @IgnoreAdditionalIDs AS X)

	DECLARE @IDs Table(NodeTypeID uniqueidentifier, Seq int IDENTITY(1, 1))
	DECLARE @NodeTypeIDs KeyLessGuidTableType
	
	IF ISNULL(@Count, 0) <= 0 SET @Count = 1000000
	
	IF ISNULL(@SearchText, N'') = N'' BEGIN
		INSERT INTO @IDs (NodeTypeID)
		SELECT Ref.NodeTypeID
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY ISNULL(MAX(NT.CreationDate), 
							'2000-02-15 10:48:39.330') DESC, NT.NodeTypeID DESC) AS RowNumber,
						NT.NodeTypeID,
						MAX(NT.SequenceNumber) AS SequenceNumber
				FROM [dbo].[CN_NodeTypes] AS NT
					LEFT JOIN [dbo].[CN_Services] AS S
					ON S.ApplicationID = @ApplicationID AND 
						S.NodeTypeID = NT.NodeTypeID AND S.Deleted = 0
					LEFT JOIN [dbo].[CN_Extensions] AS Ex
					ON @ExtensionsCount > 0 AND Ex.ApplicationID = @ApplicationID AND 
						Ex.OwnerID = NT.NodeTypeID AND Ex.Deleted = 0 AND
						Ex.Extension IN (SELECT XX.Value FROM @Extensions AS XX)
				WHERE NT.ApplicationID = @ApplicationID AND 
					(ISNULL(@IsKnowledge, 0) = 0 OR S.IsKnowledge = 1) AND
					(ISNULL(@IsDocument, 0) = 0 OR S.IsDocument = 1) AND
					(NT.Deleted = ISNULL(@Archive, 0)) AND
					(@ExtensionsCount = 0 OR Ex.OwnerID IS NOT NULL) AND
					(@IgnoreAdditionalIDsCount = 0 OR ISNULL(NT.AdditionalID, N'') NOT IN (SELECT X.Value FROM @IgnoreAdditionalIDs AS X))
				GROUP BY NT.NodeTypeID
			) AS Ref
		ORDER BY Ref.SequenceNumber ASC, Ref.RowNumber ASC
	END
	ELSE BEGIN
		INSERT INTO @IDs (NodeTypeID)
		SELECT Ref.NodeTypeID
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY MAX(SRCH.[Rank]) DESC, NT.NodeTypeID DESC) AS RowNumber,
						NT.NodeTypeID,
						MAX(NT.SequenceNumber) AS SequenceNumber
				FROM CONTAINSTABLE([dbo].[CN_NodeTypes], ([Name]), @SearchText) AS SRCH
					INNER JOIN [dbo].[CN_NodeTypes] AS NT
					ON NT.ApplicationID = @ApplicationID AND NT.NodeTypeID = SRCH.[Key]
					LEFT JOIN [dbo].[CN_Services] AS S
					ON S.ApplicationID = @ApplicationID AND 
						S.NodeTypeID = NT.NodeTypeID AND S.Deleted = 0
					LEFT JOIN [dbo].[CN_Extensions] AS Ex
					ON @ExtensionsCount > 0 AND Ex.ApplicationID = @ApplicationID AND 
						Ex.OwnerID = NT.NodeTypeID AND Ex.Deleted = 0 AND
						Ex.Extension IN (SELECT XX.Value FROM @Extensions AS XX)
				WHERE (ISNULL(@IsKnowledge, 0) = 0 OR S.IsKnowledge = 1) AND
					(ISNULL(@IsDocument, 0) = 0 OR S.IsDocument = 1) AND
					(NT.Deleted = ISNULL(@Archive, 0)) AND
					(@ExtensionsCount = 0 OR Ex.OwnerID IS NOT NULL) AND
					(@IgnoreAdditionalIDsCount = 0 OR ISNULL(NT.AdditionalID, N'') NOT IN (SELECT X.Value FROM @IgnoreAdditionalIDs AS X))
				GROUP BY NT.NodeTypeID
			) AS Ref
		ORDER BY Ref.SequenceNumber ASC, Ref.RowNumber ASC
	END

	IF @IgnoreExtensionsCount > 0 BEGIN
		DELETE X
		FROM @IDs AS X
			INNER JOIN [dbo].[CN_Extensions] AS E
			ON E.ApplicationID = @ApplicationID AND E.OwnerID = X.NodeTypeID AND E.Deleted = 0
			INNER JOIN @IgnoreExtensions AS I
			ON I.Value = E.Extension
	END


	INSERT INTO @NodeTypeIDs (Value)
	SELECT TOP(@Count) Ref.NodeTypeID
	FROM (
			SELECT	ROW_NUMBER() OVER (ORDER BY X.Seq ASC) AS Seq,
					X.NodeTypeID
			FROM @IDs AS X
		)AS Ref
	WHERE Ref.Seq >= ISNULL(@LowerBoundary, 0)
	ORDER BY Ref.Seq ASC
	
	EXEC [dbo].[CN_P_GetNodeTypesByIDs] @ApplicationID, @NodeTypeIDs
	
	SELECT COUNT(*) 
	FROM @IDs AS Ref
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetNodeType]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetNodeType]
GO

CREATE PROCEDURE [dbo].[CN_GetNodeType]
	@ApplicationID			uniqueidentifier,
	@NodeTypeID				uniqueidentifier,
	@NodeTypeAdditionalID	nvarchar(20),
	@NodeID					uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @NodeTypeID = ISNULL((SELECT TOP(1) NodeTypeID
		FROM [dbo].[CN_Nodes]
		WHERE ApplicationID = @ApplicationID AND NodeID = @NodeTypeID), @NodeTypeID)
	
	DECLARE @NodeTypeIDs KeyLessGuidTableType
	
	IF @NodeTypeID IS NOT NULL BEGIN
		INSERT INTO @NodeTypeIDs (Value)
		VALUES(@NodeTypeID)
	END
	ELSE IF @NodeID IS NOT NULL BEGIN
		INSERT INTO @NodeTypeIDs (Value)
		SELECT ND.NodeTypeID
		FROM [dbo].[CN_Nodes] AS ND
		WHERE ND.ApplicationID = @ApplicationID AND ND.[NodeID] = @NodeID
	END
	ELSE BEGIN
		INSERT INTO @NodeTypeIDs (Value)
		SELECT NodeTypeID
		FROM [dbo].[CN_NodeTypes]
		WHERE ApplicationID = @ApplicationID AND AdditionalID = @NodeTypeAdditionalID 
	END
	
	EXEC [dbo].[CN_P_GetNodeTypesByIDs] @ApplicationID, @NodeTypeIDs
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_HaveChildNodeTypes]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_HaveChildNodeTypes]
GO

CREATE PROCEDURE [dbo].[CN_HaveChildNodeTypes]
	@ApplicationID	uniqueidentifier,
	@strNodeTypeIDs	varchar(max),
	@delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeTypeIDs GuidTableType
	INSERT INTO @NodeTypeIDs
	SELECT DISTINCT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strNodeTypeIDs, @delimiter) AS Ref
	
	SELECT ExternalIDs.Value AS ID
	FROM @NodeTypeIDs AS ExternalIDs
	WHERE EXISTS(
		SELECT TOP(1) * 
		FROM [dbo].[CN_NodeTypes] 
		WHERE ApplicationID = @ApplicationID AND 
			(ParentID = ExternalIDs.Value AND ParentID <> NodeTypeID) AND Deleted = 0
	)
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetChildNodeTypes]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetChildNodeTypes]
GO

CREATE PROCEDURE [dbo].[CN_GetChildNodeTypes]
	@ApplicationID	uniqueidentifier,
	@ParentID	uniqueidentifier,
	@Archive	bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeTypeIDs KeyLessGuidTableType
	
	INSERT INTO @NodeTypeIDs (Value)
	SELECT NodeTypeID
	FROM [dbo].[CN_NodeTypes]
	WHERE ApplicationID = @ApplicationID AND
		((@ParentID IS NULL AND ParentID IS NULL) OR ParentID = @ParentID) AND 
		(@Archive IS NULL OR Deleted = @Archive)
	ORDER BY SequenceNumber ASC, CreationDate ASC
	
	EXEC [dbo].[CN_P_GetNodeTypesByIDs] @ApplicationID, @NodeTypeIDs
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_ArithmeticDeleteNodeTypes]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_ArithmeticDeleteNodeTypes]
GO

CREATE PROCEDURE [dbo].[CN_ArithmeticDeleteNodeTypes]
	@ApplicationID			uniqueidentifier,
    @strNodeTypeIDs 		varchar(max),
    @delimiter				char,
    @RemoveHierarchy		bit,
    @LastModifierUserID		uniqueidentifier,
    @LastModificationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeTypeIDs GuidTableType
	
	INSERT INTO @NodeTypeIDs (Value)
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strNodeTypeIDs, @delimiter) AS Ref
	
	IF ISNULL(@RemoveHierarchy, 0) = 0 BEGIN
		UPDATE NT
			SET Deleted = 1,
				LastModifierUserID = @LastModifierUserID,
				LastModificationDate = @LastModificationDate
		FROM @NodeTypeIDs AS Ref
			INNER JOIN [dbo].[CN_NodeTypes] AS NT
			ON NT.ApplicationID = @ApplicationID AND 
				NT.[NodeTypeID] = Ref.Value AND NT.[Deleted] = 0
		
		DECLARE @_Result int = @@ROWCOUNT
			
		UPDATE [dbo].[CN_NodeTypes]
			SET ParentID = NULL
		WHERE ApplicationID = @ApplicationID AND ParentID IN(SELECT * FROM @NodeTypeIDs)
		
		SELECT @_Result
	END
	ELSE BEGIN
		UPDATE NT
			SET Deleted = 1,
				LastModifierUserID = @LastModifierUserID,
				LastModificationDate = @LastModificationDate
		FROM [dbo].[CN_FN_GetChildNodeTypesHierarchy](@ApplicationID, @NodeTypeIDs) AS Ref
			INNER JOIN [dbo].[CN_NodeTypes] AS NT
			ON NT.ApplicationID = @ApplicationID AND NT.NodeTypeID = Ref.NodeTypeID
			
		SELECT @@ROWCOUNT
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_RecoverNodeType]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_RecoverNodeType]
GO

CREATE PROCEDURE [dbo].[CN_RecoverNodeType]
	@ApplicationID			uniqueidentifier,
    @NodeTypeID 			uniqueidentifier,
    @LastModifierUserID		uniqueidentifier,
    @LastModificationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[CN_NodeTypes]
		SET Deleted = 0,
			LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate
	WHERE ApplicationID = @ApplicationID AND NodeTypeID = @NodeTypeID
	
	DECLARE @Result int = @@ROWCOUNT
	
	DECLARE @ParentDeleted bit = (
		SELECT TOP(1) P.Deleted
		FROM [dbo].[CN_NodeTypes] AS NT
			INNER JOIN [dbo].[CN_NodeTypes] AS P
			ON P.ApplicationID = @ApplicationID AND P.NodeTypeID = NT.ParentID
		WHERE NT.ApplicationID = @ApplicationID AND 
			NT.NodeTypeID = @NodeTypeID AND NT.ParentID IS NOT NULL
	)
	
	IF ISNULL(@ParentDeleted, 0) = 1 BEGIN
		UPDATE [dbo].[CN_NodeTypes]
			SET ParentID = NULL
		WHERE ApplicationID = @ApplicationID AND NodeTypeID = @NodeTypeID
	END

	SELECT @Result
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_AddRelationType]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_AddRelationType]
GO

CREATE PROCEDURE [dbo].[CN_AddRelationType]
	@ApplicationID	uniqueidentifier,
    @RelationTypeID uniqueidentifier,
    @Name			nvarchar(255),
    @Description	nvarchar(max),
    @CreatorUserID	uniqueidentifier,
    @CreationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @Name = [dbo].[GFN_VerifyString](@Name)
	SET @Description = [dbo].[GFN_VerifyString](@Description)
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM [dbo].[CN_Properties]
		WHERE ApplicationID = @ApplicationID AND Name = @Name AND Deleted = 1
	) BEGIN
		UPDATE [dbo].[CN_Properties]
			SET Deleted = 0
		WHERE ApplicationID = @ApplicationID AND Name = @Name AND Deleted = 1
	END
	ELSE BEGIN
		INSERT INTO [dbo].[CN_Properties](
			ApplicationID,
			PropertyID,
			Name,
			[Description],
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES(
			@ApplicationID,
			@RelationTypeID,
			@Name,
			@Description,
			@CreatorUserID,
			@CreationDate,
			0
		)
	END

	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_ModifyRelationType]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_ModifyRelationType]
GO

CREATE PROCEDURE [dbo].[CN_ModifyRelationType]
	@ApplicationID			uniqueidentifier,
    @RelationTypeID 		uniqueidentifier,
    @Name					nvarchar(255),
    @Description			nvarchar(max),
    @LastModifierUserID		uniqueidentifier,
    @LastModificationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @Name = [dbo].[GFN_VerifyString](@Name)
	SET @Description = [dbo].[GFN_VerifyString](@Description)
	
	UPDATE [dbo].[CN_Properties]
		SET Name = @Name,
			[Description] = @Description,
			LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate
	WHERE ApplicationID = @ApplicationID AND PropertyID = @RelationTypeID

	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetRelationTypes]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetRelationTypes]
GO

CREATE PROCEDURE [dbo].[CN_GetRelationTypes]
	@ApplicationID	uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT PropertyID AS RelationTypeID,
		   Name,
		   AdditionalID
	FROM [dbo].[CN_Properties]
	WHERE ApplicationID = @ApplicationID AND Deleted = 0
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_ArithmeticDeleteRelationType]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_ArithmeticDeleteRelationType]
GO

CREATE PROCEDURE [dbo].[CN_ArithmeticDeleteRelationType]
	@ApplicationID			uniqueidentifier,
    @RelationTypeID 		uniqueidentifier,
    @LastModifierUserID		uniqueidentifier,
    @LastModificationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[CN_Properties]
		SET Deleted = 1,
			LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate
	WHERE ApplicationID = @ApplicationID AND PropertyID = @RelationTypeID

	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_AddRelation]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_AddRelation]
GO

CREATE PROCEDURE [dbo].[CN_P_AddRelation]
	@ApplicationID		uniqueidentifier,
	@RelationsTemp		GuidTripleTableType readonly,
    @CreatorUserID		uniqueidentifier,
    @CreationDate		datetime,
    @SetNullsToDefault	bit,
    @_Result			int output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Relations GuidTripleTableType
	INSERT INTO @Relations SELECT * FROM @RelationsTemp
	
	SET @_Result = -1
	
	DECLARE @VerifiedRelations GuidTripleTableType
	INSERT INTO @VerifiedRelations SELECT * FROM @Relations
	
	IF @SetNullsToDefault = 1 BEGIN
		DECLARE @_RelatedRelationTypeID uniqueidentifier = 
			[dbo].[CN_FN_GetRelatedRelationTypeID](@ApplicationID)
			
		UPDATE @VerifiedRelations
			SET ThirdValue = @_RelatedRelationTypeID
		WHERE ThirdValue = N'00000000-0000-0000-0000-000000000000'
	END
	
	DECLARE @_existingRelations GuidTripleTableType, 
		@_notExistingRelations GuidTripleTableType
	DECLARE @_count int
	
	INSERT INTO @_existingRelations
	SELECT RN.FirstValue, RN.SecondValue, RN.ThirdValue
	FROM @VerifiedRelations AS RN
		INNER JOIN [dbo].[CN_NodeRelations] AS NR
		ON NR.SourceNodeID = RN.FirstValue AND NR.DestinationNodeID = RN.SecondValue
	WHERE NR.ApplicationID = @ApplicationID AND NR.PropertyID = RN.ThirdValue
	
	SET @_count = (SELECT COUNT(*) FROM @_existingRelations)
	
	IF @_count > 0 BEGIN
		UPDATE [dbo].[CN_NodeRelations]
			SET LastModifierUserID = @CreatorUserID,
				LastModificationDate = @CreationDate,
				Deleted = 0
		FROM @_existingRelations AS ER
			INNER JOIN [dbo].[CN_NodeRelations] AS NR
			ON NR.SourceNodeID = ER.FirstValue AND NR.DestinationNodeID = ER.SecondValue
		WHERE NR.ApplicationID = @ApplicationID AND NR.PropertyID = ER.ThirdValue
		
		IF @@ROWCOUNT <= 0 RETURN
	END
	
	
	INSERT INTO @_notExistingRelations
	SELECT RN.FirstValue, RN.SecondValue, RN.ThirdValue
	FROM @VerifiedRelations AS RN
	WHERE NOT EXISTS(SELECT TOP(1) * FROM @_existingRelations AS Ref
		WHERE RN.FirstValue = Ref.FirstValue AND RN.SecondValue = Ref.SecondValue)
	
	SET @_count = (SELECT COUNT(*) FROM @_notExistingRelations)
	
	IF @_count > 0 BEGIN
		INSERT INTO [dbo].[CN_NodeRelations](
			ApplicationID,
			SourceNodeID,
			DestinationNodeID,
			PropertyID,
			CreatorUserID,
			CreationDate,
			Deleted,
			UniqueID
		)
		SELECT @ApplicationID, NER.FirstValue, NER.SecondValue, NER.ThirdValue, 
			@CreatorUserID, @CreationDate, 0, NEWID()
		FROM @_notExistingRelations AS NER
	
		IF @@ROWCOUNT <= 0 RETURN
	END	

	SET @_Result = 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_AddRelation]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_AddRelation]
GO

CREATE PROCEDURE [dbo].[CN_AddRelation]
	@ApplicationID		uniqueidentifier,
	@strRelations		varchar(max),
	@innerDelimiter		char,
	@outerDelimiter		char,
    @CreatorUserID		uniqueidentifier,
    @CreationDate		datetime
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE @Relations GuidTripleTableType
	INSERT INTO @Relations(FirstValue, SecondValue, ThirdValue)
	SELECT Ref.FirstValue, Ref.SecondValue, Ref.ThirdValue
	FROM [dbo].[GFN_StrToGuidTripleTable](@strRelations, @innerDelimiter, @outerDelimiter) 
		AS Ref
	
	DECLARE @_Result int
	
	EXEC [dbo].[CN_P_AddRelation] @ApplicationID, @Relations, 
		@CreatorUserID, @CreationDate, 1, @_Result output
	
	IF @_Result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
		
	SELECT @_Result
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_SaveRelations]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_SaveRelations]
GO

CREATE PROCEDURE [dbo].[CN_SaveRelations]
	@ApplicationID		uniqueidentifier,
	@NodeID				uniqueidentifier,
	@strRelatedNodeIDs	varchar(max),
	@delimiter			char,
    @CreatorUserID		uniqueidentifier,
    @CreationDate		datetime
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM [dbo].[CN_NodeRelations]
		WHERE ApplicationID = @ApplicationID AND SourceNodeID = @NodeID AND Deleted = 0
	) BEGIN
		UPDATE [dbo].[CN_NodeRelations]
			SET Deleted = 1
		WHERE ApplicationID = @ApplicationID AND SourceNodeID = @NodeID AND Deleted = 0
		
		IF @@ROWCOUNT <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	DECLARE @_RelatedRelationTypeID uniqueidentifier = [dbo].[CN_FN_GetRelatedRelationTypeID](@ApplicationID)
	
	DECLARE @Relations GuidTripleTableType
	INSERT INTO @Relations(FirstValue, SecondValue, ThirdValue)
	SELECT @NodeID, Ref.Value, @_RelatedRelationTypeID
	FROM [dbo].[GFN_StrToGuidTable](@strRelatedNodeIDs, @delimiter) AS Ref
	
	DECLARE @_Result int
	
	EXEC [dbo].[CN_P_AddRelation] @ApplicationID, @Relations, 
		@CreatorUserID, @CreationDate, 1, @_Result output
	
	IF @_Result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
		
	SELECT @_Result
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_MakeParent]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_MakeParent]
GO

CREATE PROCEDURE [dbo].[CN_P_MakeParent]
	@ApplicationID		uniqueidentifier,
	@PairNodeIDsTemp	GuidPairTableType readonly,
    @CreatorUserID		uniqueidentifier,
    @CreationDate		datetime,
    @_Result			int output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @PairNodeIDs GuidPairTableType
	INSERT INTO @PairNodeIDs SELECT * FROM @PairNodeIDsTemp
	
	SET @_Result = -1
	
	DECLARE @_ParentRelationTypeID uniqueidentifier,
		@_ChildRelationTypeID uniqueidentifier
	SET @_ParentRelationTypeID = [dbo].[CN_FN_GetParentRelationTypeID](@ApplicationID)
	SET @_ChildRelationTypeID = [dbo].[CN_FN_GetChildRelationTypeID](@ApplicationID)
	
	DECLARE @Relations GuidTripleTableType
	
	INSERT INTO @Relations (FirstValue, SecondValue, ThirdValue)
	SELECT Ref.FirstValue, Ref.SecondValue, @_ParentRelationTypeID
	FROM @PairNodeIDs AS Ref
	
	INSERT INTO @Relations (FirstValue, SecondValue, ThirdValue)
	SELECT Ref.SecondValue, Ref.FirstValue, @_ChildRelationTypeID
	FROM @PairNodeIDs AS Ref
		
	EXEC [dbo].[CN_P_AddRelation] @ApplicationID, @Relations, 
		@CreatorUserID, @CreationDate, 0, @_Result output
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_MakeCorrelation]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_MakeCorrelation]
GO

CREATE PROCEDURE [dbo].[CN_P_MakeCorrelation]
	@ApplicationID		uniqueidentifier,
	@PairNodeIDsTemp	GuidPairTableType readonly,
    @CreatorUserID		uniqueidentifier,
    @CreationDate		datetime,
    @_Result			int output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @PairNodeIDs GuidPairTableType
	INSERT INTO @PairNodeIDs SELECT * FROM @PairNodeIDsTemp
	
	DECLARE @_RelatedRelationTypeID uniqueidentifier
	SET @_RelatedRelationTypeID = [dbo].[CN_FN_GetRelatedRelationTypeID](@ApplicationID)
	
	DECLARE @Relations GuidTripleTableType
	
	INSERT INTO @Relations (FirstValue, SecondValue, ThirdValue)
	SELECT Ref.FirstValue, Ref.SecondValue, @_RelatedRelationTypeID
	FROM @PairNodeIDs AS Ref
	
	INSERT INTO @Relations (FirstValue, SecondValue, ThirdValue)
	SELECT Ref.SecondValue, Ref.FirstValue, @_RelatedRelationTypeID
	FROM @PairNodeIDs AS Ref
		
	EXEC [dbo].[CN_P_AddRelation] @ApplicationID, @Relations, 
		@CreatorUserID, @CreationDate, 0, @_Result output
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_MakeParent]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_MakeParent]
GO

CREATE PROCEDURE [dbo].[CN_MakeParent]
	@ApplicationID		uniqueidentifier,
	@strPairNodeIDs		varchar(max),
	@innerDelimiter		char,
	@outerDelimiter		char,
    @CreatorUserID		uniqueidentifier,
    @CreationDate		datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @PairNodeIDs GuidPairTableType
	INSERT INTO @PairNodeIDs (FirstValue, SecondValue)
	SELECT Ref.FirstValue, Ref.SecondValue
	FROM dbo.GFN_StrToGuidPairTable(@strPairNodeIDs, @innerDelimiter, @outerDelimiter) AS Ref
	
	DECLARE @_Result int
	
	EXEC [dbo].[CN_P_MakeParent] @ApplicationID, @PairNodeIDs, @CreatorUserID, 
		@CreationDate, @_Result output

	SELECT @_Result
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_MakeCorrelation]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_MakeCorrelation]
GO

CREATE PROCEDURE [dbo].[CN_MakeCorrelation]
	@ApplicationID		uniqueidentifier,
	@strPairNodeIDs		varchar(max),
	@innerDelimiter		char,
	@outerDelimiter		char,
    @CreatorUserID		uniqueidentifier,
    @CreationDate		datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @PairNodeIDs GuidPairTableType
	INSERT INTO @PairNodeIDs (FirstValue, SecondValue)
	SELECT Ref.FirstValue, Ref.SecondValue
	FROM dbo.GFN_StrToGuidPairTable(@strPairNodeIDs, @innerDelimiter, @outerDelimiter) AS Ref
	
	DECLARE @_Result int
	
	EXEC [dbo].[CN_P_MakeCorrelation] @ApplicationID, @PairNodeIDs, @CreatorUserID, 
		@CreationDate, @_Result output

	SELECT @_Result
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_ArithmeticDeleteRelations]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_ArithmeticDeleteRelations]
GO

CREATE PROCEDURE [dbo].[CN_P_ArithmeticDeleteRelations]
	@ApplicationID			uniqueidentifier,
	@PairNodeIDsTemp		GuidPairTableType readonly,
    @RelationTypeID 		uniqueidentifier,
    @LastModifierUserID		uniqueidentifier,
    @LastModificationDate	datetime,
    @ReverseAlso			bit,
    @_Result				int output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @PairNodeIDs GuidPairTableType
	INSERT INTO @PairNodeIDs SELECT * FROM @PairNodeIDsTemp
	
	DECLARE @_PairIDs GuidPairTableType
	
	INSERT INTO @_PairIDs (FirstValue, SecondValue)
	SELECT Ref.FirstValue, Ref.SecondValue FROM @PairNodeIDs AS Ref
	
	IF @ReverseAlso = 1 BEGIN
		INSERT INTO @_PairIDs (FirstValue, SecondValue)
		SELECT Ref.SecondValue, Ref.FirstValue
		FROM @PairNodeIDs AS Ref 
		WHERE NOT EXISTS(
			SELECT TOP(1) * 
			FROM @PairNodeIDs AS PN
			WHERE Ref.SecondValue = PN.FirstValue AND Ref.FirstValue = PN.SecondValue
		)
	END
	
	UPDATE NR
		SET LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate,
			Deleted = 1
	FROM @_PairIDs AS ExternalIDs
		INNER JOIN [dbo].[CN_NodeRelations] AS NR
		ON NR.ApplicationID = @ApplicationID AND NR.[SourceNodeID] = ExternalIDs.FirstValue AND
			NR.[DestinationNodeID] = ExternalIDs.SecondValue
	WHERE (@RelationTypeID IS NULL OR PropertyID = @RelationTypeID) AND Deleted = 0

	SET @_Result = @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_ArithmeticDeleteRelations]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_ArithmeticDeleteRelations]
GO

CREATE PROCEDURE [dbo].[CN_ArithmeticDeleteRelations]
	@ApplicationID			uniqueidentifier,
	@strPairNodeIDs			varchar(max),
	@innerDelimiter			char,
	@outerDelimiter			char,
    @RelationTypeID 		uniqueidentifier,
    @LastModifierUserID		uniqueidentifier,
    @LastModificationDate	datetime,
    @ReverseAlso			bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @PairNodeIDs GuidPairTableType
	INSERT INTO @PairNodeIDs (FirstValue, SecondValue)
	SELECT Ref.FirstValue, Ref.SecondValue
	FROM [dbo].[GFN_StrToGuidPairTable](@strPairNodeIDs, @innerDelimiter, @outerDelimiter) AS Ref

	DECLARE @_Result int
	
	EXEC [dbo].[CN_P_ArithmeticDeleteRelations] @ApplicationID, @PairNodeIDs, @RelationTypeID,
		@LastModifierUserID, @LastModificationDate, @ReverseAlso, @_Result output

	SELECT @_Result
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_ArithmeticDeleteCorrelations]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_ArithmeticDeleteCorrelations]
GO

CREATE PROCEDURE [dbo].[CN_ArithmeticDeleteCorrelations]
	@ApplicationID			uniqueidentifier,
	@strPairNodeIDs			varchar(max),
	@innerDelimiter			char,
	@outerDelimiter			char,
    @LastModifierUserID		uniqueidentifier,
    @LastModificationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @_RelatedRelationTypeID uniqueidentifier
	SET @_RelatedRelationTypeID = [dbo].[CN_FN_GetRelatedRelationTypeID](@ApplicationID)
	
	DECLARE @PairNodeIDs GuidPairTableType
	INSERT INTO @PairNodeIDs (FirstValue, SecondValue)
	SELECT Ref.FirstValue, Ref.SecondValue
	FROM [dbo].[GFN_StrToGuidPairTable](@strPairNodeIDs, @innerDelimiter, @outerDelimiter) AS Ref

	DECLARE @_Result int
	
	EXEC [dbo].[CN_P_ArithmeticDeleteRelations] @ApplicationID, @PairNodeIDs, 
		@_RelatedRelationTypeID, @LastModifierUserID, @LastModificationDate, 1, @_Result output

	SELECT @_Result
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_Unparent]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_Unparent]
GO

CREATE PROCEDURE [dbo].[CN_Unparent]
	@ApplicationID			uniqueidentifier,
	@strPairNodeIDs			varchar(max),
	@innerDelimiter			char,
	@outerDelimiter			char,
	@LastModifierUserID		uniqueidentifier,
    @LastModificationDate	datetime
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE @_ParentRelationTypeID uniqueidentifier,
		@_ChildRelationTypeID uniqueidentifier
	SET @_ParentRelationTypeID = [dbo].[CN_FN_GetParentRelationTypeID](@ApplicationID)
	SET @_ChildRelationTypeID = [dbo].[CN_FN_GetChildRelationTypeID](@ApplicationID)
	
	DECLARE @PairNodeIDs GuidPairTableType
	INSERT INTO @PairNodeIDs (FirstValue, SecondValue)
	SELECT Ref.FirstValue, Ref.SecondValue
	FROM [dbo].[GFN_StrToGuidPairTable](@strPairNodeIDs, @innerDelimiter, @outerDelimiter) AS Ref

	DECLARE @_Result int
	
	EXEC [dbo].[CN_P_ArithmeticDeleteRelations] @ApplicationID, @PairNodeIDs, 
		@_ParentRelationTypeID, @LastModifierUserID, @LastModificationDate, 0, @_Result output
		
	IF @_Result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	DECLARE @_ReversePairs GuidPairTableType
	INSERT INTO @_ReversePairs (FirstValue, SecondValue)
	SELECT Ref.SecondValue, Ref.FirstValue
	FROM @PairNodeIDs AS Ref

	EXEC [dbo].[CN_P_ArithmeticDeleteRelations] @ApplicationID, @_ReversePairs, 
		@_ChildRelationTypeID, @LastModifierUserID, @LastModificationDate, 0, @_Result output
		
	IF @_Result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END

	SELECT 1
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_ArithmeticDeleteAllRelations]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_ArithmeticDeleteAllRelations]
GO

CREATE PROCEDURE [dbo].[CN_P_ArithmeticDeleteAllRelations]
	@ApplicationID			uniqueidentifier,
	@NodeID					uniqueidentifier,
	@LastModifierUserID		uniqueidentifier,
	@LastModificationDate	datetime,
    @_Result				int output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM [dbo].[CN_NodeRelations]
		WHERE ApplicationID = @ApplicationID AND 
			(SourceNodeID = @NodeID OR DestinationNodeID = @NodeID) AND Deleted = 0
	) BEGIN
		UPDATE [dbo].[CN_NodeRelations]
			SET Deleted = 1,
				LastModifierUserID = @LastModifierUserID,
				LastModificationDate = @LastModificationDate
		WHERE ApplicationID = @ApplicationID AND 
			(SourceNodeID = @NodeID OR DestinationNodeID = @NodeID) AND Deleted = 0
		
		SET @_Result = @@ROWCOUNT
	END
	ELSE BEGIN
		SET @_Result = 1
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_AddAcceptedMembers]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_AddAcceptedMembers]
GO

CREATE PROCEDURE [dbo].[CN_P_AddAcceptedMembers]
	@ApplicationID	uniqueidentifier,
	@MembersTemp	GuidPairTableType readonly,
    @Now			datetime,
    @_Result		int output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Members GuidPairTableType
	INSERT INTO @Members SELECT * FROM @MembersTemp
	
	IF NOT EXISTS(SELECT TOP(1) * FROM @Members) BEGIN
		SET @_Result = 1
		RETURN
	END
	
	DECLARE @Status varchar(20) = N'Accepted'
	
	DECLARE @TBL TABLE (
		NodeID				uniqueidentifier NOT NULL,
		UserID				uniqueidentifier NOT NULL,
		NodeTypeID			uniqueidentifier NOT NULL,
		UniqueMembership	bit NULL
	)
	
	INSERT INTO @TBL (NodeID, UserID, NodeTypeID, UniqueMembership)
	SELECT ND.NodeID, M.SecondValue, ND.NodeTypeID, ISNULL(S.UniqueMembership, 0)
	FROM @Members AS M
		INNER JOIN [dbo].[CN_Nodes] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.NodeID = M.FirstValue
		LEFT JOIN [dbo].[CN_Services] AS S
		ON S.ApplicationID = @ApplicationID AND S.NodeTypeID = ND.NodeTypeID
	
	-- Remove existing members with UniqueMembership enabled
	UPDATE NM
		SET Deleted = 1
	FROM (
			SELECT T.UserID, T.NodeTypeID
			FROM @TBL AS T
			WHERE T.UniqueMembership = 1
			GROUP BY T.UserID, T.NodeTypeID
		) AS X
		INNER JOIN [dbo].[CN_Nodes] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.NodeTypeID = X.NodeTypeID
		INNER JOIN [dbo].[CN_NodeMembers] AS NM
		ON NM.ApplicationID = @ApplicationID AND 
			NM.NodeID = ND.NodeID AND NM.UserID = X.UserID
	-- end of Remove existing members with UniqueMembership enabled
	
	-- Update existing items
	UPDATE NM
		SET Deleted = 0,
			[Status] = @Status,
			AcceptionDate = ISNULL(AcceptionDate, @Now),
			IsAdmin = CASE WHEN Deleted = 1 THEN 0 ELSE IsAdmin END,
			MembershipDate = ISNULL(MembershipDate, @Now)
	FROM @TBL AS T
		INNER JOIN [dbo].[CN_NodeMembers] AS NM
		ON NM.ApplicationID = @ApplicationID AND 
			NM.NodeID = T.NodeID AND NM.UserID = T.UserID
	-- end of Update existing items
	
	SET @_Result = @@ROWCOUNT
	
	-- Insert New Items
	INSERT INTO [dbo].[CN_NodeMembers](
		ApplicationID,
		NodeID,
		UserID,
		MembershipDate,
		IsAdmin,
		[Status],
		AcceptionDate,
		Deleted,
		UniqueID
	)
	SELECT @ApplicationID, T.NodeID, T.UserID, @Now, 0, @Status, @Now, 0, NEWID()
	FROM @TBL AS T
		LEFT JOIN [dbo].[CN_NodeMembers] AS NM
		ON NM.ApplicationID = @ApplicationID AND 
			NM.NodeID = T.NodeID AND NM.UserID = T.UserID
	WHERE NM.NodeID IS NULL
	-- end of Insert New Items
    
    SET @_Result = @@ROWCOUNT + @_Result
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_UpdateMembers]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_UpdateMembers]
GO

CREATE PROCEDURE [dbo].[CN_P_UpdateMembers]
	@ApplicationID		uniqueidentifier,
	@MembersTemp		GuidPairTableType readonly,
    @MembershipDate		datetime,
    @IsAdmin			bit,
    @IsPending			bit,
    @AcceptionDate		datetime,
    @Position			nvarchar(255),
    @Deleted			bit,
    @_Result			int output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Members GuidPairTableType
	INSERT INTO @Members SELECT * FROM @MembersTemp
	
	IF NOT EXISTS(SELECT TOP(1) * FROM @Members) BEGIN
		SET @_Result = 1
		RETURN
	END
	
	DECLARE @Status varchar(20) = NULL
	
	IF @IsPending IS NOT NULL
		SET @Status = (CASE WHEN @IsPending = 1 THEN N'Pending' ELSE N'Accepted' END)
		
	DECLARE @TBL Table (
		NodeID			uniqueidentifier NOT NULL,
		UserID			uniqueidentifier NOT NULL,
		MembershipDate	datetime,
		IsAdmin			bit NOT NULL,
		[Status]		varchar(20) NOT NULL,
		AcceptionDate	datetime,
		Position		nvarchar(255),
		Deleted			bit NOT NULL,
		[Exists]		bit NOT NULL,
		UniqueID		uniqueidentifier NOT NULL
	)
	
	INSERT INTO @TBL(
		NodeID,
		UserID,
		MembershipDate,
		IsAdmin,
		[Status],
		AcceptionDate,
		Position,
		Deleted,
		[Exists],
		UniqueID
	)
	SELECT	M.FirstValue,
			M.SecondValue,
			ISNULL(@MembershipDate, NM.MembershipDate),
			ISNULL(ISNULL(@IsAdmin, NM.IsAdmin), 0),
			ISNULL(ISNULL(@Status, NM.[Status]), N'Accepted'),
			ISNULL(@AcceptionDate, NM.AcceptionDate),
			ISNULL(@Position, NM.Position),
			ISNULL(ISNULL(@Deleted, NM.Deleted), 0),
			CAST((CASE WHEN NM.NodeID IS NULL THEN 0 ELSE 1 END) AS bit) AS [Exists],
			ISNULL(NM.UniqueID, NEWID()) AS UniqueID
	FROM @Members AS M
		LEFT JOIN [dbo].[CN_NodeMembers] AS NM
		ON NM.ApplicationID = @ApplicationID AND 
			NM.NodeID = M.FirstValue AND NM.UserID = M.SecondValue
	
	-- Update Existing Data
	UPDATE NM
		SET MembershipDate = T.MembershipDate,
			IsAdmin = T.IsAdmin,
			[Status] = T.[Status],
			AcceptionDate = T.AcceptionDate,
			Position = T.Position,
			Deleted = T.Deleted
	FROM @TBL AS T
		INNER JOIN [dbo].[CN_NodeMembers] AS NM
		ON NM.ApplicationID = @ApplicationID AND 
			NM.NodeID = T.NodeID AND NM.UserID = T.UserID
	WHERE T.[Exists] = 1
	-- end of Update Existing Data
	
	SET @_Result = @@ROWCOUNT
	
	-- Insert New Data
	INSERT INTO [dbo].[CN_NodeMembers](
		ApplicationID,
		NodeID,
		UserID,
		MembershipDate,
		IsAdmin,
		[Status],
		AcceptionDate,
		Position,
		Deleted,
		UniqueID
	)
	SELECT	@ApplicationID,
			Ref.NodeID, 
			Ref.UserID, 
			Ref.MembershipDate, 
			Ref.IsAdmin, 
			Ref.[Status], 
			Ref.AcceptionDate, 
			Ref.Position, 
			Ref.Deleted,
			Ref.UniqueID
	FROM @TBL AS Ref
	WHERE Ref.[Exists] = 0
	-- end of Insert New Data
    
    SET @_Result = @@ROWCOUNT + @_Result
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_UpdateMember]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_UpdateMember]
GO

CREATE PROCEDURE [dbo].[CN_P_UpdateMember]
	@ApplicationID		uniqueidentifier,
	@NodeID				uniqueidentifier,
	@UserID				uniqueidentifier,
    @MembershipDate		datetime,
    @IsAdmin			bit,
    @IsPending			bit,
    @AcceptionDate		datetime,
    @Position			nvarchar(255),
    @Deleted			bit,
    @_Result			int output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Members GuidPairTableType
	
	INSERT INTO @Members (FirstValue, SecondValue)
	VALUES (@NodeID, @UserID)
	
	EXEC [dbo].[CN_P_UpdateMembers] @ApplicationID, @Members, @MembershipDate, 
		@IsAdmin, @IsPending, @AcceptionDate, @Position, @Deleted, @_Result output
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_AddMember]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_AddMember]
GO

CREATE PROCEDURE [dbo].[CN_P_AddMember]
	@ApplicationID		uniqueidentifier,
    @NodeID				uniqueidentifier,
    @UserID				uniqueidentifier,
    @MembershipDate		datetime,
    @IsAdmin			bit,
    @IsPending			bit,
    @AcceptionDate		datetime,
    @Position			nvarchar(255),
    @_Result			int output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeTypeID uniqueidentifier
	DECLARE @UniqueMembership bit, @UniqueAdmin bit
	
	SELECT	@NodeTypeID = ND.NodeTypeID, 
			@UniqueMembership = ISNULL(S.UniqueMemberShip, 0), 
			@UniqueAdmin = ISNULL(S.UniqueAdminMember, 0)
	FROM [dbo].[CN_Nodes] AS ND
		LEFT JOIN [dbo].[CN_Services] AS S
		ON S.ApplicationID = @ApplicationID AND S.NodeTypeID = ND.NodeTypeID
	WHERE ND.ApplicationID = @ApplicationID AND ND.NodeID = @NodeID
	
	IF @UniqueMembership = 1 BEGIN
		DECLARE @Members GuidPairTableType
		
		INSERT INTO @Members
		SELECT NM.NodeID, NM.UserID
		FROM [dbo].[CN_NodeMembers] AS NM
			INNER JOIN [dbo].[CN_Nodes] AS ND 
			ON ND.ApplicationID = @ApplicationID AND 
				ND.NodeTypeID = @NodeTypeID AND ND.NodeID = NM.NodeID
		WHERE NM.ApplicationID = @ApplicationID AND NM.UserID = @UserID AND NM.Deleted = 0
		
		EXEC [dbo].[CN_P_UpdateMembers] @ApplicationID, @Members, 
			NULL, NULL, NULL, NULL, NULL, 1, @_Result output
		
		IF @_Result <= 0 RETURN
	END
	
	EXEC [dbo].[CN_P_UpdateMember] @ApplicationID, @NodeID, @UserID, @MembershipDate, 
		@IsAdmin, @IsPending, @AcceptionDate, @Position, 0, @_Result output
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_AddNode]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_AddNode]
GO

CREATE PROCEDURE [dbo].[CN_P_AddNode]
	@ApplicationID			uniqueidentifier,
    @NodeID					uniqueidentifier,
    @AdditionalID			varchar(50),
    @NodeTypeID				uniqueidentifier,
    @NodeTypeAdditionalID	nvarchar(50),
    @DocumentTreeNodeID		uniqueidentifier,
    @PreviousVersionID		uniqueidentifier,
    @Name					nvarchar(255),
    @Description			nvarchar(max),
    @Tags					nvarchar(2000),
    @Searchable				bit,
    @CreatorUserID			uniqueidentifier,
    @CreationDate			datetime,
    @ParentNodeID			uniqueidentifier,
    @OwnerID				uniqueidentifier,
    @AddMember				bit,
    @_Result				int output,
    @_ErrorMessage			varchar(1000) output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @Name = [dbo].[GFN_VerifyString](@Name)
	SET @Description = [dbo].[GFN_VerifyString](@Description)
	SET @Tags = [dbo].[GFN_VerifyString](@Tags)
	
	SET @_Result = -1
	
	IF @NodeTypeID IS NULL 
		SET @NodeTypeID = [dbo].[CN_FN_GetNodeTypeID](@ApplicationID, @NodeTypeAdditionalID)
		
	IF @NodeTypeID IS NULL AND @ParentNodeID IS NOT NULL
		SET @NodeTypeID = (
			SELECT NodeTypeID 
			FROM [dbo].[CN_Nodes] 
			WHERE ApplicationID = @ApplicationID AND NodeID = @ParentNodeID
		)
			
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM [dbo].[CN_Nodes]
		WHERE ApplicationID = @ApplicationID AND NodeTypeID = @NodeTypeID AND 
			@AdditionalID IS NOT NULL AND @AdditionalID <> '' AND AdditionalID = @AdditionalID
	) BEGIN
		SET @_Result = -50
		SET @_ErrorMessage = N'AdditionalIDAlreadyExists'
		RETURN
	END
	
	SET @Searchable = ISNULL(@Searchable, CAST(1 AS bit))
	IF @PreviousVersionID = @NodeID SET @PreviousVersionID = NULL
	
	INSERT INTO [dbo].[CN_Nodes](
		ApplicationID,
		NodeID,
		AdditionalID,
		NodeTypeID,
		DocumentTreeNodeID,
		PreviousVersionID,
		Name,
		[Description],
		Tags,
		CreatorUserID,
		CreationDate,
		Deleted,
		ParentNodeID,
		OwnerID,
		Searchable
	)
	VALUES(
		@ApplicationID,
		@NodeID,
		@AdditionalID,
		@NodeTypeID,
		@DocumentTreeNodeID,
		@PreviousVersionID,
		@Name,
		@Description,
		@Tags,
		@CreatorUserID,
		@CreationDate,
		0,
		@ParentNodeID,
		@OwnerID,
		@Searchable
	)
	
	EXEC [dbo].[PRVC_P_AddAudience] @ApplicationID, @NodeID, @NodeID, N'View',
		1, NULL, NULL, NULL, @_Result output
	
	IF @_Result <= 0 BEGIN
		SET @_Result = -3
		RETURN
	END
	
	IF @AddMember = 1 BEGIN
		EXEC [dbo].[CN_P_AddMember] @ApplicationID, @NodeID, @CreatorUserID, 
			@CreationDate, 1, 0, @CreationDate, NULL, @_Result output
		
		IF @_Result <= 0 BEGIN
			SET @_Result = -4
			RETURN
		END
	END
	
	IF @Searchable = 1 AND @PreviousVersionID IS NOT NULL BEGIN
		UPDATE [dbo].[CN_Nodes]
			SET Searchable = 0
		WHERE ApplicationID = @ApplicationID AND NodeID = @PreviousVersionID
	END

	SET @_Result = 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_AddNode]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_AddNode]
GO

CREATE PROCEDURE [dbo].[CN_AddNode]
	@ApplicationID			uniqueidentifier,
    @NodeID					uniqueidentifier,
    @AdditionalID_Main		varchar(300),
    @AdditionalID			varchar(50),
    @NodeTypeID				uniqueidentifier,
    @NodeTypeAdditionalID	nvarchar(20),
    @DocumentTreeNodeID		uniqueidentifier,
    @Name					nvarchar(255),
    @Description			nvarchar(max),
    @Tags					nvarchar(2000),
    @Searchable				bit,
    @CreatorUserID			uniqueidentifier,
    @CreationDate			datetime,
    @ParentNodeID			uniqueidentifier,
    @AddMember				bit
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE @_Result int, @_ErrorMessage varchar(1000)
	
	SET @Searchable = ISNULL(@Searchable, 1)
	
	EXEC [dbo].[CN_P_AddNode] @ApplicationID, @NodeID, @AdditionalID, @NodeTypeID, 
		@NodeTypeAdditionalID, @DocumentTreeNodeID, NULL, @Name, @Description, @Tags, 
		@Searchable, @CreatorUserID, @CreationDate, @ParentNodeID, null, 
		@AddMember, @_Result output, @_ErrorMessage output
		
	UPDATE [dbo].[CN_Nodes]
		SET AdditionalID_Main = @AdditionalID_Main
	WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID
	
	SELECT @_Result
	
	IF @_Result <= 0 ROLLBACK TRANSACTION
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_SetAdditionalID]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_SetAdditionalID]
GO

CREATE PROCEDURE [dbo].[CN_SetAdditionalID]
	@ApplicationID		uniqueidentifier,
    @ID					uniqueidentifier,
    @AdditionalID_Main	varchar(300),
    @AdditionalID		varchar(50),
    @CurrentUserID		uniqueidentifier,
    @Now				datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) NodeID 
		FROM [dbo].[CN_Nodes] 
		WHERE ApplicationID = @ApplicationID AND NodeID = @ID
	) BEGIN
		UPDATE [dbo].[CN_Nodes]
			SET AdditionalID_Main = @AdditionalID_Main,
				AdditionalID = @AdditionalID,
				LastModifierUserID = @CurrentUserID,
				LastModificationDate = @Now
		WHERE ApplicationID = @ApplicationID AND NodeID = @ID
	END
	ELSE BEGIN
		UPDATE [dbo].[CN_NodeTypes]
			SET AdditionalID = @AdditionalID,
				LastModifierUserID = @CurrentUserID,
				LastModificationDate = @Now
		WHERE ApplicationID = @ApplicationID AND NodeTypeID = @ID
	END
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_ModifyNode]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_ModifyNode]
GO

CREATE PROCEDURE [dbo].[CN_P_ModifyNode]
	@ApplicationID			uniqueidentifier,
    @NodeID					uniqueidentifier,
    @Name					nvarchar(255),
    @Description			nvarchar(max),
    @Tags					nvarchar(2000),
    @LastModifierUserID		uniqueidentifier,
    @LastModificationDate	datetime,
    @_Result				int output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @Name = [dbo].[GFN_VerifyString](@Name)
	SET @Description = [dbo].[GFN_VerifyString](@Description)
	SET @Tags = [dbo].[GFN_VerifyString](@Tags)
	
	UPDATE [dbo].[CN_Nodes]
		SET Name = CASE WHEN ISNULL(@Name, N'') = N'' THEN Name ELSE @Name END,
			[Description] = @Description,
			Tags = @Tags,
			LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate
	WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID

	SET @_Result = @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_ChangeNodeType]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_ChangeNodeType]
GO

CREATE PROCEDURE [dbo].[CN_ChangeNodeType]
	@ApplicationID			uniqueidentifier,
    @NodeID					uniqueidentifier,
    @NodeTypeID				uniqueidentifier,
    @LastModifierUserID		uniqueidentifier,
    @LastModificationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[CN_Nodes]
		SET NodeTypeID = @NodeTypeID,
			LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate
	WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID

	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_SetDocumentTreeNodeID]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_SetDocumentTreeNodeID]
GO

CREATE PROCEDURE [dbo].[CN_SetDocumentTreeNodeID]
	@ApplicationID			uniqueidentifier,
    @strNodeIDs				varchar(max),
	@delimiter				char,
    @DocumentTreeNodeID		uniqueidentifier,
    @LastModifierUserID		uniqueidentifier,
    @LastModificationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeIDs GuidTableType
	INSERT INTO @NodeIDs
	SELECT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strNodeIDs, @delimiter) AS Ref
	
	UPDATE [dbo].[CN_Nodes]
		SET DocumentTreeNodeID = @DocumentTreeNodeID,
			LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate
	FROM @NodeIDs AS Ref
		INNER JOIN [dbo].[CN_Nodes] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.[NodeID] = Ref.Value
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_ModifyNodeName]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_ModifyNodeName]
GO

CREATE PROCEDURE [dbo].[CN_P_ModifyNodeName]
	@ApplicationID			uniqueidentifier,
    @NodeID					uniqueidentifier,
    @Name					nvarchar(255),
    @LastModifierUserID		uniqueidentifier,
    @LastModificationDate	datetime,
    @_Result				int output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @Name = [dbo].[GFN_VerifyString](@Name)
	
	UPDATE [dbo].[CN_Nodes]
		SET Name = @Name,
			LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate
	WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID

	SET @_Result = @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_ModifyNodeDescription]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_ModifyNodeDescription]
GO

CREATE PROCEDURE [dbo].[CN_P_ModifyNodeDescription]
	@ApplicationID			uniqueidentifier,
    @NodeID					uniqueidentifier,
    @Description			nvarchar(max),
    @LastModifierUserID		uniqueidentifier,
    @LastModificationDate	datetime,
    @_Result				int output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @Description = [dbo].[GFN_VerifyString](@Description)
	
	UPDATE [dbo].[CN_Nodes]
		SET [Description] = @Description,
			LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate
	WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID

	SET @_Result = @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_ModifyNodeTags]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_ModifyNodeTags]
GO

CREATE PROCEDURE [dbo].[CN_ModifyNodeTags]
	@ApplicationID			uniqueidentifier,
    @NodeID					uniqueidentifier,
    @Tags					nvarchar(max),
    @LastModifierUserID		uniqueidentifier,
    @LastModificationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @Tags = [dbo].[GFN_VerifyString](@Tags)
	
	UPDATE [dbo].[CN_Nodes]
		SET [Tags] = @Tags,
			LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate
	WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID

	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_ModifyNodeWFState]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_ModifyNodeWFState]
GO

CREATE PROCEDURE [dbo].[CN_P_ModifyNodeWFState]
	@ApplicationID			uniqueidentifier,
    @NodeID					uniqueidentifier,
    @WFState				nvarchar(1000),
    @HideCreators			bit,
    @LastModifierUserID		uniqueidentifier,
    @LastModificationDate	datetime,
    @_Result				int output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @WFState = [dbo].[GFN_VerifyString](@WFState)
	
	UPDATE [dbo].[CN_Nodes]
		SET WFState = @WFState,
			HideCreators = ISNULL(@HideCreators, 0),
			LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate
	WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID

	SET @_Result = @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_ModifyNode]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_ModifyNode]
GO

CREATE PROCEDURE [dbo].[CN_ModifyNode]
	@ApplicationID			uniqueidentifier,
    @NodeID					uniqueidentifier,
    @Name					nvarchar(255),
    @Description			nvarchar(max),
    @Tags					nvarchar(2000),
    @LastModifierUserID		uniqueidentifier,
    @LastModificationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @_Result int
	
	EXEC [dbo].[CN_P_ModifyNode] @ApplicationID, @NodeID, @Name, @Description, @Tags, 
		@LastModifierUserID, @LastModificationDate, @_Result output

	SELECT @_Result
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_ModifyNodeName]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_ModifyNodeName]
GO

CREATE PROCEDURE [dbo].[CN_ModifyNodeName]
	@ApplicationID			uniqueidentifier,
    @NodeID					uniqueidentifier,
    @Name					nvarchar(255),
    @LastModifierUserID		uniqueidentifier,
    @LastModificationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @_Result int
	
	EXEC [dbo].[CN_P_ModifyNodeName] @ApplicationID, @NodeID, @Name, 
		@LastModifierUserID, @LastModificationDate, @_Result output

	SELECT @_Result
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_ModifyNodeDescription]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_ModifyNodeDescription]
GO

CREATE PROCEDURE [dbo].[CN_ModifyNodeDescription]
	@ApplicationID			uniqueidentifier,
    @NodeID					uniqueidentifier,
    @Description			nvarchar(max),
    @LastModifierUserID		uniqueidentifier,
    @LastModificationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @_Result int
	
	EXEC [dbo].[CN_P_ModifyNodeDescription] @ApplicationID, @NodeID, @Description, 
		@LastModifierUserID, @LastModificationDate, @_Result output

	SELECT @_Result
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_ModifyNodePublicDescription]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_ModifyNodePublicDescription]
GO

CREATE PROCEDURE [dbo].[CN_ModifyNodePublicDescription]
	@ApplicationID	uniqueidentifier,
    @NodeID			uniqueidentifier,
    @Description	nvarchar(max)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[CN_Nodes]
		SET PublicDescription = [dbo].[GFN_VerifyString](@Description)
	WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_SetNodeExpirationDate]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_SetNodeExpirationDate]
GO

CREATE PROCEDURE [dbo].[CN_SetNodeExpirationDate]
	@ApplicationID	uniqueidentifier,
    @NodeID			uniqueidentifier,
    @ExpirationDate	datetime
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	UPDATE [dbo].[CN_Nodes]
		SET ExpirationDate = @ExpirationDate
	WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID
	
	-- remove dashboards
	IF @ExpirationDate IS NULL BEGIN
		DECLARE @_Result int = 0
    
		EXEC [dbo].[NTFN_P_ArithmeticDeleteDashboards] @ApplicationID, 
			NULL, @NodeID, NULL, N'Knowledge', N'ExpirationDate', 
			@_Result output
			
		IF @_Result <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	-- end of remove dashboards
	
	SELECT 1
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_SetExpiredNodesAsNotSearchable]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_SetExpiredNodesAsNotSearchable]
GO

CREATE PROCEDURE [dbo].[CN_SetExpiredNodesAsNotSearchable]
	@ApplicationID	uniqueidentifier,
    @Now			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[CN_Nodes]
		SET Searchable = 0
	WHERE ApplicationID = @ApplicationID AND 
		ExpirationDate < @Now AND Deleted = 0
	
	SELECT @@ROWCOUNT + 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetNodeIDsThatWillBeExpiredSoon]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetNodeIDsThatWillBeExpiredSoon]
GO

CREATE PROCEDURE [dbo].[CN_GetNodeIDsThatWillBeExpiredSoon]
	@ApplicationID	uniqueidentifier,
    @Date			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT ND.NodeID AS ID
	FROM [dbo].[CN_Nodes] AS ND
		LEFT JOIN [dbo].[NTFN_Dashboards] AS D
		ON D.ApplicationID = @ApplicationID AND D.NodeID = ND.NodeID AND 
			D.Deleted = 0 AND D.Done = 0 AND
			D.[Type] = N'Knowledge' AND D.SubType = N'ExpirationDate'
	WHERE ND.ApplicationID = @ApplicationID AND ND.Deleted = 0 AND
		ND.ExpirationDate IS NOT NULL AND ND.ExpirationDate <= @Date AND
		D.ID IS NULL
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_NotifyNodeExpiration]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_NotifyNodeExpiration]
GO

CREATE PROCEDURE [dbo].[CN_NotifyNodeExpiration]
	@ApplicationID	uniqueidentifier,
    @NodeID			uniqueidentifier,
    @UserID			uniqueidentifier,
    @Now			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	-- Send new dashboards
    IF @UserID IS NOT NULL BEGIN
		DECLARE @Dashboards DashboardTableType
		
		INSERT INTO @Dashboards(UserID, NodeID, RefItemID, [Type], SubType, Removable, SendDate)
		VALUES (@UserID, @NodeID, @NodeID, N'Knowledge', N'ExpirationDate', 0, @Now)
		
		DECLARE @_Result int = 0
		
		EXEC [dbo].[NTFN_P_SendDashboards] @ApplicationID, @Dashboards, @_Result output
		
		IF @_Result <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
		ELSE BEGIN
			SELECT * 
			FROM @Dashboards
		END
	END
	-- end of send new dashboards
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_SetPreviousVersion]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_SetPreviousVersion]
GO

CREATE PROCEDURE [dbo].[CN_SetPreviousVersion]
	@ApplicationID			uniqueidentifier,
    @NodeID					uniqueidentifier,
    @PreviousVersionID		uniqueidentifier,
    @LastModifierUserID		uniqueidentifier,
    @LastModificationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[CN_Nodes]
		SET PreviousVersionID = @PreviousVersionID,
			LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate
	WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetPreviousVersions]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetPreviousVersions]
GO

CREATE PROCEDURE [dbo].[CN_GetPreviousVersions]
	@ApplicationID	uniqueidentifier,
    @NodeID			uniqueidentifier,
    @CurrentUserID	uniqueidentifier,
	@CheckPrivacy	bit,
	@Now			datetime,
	@DefaultPrivacy	varchar(50)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @NodeIDs KeyLessGuidTableType
	
	;WITH hirarchy (NodeID, PreviousVersionID, [Level], Name)
	AS
	(
		SELECT NodeID, PreviousVersionID, 0 AS [Level], Name
		FROM [dbo].[CN_Nodes]
		WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID
		
		UNION ALL
		
		SELECT ND.NodeID, ND.PreviousVersionID, [Level] + 1, ND.Name
		FROM [dbo].[CN_Nodes] AS ND
			INNER JOIN hirarchy AS HR
			ON ND.ApplicationID = @ApplicationID AND ND.NodeID = HR.PreviousVersionID
		WHERE ND.NodeID <> HR.NodeID AND ND.Deleted = 0
	)
	
	INSERT INTO @NodeIDs (Value)
	SELECT NodeID
	FROM hirarchy
	WHERE NodeID <> @NodeID
	ORDER BY [Level] ASC
	
	IF @CheckPrivacy = 1 BEGIN
		DECLARE @RetIDs GuidTableType
	
		DECLARE	@PermissionTypes StringPairTableType
		
		INSERT INTO @PermissionTypes (FirstValue, SecondValue)
		VALUES (N'View', @DefaultPrivacy)
	
		INSERT INTO @RetIDs (Value)
		SELECT Ref.ID
		FROM [dbo].[PRVC_FN_CheckAccess](@ApplicationID, @CurrentUserID, 
			@NodeIDs, N'Node', @Now, @PermissionTypes) AS Ref
		
		DELETE @NodeIDs
		
		INSERT INTO @NodeIDs (Value)
		SELECT Ref.Value
		FROM @RetIDs AS Ref
	END
	
	EXEC [dbo].[CN_P_GetNodesByIDs] @ApplicationID, @NodeIDs, NULL, NULL
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetNewVersions]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetNewVersions]
GO

CREATE PROCEDURE [dbo].[CN_GetNewVersions]
	@ApplicationID	uniqueidentifier,
    @NodeID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeIDs KeyLessGuidTableType
	
	INSERT INTO @NodeIDs (Value)
	SELECT NodeID
	FROM [dbo].[CN_Nodes]
	WHERE ApplicationID = @ApplicationID AND PreviousVersionID = @NodeID AND Deleted = 0
	
	EXEC [dbo].[CN_P_GetNodesByIDs] @ApplicationID, @NodeIDs, NULL, NULL
	
	/*
	;WITH hierarchy (ID, ParentID, [Level], Name)
	AS
	(
		SELECT NodeID AS ID, PreviousVersionID AS ParentID, 0 AS [Level], Name AS Name
		FROM [dbo].[CN_Nodes]
		WHERE NodeID = @NodeID
		
		UNION ALL
		
		SELECT ND.NodeID AS ID, ND.PreviousVersionID AS ParentID, 
			[Level] + 1, ND.Name AS Name
		FROM [dbo].[CN_Nodes] AS ND
			INNER JOIN hierarchy AS HR
			ON ND.PreviousVersionID = HR.ID
		WHERE ND.NodeID <> HR.ID AND ND.Deleted = 0
	)

	SELECT * FROM hierarchy
	*/
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetNodeDescription]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetNodeDescription]
GO

CREATE PROCEDURE [dbo].[CN_GetNodeDescription]
	@ApplicationID	uniqueidentifier,
    @NodeID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT [Description]
	FROM [dbo].[CN_Nodes]
	WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_SetNodesSearchability]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_SetNodesSearchability]
GO

CREATE PROCEDURE [dbo].[CN_SetNodesSearchability]
	@ApplicationID			uniqueidentifier,
    @strNodeIDs				varchar(max),
    @delimiter				char,
    @Searchable				bit,
    @LastModifierUserID		uniqueidentifier,
    @LastModificationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @NodeIDs GuidTableType
	
	INSERT INTO @NodeIDs
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strNodeIDs, @delimiter) AS Ref

    UPDATE ND
        SET Searchable = @Searchable,
			LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate
    FROM @NodeIDs AS Ref
		INNER JOIN [dbo].[CN_Nodes] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.[NodeID] = Ref.Value
	
	SELECT @@ROWCOUNT
END 

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_ArithmeticDeleteNodes]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_ArithmeticDeleteNodes]
GO

CREATE PROCEDURE [dbo].[CN_P_ArithmeticDeleteNodes]
	@ApplicationID			uniqueidentifier,
    @NodeIDsTemp			GuidTableType readonly,
    @RemoveHierarchy		bit,
    @LastModifierUserID		uniqueidentifier,
    @LastModificationDate	datetime,
    @_Result				int output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeIDs GuidTableType
	INSERT INTO @NodeIDs SELECT * FROM @NodeIDsTemp

	IF ISNULL(@RemoveHierarchy, 0) = 0 BEGIN
		UPDATE ND
			SET Deleted = 1,
				LastModifierUserID = @LastModifierUserID,
				LastModificationDate = @LastModificationDate
		FROM @NodeIDs AS Ref
			INNER JOIN [dbo].[CN_Nodes] AS ND
			ON ND.ApplicationID = @ApplicationID AND 
				ND.[NodeID] = Ref.Value AND ND.[Deleted] = 0
		
		SET @_Result = @@ROWCOUNT
			
		UPDATE [dbo].[CN_Nodes]
			SET ParentNodeID = NULL
		WHERE ApplicationID = @ApplicationID AND ParentNodeID IN(SELECT * FROM @NodeIDs)
	END
	ELSE BEGIN
		UPDATE ND
			SET Deleted = 1,
				LastModifierUserID = @LastModifierUserID,
				LastModificationDate = @LastModificationDate
		FROM [dbo].[CN_FN_GetChildNodesHierarchy](@ApplicationID, @NodeIDs) AS Ref
			INNER JOIN [dbo].[CN_Nodes] AS ND
			ON ND.ApplicationID = @ApplicationID AND ND.NodeID = Ref.NodeID
			
		SELECT @@ROWCOUNT
	END
END 

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_ArithmeticDeleteNodes]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_ArithmeticDeleteNodes]
GO

CREATE PROCEDURE [dbo].[CN_ArithmeticDeleteNodes]
	@ApplicationID			uniqueidentifier,
    @strNodeIDs				varchar(max),
    @delimiter				char,
    @RemoveHierarchy		bit,
    @LastModifierUserID		uniqueidentifier,
    @LastModificationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @NodeIDs GuidTableType
	
	INSERT INTO @NodeIDs
	SELECT DISTINCT Ref.Value FROM GFN_StrToGuidTable(@strNodeIDs, @delimiter) AS Ref
	
	DECLARE @_Result int

	EXEC [dbo].[CN_P_ArithmeticDeleteNodes] @ApplicationID, @NodeIDs, @RemoveHierarchy, 
		@LastModifierUserID, @LastModificationDate, @_Result output

    SELECT @_Result
END 

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_RecycleNodes]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_RecycleNodes]
GO

CREATE PROCEDURE [dbo].[CN_RecycleNodes]
	@ApplicationID	uniqueidentifier,
    @strNodeIDs		varchar(max),
    @delimiter		char,
    @CurrentUserID	uniqueidentifier,
    @Now			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	UPDATE ND
		SET Deleted = 0,
			LastModifierUserID = @CurrentUserID,
			LastModificationDate = @Now
	FROM [dbo].[GFN_StrToGuidTable](@strNodeIDs, @delimiter) AS Ref
		INNER JOIN [dbo].[CN_Nodes] AS ND
		ON ND.ApplicationID = @ApplicationID AND 
			ND.[NodeID] = Ref.Value AND ND.[Deleted] = 1
	
	SELECT @@ROWCOUNT
END 

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_SetNodeTypesOrder]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_SetNodeTypesOrder]
GO

CREATE PROCEDURE [dbo].[CN_SetNodeTypesOrder]
	@ApplicationID	uniqueidentifier,
	@strIDs	varchar(max),
	@delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @IDs TABLE (
		SequenceNo int identity(1, 1) primary key, 
		ID uniqueidentifier
	)
	
	INSERT INTO @IDs (ID)
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strIDs, @delimiter) AS Ref
	
	DECLARE @ParentID uniqueidentifier = NULL
	
	SELECT TOP(1) @ParentID = ParentID
	FROM [dbo].[CN_NodeTypes]
	WHERE ApplicationID = @ApplicationID AND 
		NodeTypeID = (SELECT TOP (1) Ref.ID FROM @IDs AS Ref)
	
	INSERT INTO @IDs (ID)
	SELECT NT.NodeTypeID
	FROM @IDs AS Ref
		RIGHT JOIN [dbo].[CN_NodeTypes] AS NT
		ON NT.ApplicationID = @ApplicationID AND NT.NodeTypeID = Ref.ID
	WHERE NT.ApplicationID = @ApplicationID AND (
			(NT.ParentID IS NULL AND @ParentID IS NULL) OR 
			NT.ParentID = @ParentID
		) AND Ref.ID IS NULL
	ORDER BY NT.SequenceNumber
	
	UPDATE [dbo].[CN_NodeTypes]
		SET SequenceNumber = Ref.SequenceNo
	FROM @IDs AS Ref
		INNER JOIN [dbo].[CN_NodeTypes] AS NT
		ON NT.NodeTypeID = Ref.ID
	WHERE NT.ApplicationID = @ApplicationID AND (
			(NT.ParentID IS NULL AND @ParentID IS NULL) OR 
			NT.ParentID = @ParentID
		)
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_SetNodesOrder]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_SetNodesOrder]
GO

CREATE PROCEDURE [dbo].[CN_SetNodesOrder]
	@ApplicationID	uniqueidentifier,
	@strIDs	varchar(max),
	@delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @IDs TABLE (
		SequenceNo int identity(1, 1) primary key, 
		ID uniqueidentifier
	)
	
	INSERT INTO @IDs (ID)
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strIDs, @delimiter) AS Ref
	
	DECLARE @ParentID uniqueidentifier = NULL, @TypeID uniqueidentifier = NULL
	
	SELECT TOP(1) @ParentID = ParentNodeID, @TypeID = NodeTypeID
	FROM [dbo].[CN_Nodes]
	WHERE ApplicationID = @ApplicationID AND 
		NodeID = (SELECT TOP (1) Ref.ID FROM @IDs AS Ref)
	
	INSERT INTO @IDs (ID)
	SELECT ND.NodeID
	FROM @IDs AS Ref
		RIGHT JOIN [dbo].[CN_Nodes] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.NodeID = Ref.ID
	WHERE ND.ApplicationID = @ApplicationID AND ND.NodeTypeID = @TypeID AND (
			(ND.ParentNodeID IS NULL AND @ParentID IS NULL) OR 
			ND.ParentNodeID = @ParentID
		) AND Ref.ID IS NULL
	ORDER BY ND.SequenceNumber
	
	UPDATE [dbo].[CN_Nodes]
		SET SequenceNumber = Ref.SequenceNo
	FROM @IDs AS Ref
		INNER JOIN [dbo].[CN_Nodes] AS ND
		ON ND.NodeID = Ref.ID
	WHERE ND.ApplicationID = @ApplicationID AND ND.NodeTypeID = @TypeID AND (
			(ND.ParentNodeID IS NULL AND @ParentID IS NULL) OR 
			ND.ParentNodeID = @ParentID
		)
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetNodesCount]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetNodesCount]
GO

CREATE PROCEDURE [dbo].[CN_GetNodesCount]
	@ApplicationID			uniqueidentifier,
    @strNodeTypeIDs			varchar(max),
    @delimiter				char,
    @NodeTypeAddtionalID	nvarchar(255),
    @LowerCreationDateLimit datetime,
    @UpperCreationDateLimit	datetime,
    @Root					bit,
    @Archive				bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF @Root = 0 SET @Root = NULL
	
	DECLARE @NodeTypeIDs GuidTableType
	INSERT INTO @NodeTypeIDs
	SELECT DISTINCT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strNodeTypeIDs, @delimiter) AS Ref
	
	IF @NodeTypeAddtionalID IS NOT NULL AND (SELECT COUNT(*) FROM @NodeTypeIDs) = 0 BEGIN
		INSERT INTO @NodeTypeIDs
		VALUES ([dbo].[CN_FN_GetNodeTypeID](@ApplicationID, @NodeTypeAddtionalID))
	END
	
	IF (SELECT COUNT(*) FROM @NodeTypeIDs) = 0 BEGIN
		INSERT INTO @NodeTypeIDs
		SELECT NodeTypeID
		FROM [dbo].[CN_NodeTypes]
		WHERE ApplicationID = @ApplicationID AND Deleted = 0
	END
	
	SELECT Ref.NodeTypeID AS NodeTypeID, 
		   ISNULL(NT.AdditionalID, N'') AS NodeTypeAdditionalID, 
		   NT.Name AS TypeName,
		   Ref.NodesCount AS NodesCount
	FROM (
			SELECT CVN.NodeTypeID AS NodeTypeID, 
				COUNT(CVN.NodeID) AS NodesCount
			FROM @NodeTypeIDs AS NTIDs
				INNER JOIN [dbo].[CN_Nodes] AS CVN
				ON CVN.ApplicationID = @ApplicationID AND CVN.NodeTypeID = NTIDs.Value
			WHERE (@LowerCreationDateLimit IS NULL OR 
				CVN.CreationDate >= @LowerCreationDateLimit) AND
				(@UpperCreationDateLimit IS NULL OR 
				CVN.CreationDate <= @UpperCreationDateLimit) AND
				(@Root IS NULL OR CVN.ParentNodeID IS NULL) AND
				(@Archive IS NULL OR CVN.Deleted = @Archive)
			GROUP BY CVN.NodeTypeID
		) AS Ref
		LEFT JOIN dbo.CN_NodeTypes AS NT
		ON NT.ApplicationID = @ApplicationID AND NT.NodeTypeID = Ref.NodeTypeID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetMostPopulatedNodeTypes]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetMostPopulatedNodeTypes]
GO

CREATE PROCEDURE [dbo].[CN_GetMostPopulatedNodeTypes]
	@ApplicationID	uniqueidentifier,
	@Count			int,
	@LowerBoundary	int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF ISNULL(@Count, 0) <= 0 SET @Count = 10000
	
	SELECT TOP(@Count) 
		Ref.RowNumber AS [Order],
		Ref.RevRowNumber AS [ReverseOrder],
		Ref.NodeTypeID AS NodeTypeID,
		Ref.TypeAdditionalID AS NodeTypeAdditionalID,
		Ref.NodeType AS TypeName,
		Ref.[Count] AS NodesCount
	FROM (
			SELECT	ROW_NUMBER() OVER (ORDER BY X.[Count] DESC, X.NodeTypeID DESC) AS RowNumber, 
					ROW_NUMBER() OVER (ORDER BY X.[Count] ASC, X.NodeTypeID ASC) AS RevRowNumber,
					X.*
			FROM (
					SELECT	NodeTypeID,
							MAX(ND.TypeAdditionalID) AS TypeAdditionalID,
							MAX(ND.TypeName) AS NodeType, 
							COUNT(ND.NodeID) AS [Count]
					FROM [dbo].[CN_View_Nodes_Normal] AS ND
					WHERE ND.ApplicationID = @ApplicationID AND 
						ND.TypeDeleted = 0 AND ND.Deleted = 0
					GROUP BY ND.NodeTypeID
				) AS X
		) AS Ref
	WHERE Ref.RowNumber >= ISNULL(@LowerBoundary, 0)
	ORDER BY Ref.RowNumber ASC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetNodeRecordsCount]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetNodeRecordsCount]
GO

CREATE PROCEDURE [dbo].[CN_GetNodeRecordsCount]
	@ApplicationID	uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT (COUNT(*) + 1) 
	FROM [dbo].[CN_Nodes]
	WHERE ApplicationID = @ApplicationID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetNodeTypeIDs]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetNodeTypeIDs]
GO

CREATE PROCEDURE [dbo].[CN_GetNodeTypeIDs]
	@ApplicationID			uniqueidentifier,
	@NodeTypeAdditionalIDs	nvarchar(max),
	@delimiter				char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT X.ID
	FROM (
			SELECT [dbo].[CN_FN_GetNodeTypeID](@ApplicationID, Ref.Value) AS ID
			FROM [dbo].[GFN_StrToStringTable](@NodeTypeAdditionalIDs, @delimiter) AS Ref
		) AS X
	WHERE X.ID IS NOT NULL
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetNodeIDs]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetNodeIDs]
GO

CREATE PROCEDURE [dbo].[CN_GetNodeIDs]
	@ApplicationID			uniqueidentifier,
	@NodeAdditionalIDsTemp	StringTableType readonly,
    @NodeTypeID				uniqueidentifier,
    @NodeTypeAddtionalID	nvarchar(255)
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeAdditionalIDs StringTableType
	INSERT INTO @NodeAdditionalIDs SELECT * FROM @NodeAdditionalIDsTemp
	
	IF @NodeTypeID IS NULL
		SET @NodeTypeID = [dbo].[CN_FN_GetNodeTypeID](@ApplicationID, @NodeTypeAddtionalID)
	
	SELECT NodeID AS ID
	FROM @NodeAdditionalIDs AS ExternalIDs 
		INNER JOIN [dbo].[CN_Nodes] AS ND
		ON ND.AdditionalID = ExternalIDs.Value
	WHERE ND.ApplicationID = @ApplicationID AND ND.NodeTypeID = @NodeTypeID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetNodeIDsByAdditionalIDs]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetNodeIDsByAdditionalIDs]
GO

CREATE PROCEDURE [dbo].[CN_GetNodeIDsByAdditionalIDs]
	@ApplicationID	uniqueidentifier,
	@NodesTemp		StringPairTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Nodes StringPairTableType
	INSERT INTO @Nodes SELECT * FROM @NodesTemp
	
	SELECT ND.NodeID AS ID
	FROM @Nodes AS Ref
		INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
		ON ND.ApplicationID = @ApplicationID AND 
			ND.NodeAdditionalID = Ref.FirstValue AND ND.TypeAdditionalID = Ref.SecondValue
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_GetNodesByIDs]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_GetNodesByIDs]
GO

CREATE PROCEDURE [dbo].[CN_P_GetNodesByIDs]
	@ApplicationID	uniqueidentifier,
    @NodeIDsTemp	KeyLessGuidTableType readonly,
    @Full			bit,
    @ViewerUserID	uniqueidentifier
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeIDs KeyLessGuidTableType
	INSERT INTO @NodeIDs (Value) SELECT Value FROM @NodeIDsTemp
	
	IF @Full IS NULL OR @Full = 0 BEGIN
		SELECT	ND.[NodeID] AS NodeID, 
				ND.[NodeName] AS Name,
				ND.[NodeAdditionalID_Main] AS AdditionalID_Main,
				ND.[NodeAdditionalID] AS AdditionalID,
				ND.AvatarName,
				ND.UseAvatar,
				ND.[NodeTypeID] AS NodeTypeID,
				ND.[TypeName] AS NodeType,
				ND.[TypeAdditionalID] AS NodeTypeAdditionalID,
				ND.[ParentNodeID] AS ParentNodeID,
				ND.CreatorUserID AS CreatorUserID,
				ND.[CreationDate] AS CreationDate,
				ND.AreaID AS AdminAreaID,
				ND.DocumentTreeNodeID,
				ND.[Status],
				ND.[WFState],
				ND.Searchable,
				(ND.Score * ISNULL(KT.ScoreScale, 10)) / 10 AS Score,
				ND.HideCreators,
				ND.Deleted AS Archive
		FROM	@NodeIDs AS Ref
				INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND 
				ON ND.ApplicationID = @ApplicationID AND ND.[NodeID] = Ref.Value
				LEFT JOIN [dbo].[KW_KnowledgeTypes] AS KT
				ON KT.ApplicationID = @ApplicationID AND KT.KnowledgeTypeID = ND.NodeTypeID AND KT.Deleted = 0
		ORDER BY Ref.SequenceNumber ASC
	END
	ELSE BEGIN
		SELECT	Node.[NodeID] AS NodeID, 
				Node.[Name] AS Name,
				Node.[AdditionalID_Main] AS AdditionalID_Main,
				Node.[AdditionalID] AS AdditionalID,
				Node.AvatarName,
				Node.UseAvatar,
				Node.DocumentTreeNodeID,
				TR.TreeID AS DocumentTreeID,
				TR.Name AS DocumentTreeName,
				PVersion.NodeID AS PreviousVersionID,
				PVersion.Name AS PreviousVersionName,
				Node.[Description] AS [Description],
				Node.PublicDescription,
				Node.[Tags] AS Tags,
				Node.[NodeTypeID] AS NodeTypeID,
				NY.[Name] AS NodeType,
				NY.[AdditionalID] AS NodeTypeAdditionalID,
				Node.CreatorUserID AS CreatorUserID,
				USR.UserName AS CreatorUserName,
				USR.FirstName AS CreatorFirstName,
				USR.LastName AS CreatorLastName,
				USR.AvatarName AS CreatorAvatarName,
				USR.UseAvatar AS CreatorUseAvatar,
				Node.CreationDate AS CreationDate,
				Node.ParentNodeID AS ParentNodeID,
				Node.[Status],
				Node.[WFState],
				ISNULL(Node.Searchable, 1) AS Searchable,
				ISNULL(Node.HideCreators, 0) AS HideCreators,
				Node.PublicationDate AS PublicationDate,
				Node.ExpirationDate,
				(Node.Score * ISNULL(KT.ScoreScale, 10)) / 10 AS Score,
				Area.NodeID AS AdminAreaID,
			    Area.NodeName AS AdminAreaName,
			    Area.TypeName AS AdminAreaType,
				CL.ID AS ConfidentialityLevelID,
				CL.LevelID AS ConfidentialityLevelNum,
			    CL.Title AS ConfidentialityLevel,
				OW.NodeID AS OwnerID,
				OW.Name AS OwnerName,
				Node.Deleted AS Archive,
				(
					SELECT COUNT(*) 
					FROM [dbo].[CN_NodeLikes] AS NL
					WHERE NL.ApplicationID = @ApplicationID AND 
						NL.[NodeID] = ExternalIDs.Value AND NL.[Deleted] = 0
				) AS LikesCount,
				(
					SELECT CAST(1 AS bit) 
					FROM [dbo].[CN_NodeLikes] AS NL
					WHERE NL.ApplicationID = @ApplicationID AND 
						NL.[NodeID] = ExternalIDs.Value AND 
						NL.[UserID] = @ViewerUserID AND NL.[Deleted] = 0
				) AS LikeStatus,
				(
					SELECT [Status]
					FROM [dbo].[CN_NodeMembers] AS NM
					WHERE NM.ApplicationID = @ApplicationID AND 
						NM.[NodeID] = ExternalIDs.Value AND
						NM.[UserID] = @ViewerUserID AND NM.[Deleted] = 0
				) AS MembershipStatus,
				(
					SELECT COUNT(*) 
					FROM [dbo].[USR_ItemVisits] AS IV
					WHERE IV.ApplicationID = @ApplicationID AND IV.[ItemID] = ExternalIDs.Value
				) AS VisitsCount,
				(
					SELECT TOP(1) CAST(1 AS bit)
					FROM [dbo].[CN_FreeUsers] AS FU 
					WHERE FU.ApplicationID = @ApplicationID AND 
						FU.NodeTypeID = Node.NodeTypeID AND 
						FU.UserID = @ViewerUserID AND FU.Deleted = 0
				) AS IsFreeUser,
				[dbo].[WK_FN_HasWikiContent](@ApplicationID, Node.NodeID) AS HasWikiContent,
				[dbo].[FG_FN_HasFormContent](@ApplicationID, Node.NodeID) AS HasFormContent
		FROM	@NodeIDs AS ExternalIDs
				INNER JOIN [dbo].[CN_Nodes] AS Node
				ON Node.ApplicationID = @ApplicationID AND Node.[NodeID] = ExternalIDs.Value
				INNER JOIN [dbo].[CN_NodeTypes] AS NY
				ON NY.ApplicationID = @ApplicationID AND NY.NodeTypeID = Node.NodeTypeID
				LEFT JOIN [dbo].[Users_Normal] AS USR
				ON USR.ApplicationID = @ApplicationID AND USR.UserID = Node.CreatorUserID
				LEFT JOIN [dbo].[CN_View_Nodes_Normal] AS Area
				ON Area.ApplicationID = @ApplicationID AND Area.NodeID = Node.AreaID
				LEFT JOIN [dbo].[PRVC_Settings] AS CONF
				INNER JOIN [dbo].[PRVC_ConfidentialityLevels] AS CL
				ON CL.ApplicationID = @ApplicationID AND CL.ID = CONF.ConfidentialityID
				ON CONF.ApplicationID = @ApplicationID AND CONF.ObjectID = Node.NodeID
				LEFT JOIN [dbo].[CN_Nodes] AS OW
				ON OW.ApplicationID = @ApplicationID AND OW.NodeID = Node.OwnerID
				LEFT JOIN [dbo].[DCT_TreeNodes] AS TN
				INNER JOIN [dbo].[DCT_Trees] AS TR
				ON TR.ApplicationID = @ApplicationID AND 
					TR.TreeID = TN.TreeID AND TR.Deleted = 0
				ON TN.ApplicationID = @ApplicationID AND 
					Node.DocumentTreeNodeID IS NOT NULL AND 
					TN.TreeNodeID = Node.DocumentTreeNodeID AND TN.Deleted = 0
				LEFT JOIN [dbo].[CN_Nodes] AS PVersion
				ON PVersion.ApplicationID = @ApplicationID AND 
					Node.PreviousVersionID IS NOT NULL AND 
					PVersion.NodeID = Node.PreviousVersionID
				LEFT JOIN [dbo].[KW_KnowledgeTypes] AS KT
				ON KT.ApplicationID = @ApplicationID AND KT.KnowledgeTypeID = Node.NodeTypeID AND KT.Deleted = 0
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetNodesByIDs]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetNodesByIDs]
GO

CREATE PROCEDURE [dbo].[CN_GetNodesByIDs]
	@ApplicationID	uniqueidentifier,
    @strNodeIDs 	varchar(max),
    @delimiter		char,
    @Full			bit,
    @ViewerUserID	uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeIDs KeyLessGuidTableType
	
	INSERT INTO @NodeIDs (Value)
	SELECT DISTINCT Ref.Value 
	FROM GFN_StrToGuidTable(@strNodeIDs, @delimiter) AS Ref
	
	EXEC [dbo].[CN_P_GetNodesByIDs] @ApplicationID, @NodeIDs, @Full, @ViewerUserID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetNodeIDsByAdditionalID]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetNodeIDsByAdditionalID]
GO

CREATE PROCEDURE [dbo].[CN_GetNodeIDsByAdditionalID]
	@ApplicationID	uniqueidentifier,
	@NodeTypeID		uniqueidentifier,
    @strIDs			varchar(max),
    @delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @IDs StringTableType
	
	INSERT INTO @IDs (Value)
	SELECT DISTINCT Ref.Value 
	FROM GFN_StrToStringTable(@strIDs, @delimiter) AS Ref
	
	SELECT IDs.Value AS AdditionalID, ND.NodeID
	FROM @IDs AS IDs
		INNER JOIN [dbo].[CN_Nodes] AS ND
		ON ND.ApplicationID = @APplicationID AND 
			ND.NodeTypeID = @NodeTypeID AND ND.AdditionalID = IDs.Value
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetNodes]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetNodes]
GO

CREATE PROCEDURE [dbo].[CN_GetNodes]
	@ApplicationID			uniqueidentifier,
	@CurrentUserID			uniqueidentifier,
	@NodeTypeIDsTemp		GuidTableType readonly,
	@NodeTypeAdditionalID	nvarchar(50),
	@UseNodeTypeHierarchy	bit,
	@RelatedToIDsTemp		GuidTableType readonly,
    @SearchText				nvarchar(1000),
    @IsDocument				bit,
    @IsKnowledge			bit,
    @CreatorUserIDsTemp		GuidTableType readonly,
    @Searchable				bit,
    @Archive				bit,
    @GrabNoContentServices	bit,
    @LowerCreationDateLimit	datetime,
    @UpperCreationDateLimit	datetime,
    @Count					int,
    @LowerBoundary			bigint,
	@IsFavorite				bit,
	@IsGroup				bit,
	@IsExpertise			bit,
    @FormFiltersTemp		FormFilterTableType readonly,
    @MatchAllFilters		bit,
	@FetchCounts			bit,
    @CheckAccess			bit,
    @DefaultPrivacy			varchar(20),
    @GroupByFormElementID	uniqueidentifier,
	@Now					datetime
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @FormFilters FormFilterTableType
	INSERT INTO @FormFilters SELECT * FROM @FormFiltersTemp

	SET @SearchText = [dbo].[GFN_VerifyString](@SearchText)

	DECLARE @NodeTypeIDs KeyLessGuidTableType
	INSERT INTO @NodeTypeIDs ([Value]) SELECT Ref.[Value]  FROM @NodeTypeIDsTemp AS Ref

	DECLARE @RelatedToIDs GuidTableType
	INSERT INTO @RelatedToIDs ([Value]) SELECT Ref.[Value]  FROM @RelatedToIDsTemp AS Ref

	DECLARE @CreatorUserIDs GuidTableType
	INSERT INTO @CreatorUserIDs ([Value]) SELECT Ref.[Value]  FROM @CreatorUserIDsTemp AS Ref
	
	DECLARE @_cnt INT = (SELECT  COUNT(*) FROM @NodeTypeIDs)
	
	IF @_cnt = 0 BEGIN
		INSERT INTO @NodeTypeIDs ([Value])
		SELECT NodeTypeID
		FROM [dbo].[CN_NodeTypes]
		WHERE ApplicationID = @ApplicationID AND AdditionalID = @NodeTypeAdditionalID
		
		SET @_cnt = (SELECT  COUNT(*) FROM @NodeTypeIDs)
	END
	
	IF @UseNodeTypeHierarchy = 1 AND @_cnt > 0 BEGIN
		DECLARE @TempIDs GuidTableType
		
		INSERT INTO @TempIDs (Value)
		SELECT IDs.Value
		FROM @NodeTypeIDs AS IDs
	
		INSERT INTO @NodeTypeIDs (Value)
		SELECT DISTINCT Ref.NodeTypeID
		FROM @NodeTypeIDs AS IDs
			RIGHT JOIN [dbo].[CN_FN_GetChildNodeTypesDeepHierarchy](@ApplicationID, @TempIDs) AS Ref
			ON Ref.NodeTypeID = IDs.Value
		WHERE IDs.Value IS NULL
		
		SET @_cnt = (SELECT  COUNT(*) FROM @NodeTypeIDs)
	END
	
	DECLARE @AllIDs KeyLessGuidTableType
	
	IF ISNULL(@SearchText, N'') = N'' BEGIN
		INSERT INTO @AllIDs ([Value])
		SELECT	ND.NodeID
		FROM [dbo].[CN_View_Nodes_Normal] AS ND
			LEFT JOIN [dbo].[CN_Services] AS S
			ON S.ApplicationID = @ApplicationID AND S.NodeTypeID = ND.NodeTypeID AND S.Deleted = 0
		WHERE ND.ApplicationID = @ApplicationID AND 
			(@_cnt = 0 OR ND.NodeTypeID IN (SELECT Value FROM @NodeTypeIDs)) AND
			(@IsDocument IS NULL OR ISNULL(S.IsDocument, 0) = @IsDocument) AND
			(@IsKnowledge IS NULL OR ISNULL(S.IsKnowledge, 0) = @IsKnowledge) AND
			(@LowerCreationDateLimit IS NULL OR ND.CreationDate >= @LowerCreationDateLimit) AND
			(@UpperCreationDateLimit IS NULL OR ND.CreationDate <= @UpperCreationDateLimit) AND
			(@Archive IS NULL OR ND.[Deleted] = @Archive) AND
			(@Searchable IS NULL OR ISNULL(ND.Searchable, 1) = @Searchable) AND
			(
				(@_cnt = 1 AND (ISNULL(@GrabNoContentServices, 0) = 1 OR 
					ISNULL(S.NoContent, 0) = 0 OR ND.CreatorUserID = @CurrentUserID)) OR
				(@_cnt <> 1 AND ISNULL(S.NoContent, 0) = 0)
			)
		ORDER BY ND.CreationDate DESC
	END
	ELSE BEGIN
		INSERT INTO @AllIDs ([Value])
		SELECT ND.[NodeID]
		FROM CONTAINSTABLE([dbo].[CN_Nodes], ([Name], [AdditionalID], [Tags]), @SearchText) AS SRCH
			INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
			ON SRCH.[Key] = ND.NodeID
			LEFT JOIN [dbo].[CN_Services] AS S
			ON S.ApplicationID = @ApplicationID AND S.NodeTypeID = ND.NodeTypeID AND S.Deleted = 0
		WHERE ND.ApplicationID = @ApplicationID AND 
			(@_cnt = 0 OR ND.NodeTypeID IN (SELECT Value FROM @NodeTypeIDs)) AND
			(@IsDocument IS NULL OR ISNULL(S.IsDocument, 0) = @IsDocument) AND
			(@IsKnowledge IS NULL OR ISNULL(S.IsKnowledge, 0) = @IsKnowledge) AND
			(@LowerCreationDateLimit IS NULL OR ND.CreationDate >= @LowerCreationDateLimit) AND
			(@UpperCreationDateLimit IS NULL OR ND.CreationDate <= @UpperCreationDateLimit) AND
			(@Archive IS NULL OR ND.[Deleted] = @Archive) AND
			(@Searchable IS NULL OR ISNULL(ND.Searchable, 1) = @Searchable) AND
			(
				(@_cnt = 1 AND (ISNULL(@GrabNoContentServices, 0) = 1 OR 
					ISNULL(S.NoContent, 0) = 0 OR ND.CreatorUserID = @CurrentUserID)) OR
				(@_cnt <> 1 AND ISNULL(S.NoContent, 0) = 0)
			)
		ORDER BY SRCH.[Rank] DESC, ND.CreationDate DESC
	END

	DECLARE @FilteredIDs KeyLessGuidTableType

	INSERT INTO @FilteredIDs ([Value])
	SELECT F.NodeID
	FROM [dbo].[CN_FN_GetFilteredNodes](@ApplicationID, @CurrentUserID, @AllIDs, @RelatedToIDs, @CreatorUserIDs, 
		@IsFavorite, @IsGroup, @IsExpertise, @CheckAccess, @DefaultPrivacy, @FormFilters, @MatchAllFilters, @Now) AS F
	ORDER BY F.SequenceNumber ASC

	DECLARE @TotalCount bigint = (SELECT COUNT(*) FROM @FilteredIDs)
	
	DECLARE @ElementType varchar(50) = NULL
	DECLARE @NodeTypeID uniqueidentifier = NULL
	
	IF @GroupByFormElementID IS NOT NULL AND @_cnt = 1 BEGIN
		SET @ElementType = (
			SELECT TOP(1) E.[Type]
			FROM [dbo].[FG_ExtendedFormElements] AS E
			WHERE E.ApplicationID = @ApplicationID AND E.ElementID = @GroupByFormElementID
		)
		
		IF @ElementType = N'Select' BEGIN 
			SELECT	E.TextValue, 
					CAST(NULL AS bit) AS BitValue, 
					@ElementType AS [Type], 
					COUNT(DISTINCT ND.[Value]) AS [Count]
			FROM @FilteredIDs AS ND
				LEFT JOIN [dbo].[FG_FormInstances] AS I
				ON I.ApplicationID = @ApplicationID AND I.OwnerID = ND.[Value]
				LEFT JOIN [dbo].[FG_InstanceElements] AS E
				ON E.ApplicationID = @ApplicationID AND E.InstanceID = I.InstanceID AND E.RefElementID = @GroupByFormElementID
			GROUP BY E.TextValue
			ORDER BY [Count] DESC
		END 
		ELSE IF @ElementType = N'Binary' BEGIN
			SELECT	CAST(NULL AS nvarchar(max)) AS TextValue, 
					E.BitValue, 
					@ElementType AS [Type], 
					COUNT(DISTINCT ND.[Value]) AS [Count]
			FROM @FilteredIDs AS ND
				LEFT JOIN [dbo].[FG_FormInstances] AS I
				ON I.ApplicationID = @ApplicationID AND I.OwnerID = ND.[Value]
				LEFT JOIN [dbo].[FG_InstanceElements] AS E
				ON E.ApplicationID = @ApplicationID AND E.InstanceID = I.InstanceID AND E.RefElementID = @GroupByFormElementID
			GROUP BY E.BitValue
			ORDER BY [Count] DESC
		END
	END
	ELSE BEGIN
		DECLARE @RetIDs KeyLessGuidTableType

		-- Pick Items
		IF ISNULL(@Count, 0) < 1 SET @Count = 1000000000
		IF ISNULL(@LowerBoundary, 0) < 1 SET @LowerBoundary = 1
		
		INSERT INTO @RetIDs ([Value])
		SELECT IDs.[Value]
		FROM @FilteredIDs AS IDs
		WHERE IDs.SequenceNumber BETWEEN @LowerBoundary AND (@LowerBoundary + @Count - 1)
		-- end of Pick Items
		
		EXEC [dbo].[CN_P_GetNodesByIDs] @ApplicationID, @RetIDs, 0, NULL
		
		SELECT @TotalCount

		IF @FetchCounts = 1 BEGIN
			SELECT	ND.NodeTypeID,
					MAX(ND.TypeAdditionalID) AS NodeTypeAdditionalID,
					MAX(ND.TypeName) AS TypeName,
					COUNT(DISTINCT ND.NodeID) AS NodesCount
			FROM @FilteredIDs AS IDs
				INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
				ON ND.ApplicationID = @ApplicationID AND ND.NodeID = IDs.[Value]
			GROUP BY ND.NodeTypeID
		END
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetMostPopularNodes]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetMostPopularNodes]
GO

CREATE PROCEDURE [dbo].[CN_GetMostPopularNodes]
	@ApplicationID	uniqueidentifier,
	@strNodeTypeIDs	varchar(max),
	@Delimiter		char,
	@ParentNodeID	uniqueidentifier,
    @Count			int,
    @LowerBoundary	bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeTypeIDs GuidTableType
	INSERT INTO @NodeTypeIDs
	SELECT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strNodeTypeIDs, @Delimiter) AS Ref
	
	DECLARE @_cnt INT = (SELECT  COUNT(*) FROM @NodeTypeIDs) 
	
	SELECT TOP(@Count)
		Ref.NodeID,
		Ref.NodeTypeID,
		Ref.Name,
		Ref.NodeType,
		Ref.VisitsCount,
		Ref.LikesCount,
		Ref.RowNumber AS [Order],
		(Ref.RowNumber + Ref.RevRowNumber - 1) AS TotalCount
	FROM (
			SELECT	ROW_NUMBER() OVER (ORDER BY (N.VisitsCount + N.LikesCount) DESC, N.NodeID DESC) AS RowNumber,
					ROW_NUMBER() OVER (ORDER BY (N.VisitsCount + N.LikesCount) ASC, N.NodeID ASC) AS RevRowNumber,
					N.*
			FROM (
					SELECT	V.NodeID,
							V.NodeTypeID,
							V.Name,
							V.NodeType,
							V.[Count] AS VisitsCount,
							ISNULL(L.[Count], 0) AS LikesCount
					FROM (
							SELECT	ND.NodeID,
									CAST(MAX(CAST(ND.NodeTypeID AS varchar(50))) 
										AS uniqueidentifier) AS NodeTypeID,
									MAX(ND.NodeName) AS Name,
									MAX(ND.TypeName) AS NodeType,
									COUNT(IV.UserID) AS [Count]
							FROM [dbo].[CN_View_Nodes_Normal] AS ND
								INNER JOIN [dbo].[USR_ItemVisits] AS IV
								ON IV.ApplicationID = @ApplicationID AND IV.ItemID = ND.NodeID
							WHERE ND.ApplicationID = @ApplicationID AND 
								(@_cnt = 0 OR ND.NodeTypeID IN (SELECT Value FROM @NodeTypeIDs)) AND--(@NodeTypeID IS NULL OR ND.NodeTypeID = @NodeTypeID) AND
								(@ParentNodeID IS NULL OR ND.ParentNodeID = @ParentNodeID) AND
								ND.Deleted = 0
							GROUP BY ND.NodeID
						) AS V
						LEFT JOIN (
							SELECT NL.NodeID, COUNT(NL.UserID) AS [Count]
							FROM [dbo].[CN_NodeLikes] AS NL
							WHERE NL.ApplicationID = @ApplicationID
							GROUP BY NL.NodeID
						) AS L
						ON L.NodeID = V.NodeID
				) AS N
		) AS Ref
	WHERE Ref.RowNumber >= ISNULL(@LowerBoundary, 0)
	ORDER BY Ref.RowNumber ASC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetParentNodes]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetParentNodes]
GO

CREATE PROCEDURE [dbo].[CN_GetParentNodes]
	@ApplicationID	uniqueidentifier,
	@NodeID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @NodeTypeID uniqueidentifier, @_ChildTypeID uniqueidentifier
	
	SET @NodeTypeID = (
		SELECT NodeTypeID 
		FROM [dbo].[CN_Nodes] 
		WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID
	)
	
	SET @_ChildTypeID = [dbo].[CN_FN_GetChildRelationTypeID](@ApplicationID)

	DECLARE @NodeIDs KeyLessGuidTableType
	
	INSERT INTO @NodeIDs (Value)
	SELECT NR.DestinationNodeID
	FROM [dbo].[CN_NodeRelations] AS NR
		INNER JOIN [dbo].[CN_Nodes] AS Nodes
		ON Nodes.ApplicationID = @ApplicationID AND Nodes.NodeID = NR.DestinationNodeID
	WHERE NR.ApplicationID = @ApplicationID AND 
		NR.SourceNodeID = @NodeID AND NR.PropertyID = @_ChildTypeID AND
		NR.Deleted = 0 AND Nodes.NodeTypeID = @NodeTypeID AND Nodes.Deleted = 0
	
	EXEC [dbo].[CN_P_GetNodesByIDs] @ApplicationID, @NodeIDs, 0, NULL
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetChildNodes]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetChildNodes]
GO

CREATE PROCEDURE [dbo].[CN_GetChildNodes]
	@ApplicationID	uniqueidentifier,
	@NodeID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @NodeTypeID uniqueidentifier, @_ParentTypeID uniqueidentifier
	
	SET @NodeTypeID = (
		SELECT NodeTypeID 
		FROM [dbo].[CN_Nodes] 
		WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID
	)
	
	SET @_ParentTypeID = [dbo].[CN_FN_GetParentRelationTypeID](@ApplicationID)

	DECLARE @NodeIDs KeyLessGuidTableType
	
	INSERT INTO @NodeIDs (Value)
	SELECT NR.DestinationNodeID
	FROM [dbo].[CN_NodeRelations] AS NR
		INNER JOIN [dbo].[CN_Nodes] AS Nodes
		ON Nodes.ApplicationID = @ApplicationID AND Nodes.NodeID = NR.DestinationNodeID
	WHERE NR.ApplicationID = @ApplicationID AND
		NR.SourceNodeID = @NodeID AND NR.PropertyID = @_ParentTypeID AND
		NR.Deleted = 0 AND Nodes.NodeTypeID = @NodeTypeID AND Nodes.Deleted = 0
	
	EXEC [dbo].[CN_P_GetNodesByIDs] @ApplicationID, @NodeIDs, 0, NULL
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetDefaultRelatedNodes]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetDefaultRelatedNodes]
GO

CREATE PROCEDURE [dbo].[CN_GetDefaultRelatedNodes]
	@ApplicationID	uniqueidentifier,
	@NodeID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @NodeTypeID uniqueidentifier, @_RelatedTypeID uniqueidentifier
	
	SET @NodeTypeID = (
		SELECT NodeTypeID 
		FROM [dbo].[CN_Nodes] 
		WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID
	)
	
	SET @_RelatedTypeID = [dbo].[CN_FN_GetRelatedRelationTypeID](@ApplicationID)

	DECLARE @NodeIDs KeyLessGuidTableType
	
	INSERT INTO @NodeIDs (Value)
	SELECT NR.DestinationNodeID
	FROM [dbo].[CN_NodeRelations] AS NR
		INNER JOIN [dbo].[CN_Nodes] AS Nodes
		ON Nodes.ApplicationID = @ApplicationID AND Nodes.NodeID = NR.DestinationNodeID
	WHERE NR.ApplicationID = @ApplicationID AND 
		NR.SourceNodeID = @NodeID AND NR.PropertyID = @_RelatedTypeID AND
		NR.Deleted = 0 AND Nodes.NodeTypeID = @NodeTypeID AND Nodes.Deleted = 0
	
	EXEC [dbo].[CN_P_GetNodesByIDs] @ApplicationID, @NodeIDs, 0, NULL
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetDefaultConnectedNodes]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetDefaultConnectedNodes]
GO

CREATE PROCEDURE [dbo].[CN_GetDefaultConnectedNodes]
	@ApplicationID	uniqueidentifier,
	@NodeID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @NodeIDs KeyLessGuidTableType
	
	INSERT INTO @NodeIDs (Value)
	SELECT NR.DestinationNodeID
	FROM [dbo].[CN_NodeRelations] AS NR
		INNER JOIN [dbo].[CN_View_Nodes_Normal] AS Nodes
		ON Nodes.ApplicationID = @ApplicationID AND Nodes.NodeID = NR.DestinationNodeID
	WHERE NR.ApplicationID = @ApplicationID AND NR.SourceNodeID = @NodeID AND NR.Deleted = 0 AND 
		(Nodes.TypeAdditionalID = N'1' OR Nodes.TypeAdditionalID = N'2' OR
		 Nodes.TypeAdditionalID = N'3' OR Nodes.TypeAdditionalID = N'4') AND Nodes.Deleted = 0
	
	EXEC [dbo].[CN_P_GetNodesByIDs] @ApplicationID, @NodeIDs, 0, NULL
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetBrotherNodes]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetBrotherNodes]
GO

CREATE PROCEDURE [dbo].[CN_GetBrotherNodes]
	@ApplicationID	uniqueidentifier,
	@NodeID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @NodeTypeID uniqueidentifier, @_ChildTypeID uniqueidentifier
	
	SET @NodeTypeID = (
		SELECT NodeTypeID 
		FROM [dbo].[CN_Nodes] 
		WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID
	)
	
	SET @_ChildTypeID = [dbo].[CN_FN_GetChildRelationTypeID](@ApplicationID)

	DECLARE @ParentNodeIDs GuidTableType
	
	INSERT INTO @ParentNodeIDs
	SELECT NR.DestinationNodeID
	FROM [dbo].[CN_NodeRelations] AS NR
		INNER JOIN [dbo].[CN_Nodes] AS Nodes
		ON Nodes.ApplicationID = @ApplicationID AND Nodes.NodeID = NR.DestinationNodeID
	WHERE NR.ApplicationID = @ApplicationID AND 
		NR.SourceNodeID = @NodeID AND NR.PropertyID = @_ChildTypeID AND
		NR.Deleted = 0 AND Nodes.NodeTypeID = @NodeTypeID AND Nodes.Deleted = 0
	
		
	DECLARE @NodeIDs KeyLessGuidTableType
	
	INSERT INTO @NodeIDs (Value)
	SELECT NR.SourceNodeID
	FROM @ParentNodeIDs AS Ref
		INNER JOIN [dbo].[CN_NodeRelations] AS NR
		ON NR.DestinationNodeID = Ref.Value
		INNER JOIN [dbo].[CN_Nodes] AS Nodes
		ON Nodes.ApplicationID = @ApplicationID AND Nodes.NodeID = NR.SourceNodeID
	WHERE NR.ApplicationID = @ApplicationID AND 
		NR.PropertyID = @_ChildTypeID AND NR.Deleted = 0 AND 
		Nodes.NodeTypeID = @NodeTypeID AND Nodes.Deleted = 0
	
	
	EXEC [dbo].[CN_P_GetNodesByIDs] @ApplicationID, @NodeIDs, 0, NULL
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetDirectChilds]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetDirectChilds]
GO

CREATE PROCEDURE [dbo].[CN_GetDirectChilds]
	@ApplicationID			uniqueidentifier,
	@NodeID					uniqueidentifier,
	@NodeTypeID				uniqueidentifier,
	@NodeTypeAdditionalID	nvarchar(20),
	@Searchable				bit,
	@LowerBoundary			float,
	@Count					int,
	@OrderBy				varchar(100),
	@OrderByDesc			bit,
	@SearchText				nvarchar(1000),
	@CheckAccess			bit,
	@CurrentUserID			uniqueidentifier,
	@Now					datetime,
	@DefaultPrivacy			varchar(50)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF @NodeTypeID IS NULL AND ISNULL(@NodeTypeAdditionalID, N'') <> N''
		SET @NodeTypeID = [dbo].[CN_FN_GetNodeTypeID](@ApplicationID, @NodeTypeAdditionalID)

	DECLARE @NodeIDs KeyLessGuidTableType
	DECLARE @TempIDs KeyLessGuidTableType
	
	IF ISNULL(@SearchText, N'') = N'' BEGIN
		CREATE TABLE #Results (NodeID uniqueidentifier)
		
		IF @OrderBy = 'Type' SET @OrderBy = 'TypeName'	
		ELSE IF @OrderBy = N'Date' SET @OrderBy = 'CreationDate'	
		ELSE IF @OrderBy = N'Name' SET @OrderBy = 'NodeName'
		ELSE SET @OrderBy = 'SequenceNumber'
		
		DECLARE @SortOrder varchar(10) = 'ASC'
		IF @OrderByDesc = 1 SET @SortOrder = 'DESC'
		
		DECLARE @SecondaryOrder varchar(100) = N''
		IF @OrderBy <> 'CreationDate' SET @SecondaryOrder = ', ND.CreationDate ASC'
		
		DECLARE @strSearchable varchar(100) = N''
		IF @Searchable IS NOT NULL BEGIN
			SET @strSearchable = N'ISNULL(ND.Searchable, 1) = ' + (CASE WHEN @Searchable = 1 THEN N'1' ELSE N'0' END) + ' AND '
		END
		
		DECLARE @ToBeExecuted varchar(2000) =
			'INSERT INTO #Results (NodeID) ' +
			'SELECT X.NodeID ' +
			'FROM ( ' +
					'SELECT	ROW_NUMBER() OVER (ORDER BY ND.' + @OrderBy + ' ' + 
								@SortOrder + @SecondaryOrder + ', ND.CreationDate ASC, ND.NodeID ' + @SortOrder + ') AS RowNumber, ' +
							'ND.NodeID ' +
					'FROM [dbo].[CN_View_Nodes_Normal] AS ND ' +
					'WHERE ND.ApplicationID = N''' + CAST(@ApplicationID AS varchar(100)) + ''' AND ' +
						CASE 
							WHEN @NodeTypeID IS NULL THEN '' 
							ELSE 'ND.NodeTypeID = N''' + CAST(@NodeTypeID AS varchar(100)) + ''' AND '
						END +
						CASE
							WHEN @NodeID IS NOT NULL THEN 
								'ND.ParentNodeID = N''' + CAST(@NodeID AS varchar(100)) + ''' AND ND.ParentNodeID <> ND.NodeID AND '
							ELSE '(ND.ParentNodeID IS NULL OR ND.ParentNodeID = ND.NodeID) AND '
						END +
						@strSearchable + ' ' + 'ND.Deleted = 0 ' +
				') AS X ' +
			'ORDER BY X.RowNumber ASC'
		
		EXEC (@ToBeExecuted)
		
		INSERT INTO @TempIDs (Value)
		SELECT *
		FROM #Results
	END
	ELSE BEGIN
		DECLARE @NIDs GuidTableType
	
		IF @NodeID IS NOT NULL BEGIN
			INSERT INTO @NIDs (Value)
			VALUES (@NodeID)
			
			INSERT INTO @NIDs (Value)
			SELECT DISTINCT H.NodeID
			FROM @NodeIDs AS N
				RIGHT JOIN [dbo].[CN_FN_GetChildNodesDeepHierarchy](@ApplicationID, @NIDs) AS H
				ON H.NodeID = N.Value
			WHERE N.Value IS NULL AND H.NodeID <> @NodeID
			
			DELETE @NIDs
			WHERE Value = @NodeID
		END
		
		DECLARE @NodeIDsCount int = (SELECT COUNT(*) FROM @NIDs)
		
		INSERT INTO @TempIDs (Value)
		SELECT X.NodeID
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY SRCH.[Rank] DESC, SRCH.[Key] ASC) AS RowNumber,
						SRCH.[Key] AS NodeID
				FROM CONTAINSTABLE([dbo].[CN_Nodes], ([Name], [AdditionalID]), @SearchText) AS SRCH
					INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
					ON ND.NodeID = SRCH.[Key]
					LEFT JOIN @NIDs AS I
					ON I.Value = ND.NodeID
				WHERE ApplicationID = @ApplicationID AND 
					(@NodeTypeID IS NULL OR NodeTypeID = @NodeTypeID) AND 
					(@NodeIDsCount = 0 OR I.Value IS NOT NULL) AND 
					(@Searchable IS NULL OR ISNULL(ND.Searchable, 1) = @Searchable) AND ND.Deleted = 0
			) AS X
		ORDER BY X.RowNumber ASC
	END
	
	IF ISNULL(@CheckAccess, 0) = 1 BEGIN
		DECLARE	@PermissionTypes StringPairTableType
		
		INSERT INTO @PermissionTypes (FirstValue, SecondValue)
		VALUES (N'View', @DefaultPrivacy)
	
		DELETE T
		FROM @TempIDs AS T
			LEFT JOIN [dbo].[PRVC_FN_CheckAccess](@ApplicationID, @CurrentUserID, 
				@TempIDs, N'Node', @Now, @PermissionTypes) AS A
			ON A.ID = T.Value
		WHERE A.ID IS NULL
	END
	
	INSERT INTO @NodeIDs (Value)
	SELECT TOP(ISNULL(@Count, 1000000)) X.Value
	FROM @TempIDs AS X
	WHERE X.SequenceNumber >= ISNULL(@LowerBoundary, 0)
	ORDER BY X.SequenceNumber ASC
	
	EXEC [dbo].[CN_P_GetNodesByIDs] @ApplicationID, @NodeIDs, 0, NULL
	
	SELECT CAST(COUNT(ID.Value) AS bigint) AS TotalCount
	FROM @TempIDs AS ID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetDirectParent]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetDirectParent]
GO

CREATE PROCEDURE [dbo].[CN_GetDirectParent]
	@ApplicationID	uniqueidentifier,
	@NodeID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @NodeIDs KeyLessGuidTableType
	
	INSERT INTO @NodeIDs (Value)
	SELECT Parent.NodeID
	FROM [dbo].[CN_Nodes] AS Node
		INNER JOIN [dbo].[CN_Nodes] AS Parent
		ON Parent.ApplicationID = @ApplicationID AND Parent.NodeID = Node.ParentNodeID
	WHERE Node.ApplicationID = @ApplicationID AND Node.NodeID = @NodeID AND 
		Node.ParentNodeID IS NOT NULL AND Parent.Deleted = 0
	
	EXEC [dbo].[CN_P_GetNodesByIDs] @ApplicationID, @NodeIDs, 0, NULL
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_SetDirectParent]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_SetDirectParent]
GO

CREATE PROCEDURE [dbo].[CN_SetDirectParent]
	@ApplicationID			uniqueidentifier,
	@strNodeIDs				varchar(max),
	@delimiter				char,
	@ParentNodeID			uniqueidentifier,
	@LastModifierUserID		uniqueidentifier,
	@LastModificationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeIDs GuidTableType
	INSERT INTO @NodeIDs
	SELECT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strNodeIDs, @delimiter) AS Ref
	
	DECLARE @ParentHierarchy NodesHierarchyTableType
	
	IF @ParentNodeID IS NOT NULL BEGIN
		INSERT INTO @ParentHierarchy
		EXEC [dbo].[CN_P_GetNodeHierarchy] @ApplicationID, @ParentNodeID, 0
	END
	
	IF EXISTS(
		SELECT TOP(1) 1
		FROM @ParentHierarchy AS P
			INNER JOIN @NodeIDs AS N
			ON N.Value = P.NodeID
	) BEGIN
		SELECT -1, N'CannotTransferToChilds'
		RETURN
	END

	UPDATE ND
		SET LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate,
			ParentNodeID = @ParentNodeID
	FROM @NodeIDs AS Ref
		INNER JOIN [dbo].[CN_Nodes] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.[NodeID] = Ref.Value
	WHERE (@ParentNodeID IS NULL OR ND.[NodeID] <> @ParentNodeID)
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_HaveChilds]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_HaveChilds]
GO

CREATE PROCEDURE [dbo].[CN_HaveChilds]
	@ApplicationID	uniqueidentifier,
	@strNodeIDs		varchar(max),
	@delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeIDs GuidTableType
	INSERT INTO @NodeIDs
	SELECT DISTINCT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strNodeIDs, @delimiter) AS Ref
	
	SELECT ExternalIDs.Value AS ID
	FROM @NodeIDs AS ExternalIDs
	WHERE EXISTS(
		SELECT TOP(1) * 
		FROM [dbo].[CN_Nodes] 
		WHERE ApplicationID = @ApplicationID AND 
			(ParentNodeID = ExternalIDs.Value AND ParentNodeID <> NodeID) AND Deleted = 0)
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_GetRelatedNodeIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_GetRelatedNodeIDs]
GO

CREATE PROCEDURE [dbo].[CN_P_GetRelatedNodeIDs]
	@ApplicationID		uniqueidentifier,
	@NodeIDOrUserID		uniqueidentifier,
	@RelatedNodeTypeID	uniqueidentifier,
	@SearchText			nvarchar(1000),
	@In					bit,
	@Out				bit,
	@InTags				bit,
	@OutTags			bit,
	@Count				int,
	@LowerBoundary		int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @SearchText = [dbo].[GFN_VerifyString](@SearchText)

	DECLARE @SourceIDs GuidTableType
	
	IF @NodeIDOrUserID IS NOT NULL BEGIN
		INSERT INTO @SourceIDs(Value) VALUES(@NodeIDOrUserID)
	END
	
	DECLARE @RelatedTypeIDs GuidTableType
	
	IF @RelatedNodeTypeID IS NOT NULL BEGIN
		INSERT INTO @RelatedTypeIDs(Value) VALUES(@RelatedNodeTypeID)
	END
	
	DECLARE @NodeIDs KeyLessGuidTableType
	
	IF EXISTS(
		SELECT TOP(1) UN.UserID
		FROM [dbo].[Users_Normal] AS UN 
		WHERE UN.ApplicationID = @ApplicationID AND UN.UserID = @NodeIDOrUserID
	) BEGIN
		INSERT INTO @NodeIDs (Value)
		SELECT Ref.RelatedNodeID
		FROM [dbo].[CN_FN_GetUserRelatedNodeIDs](@ApplicationID, @SourceIDs, @RelatedTypeIDs) AS Ref
	END
	ELSE BEGIN
		DECLARE @SourceNodeTypeIDs GuidTableType

		INSERT INTO @NodeIDs (Value)
		SELECT Ref.RelatedNodeID
		FROM [dbo].[CN_FN_GetRelatedNodeIDs](@ApplicationID, 
			@SourceIDs, @SourceNodeTypeIDs, @RelatedTypeIDs, @In, @Out, @InTags, @OutTags) AS Ref
	END
	
	
	IF ISNULL(@SearchText, N'') = N'' BEGIN
		SELECT TOP(ISNULL(@Count, 1000000)) ND.Value AS ID
		FROM @NodeIDs AS ND
		WHERE ND.SequenceNumber >= ISNULL(@LowerBoundary, 0)
		ORDER BY ND.SequenceNumber ASC
	END
	ELSE BEGIN
		SELECT TOP(ISNULL(@Count, 1000000)) X.NodeID AS ID
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY SRCH.[Rank] DESC, ND.SequenceNumber ASC) AS RowNumber,
						ND.Value AS NodeID
				FROM CONTAINSTABLE([dbo].[CN_Nodes], (Name, Tags, AdditionalID), @SearchText) AS SRCH
					INNER JOIN @NodeIDs AS ND
					ON ND.Value = SRCH.[Key]
			) AS X
		WHERE X.RowNumber >= ISNULL(@LowerBoundary, 0)
		ORDER BY X.RowNumber ASC
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetRelatedNodeIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetRelatedNodeIDs]
GO

CREATE PROCEDURE [dbo].[CN_GetRelatedNodeIDs]
	@ApplicationID		uniqueidentifier,
	@NodeID				uniqueidentifier,
	@RelatedNodeTypeID	uniqueidentifier,
	@SearchText			nvarchar(1000),
	@In					bit,
	@Out				bit,
	@InTags				bit,
	@OutTags			bit,
	@Count				int,
	@LowerBoundary		int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	EXEC [dbo].[CN_P_GetRelatedNodeIDs] @ApplicationID, @NodeID, @RelatedNodeTypeID, 
		@SearchText, @In, @Out, @InTags, @OutTags, @Count, @LowerBoundary
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetRelatedNodes]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetRelatedNodes]
GO

CREATE PROCEDURE [dbo].[CN_GetRelatedNodes]
	@ApplicationID		uniqueidentifier,
	@NodeID				uniqueidentifier,
	@RelatedNodeTypeID	uniqueidentifier,
	@SearchText			nvarchar(1000),
	@In					bit,
	@Out				bit,
	@InTags				bit,
	@OutTags			bit,
	@Count				int,
	@LowerBoundary		int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeIDs KeyLessGuidTableType
	
	INSERT INTO @NodeIDs (Value)
	EXEC [dbo].[CN_P_GetRelatedNodeIDs] @ApplicationID, @NodeID, @RelatedNodeTypeID, 
		@SearchText, @In, @Out, @InTags, @OutTags, @Count, @LowerBoundary
	
	EXEC [dbo].[CN_P_GetNodesByIDs] @ApplicationID, @NodeIDs, 0, NULL
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetRelatedNodesCount]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetRelatedNodesCount]
GO

CREATE PROCEDURE [dbo].[CN_GetRelatedNodesCount]
	@ApplicationID		uniqueidentifier,
	@NodeID				uniqueidentifier,
	@RelatedNodeTypeID	uniqueidentifier,
	@SearchText			nvarchar(1000),
	@In					bit,
	@Out				bit,
	@InTags				bit,
	@OutTags			bit,
	@Count				int,
	@LowerBoundary		int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeIDs KeyLessGuidTableType
	
	INSERT INTO @NodeIDs (Value)
	EXEC [dbo].[CN_P_GetRelatedNodeIDs] @ApplicationID, @NodeID, @RelatedNodeTypeID, 
		@SearchText, @In, @Out, @InTags, @OutTags, @Count, @LowerBoundary
	
	SELECT *
	FROM (
			SELECT	ND.NodeTypeID,
					MAX(ND.TypeAdditionalID) AS NodeTypeAdditionalID,
					MAX(ND.TypeName) AS TypeName,
					COUNT(ND.NodeID) AS NodesCount
			FROM @NodeIDs AS IDs
				INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
				ON ND.ApplicationID = @ApplicationID AND ND.NodeID = IDs.Value
			GROUP BY ND.NodeTypeID
		) AS X
	ORDER BY X.NodesCount DESC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetRelatedNodesPartitioned]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetRelatedNodesPartitioned]
GO

CREATE PROCEDURE [dbo].[CN_GetRelatedNodesPartitioned]
	@ApplicationID	uniqueidentifier,
	@NodeID			uniqueidentifier,
	@strNodeTypeIDs varchar(max),
	@delimiter		char,
	@In				bit,
	@Out			bit,
	@InTags			bit,
	@OutTags		bit,
	@Count			int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @TypeIDs GuidTableType
	
	INSERT INTO @TypeIDs (Value)
	SELECT DISTINCT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strNodeTypeIDs, @delimiter) AS Ref
	
	DECLARE @HasNodeTypeID bit = (SELECT TOP(1) CAST(1 AS bit) FROM @TypeIDs)
	
	DECLARE @NodeIDs KeyLessGuidTableType
	
	INSERT INTO @NodeIDs (Value)
	EXEC [dbo].[CN_P_GetRelatedNodeIDs] @ApplicationID, @NodeID, NULL, 
		NULL, @In, @Out, @InTags, @OutTags, 1000000, NULL
	
	DECLARE @RetIDs KeyLessGuidTableType
	
	INSERT INTO @RetIDs (Value)
	SELECT X.NodeID
	FROM (
			SELECT	ROW_NUMBER() OVER (PARTITION BY N.NodeTypeID ORDER BY N.CreationDate DESC, N.NodeID DESC) AS Number,
					N.NodeID
			FROM @NodeIDs AS ID
				INNER JOIN [dbo].[CN_View_Nodes_Normal] AS N
				ON N.ApplicationID = @ApplicationID AND N.NodeID = ID.Value
			WHERE @HasNodeTypeID = 0 OR N.NodeTypeID IN (SELECT T.Value FROM @TypeIDs AS T)
		) AS X
	WHERE X.Number <= ISNULL(@Count, 5)
	
	EXEC [dbo].[CN_P_GetNodesByIDs] @ApplicationID, @RetIDs, 0, NULL
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_RelationExists]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_RelationExists]
GO

CREATE PROCEDURE [dbo].[CN_RelationExists]
	@ApplicationID				uniqueidentifier,
	@SourceNodeID				uniqueidentifier,
	@DestinationNodeID			uniqueidentifier,
	@ReverseAlso				bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT CAST(1 AS bit) 
	FROM [dbo].[CN_NodeRelations]
	WHERE ApplicationID = @ApplicationID AND 
		((SourceNodeID = @SourceNodeID AND DestinationNodeID = @DestinationNodeID) OR
		(@ReverseAlso = 1 AND SourceNodeID = @DestinationNodeID AND
		  DestinationNodeID = @SourceNodeID)) AND Deleted = 0
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_GetNodeHierarchy]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_GetNodeHierarchy]
GO

CREATE PROCEDURE [dbo].[CN_P_GetNodeHierarchy]
	@ApplicationID	uniqueidentifier,
	@NodeID			uniqueidentifier,
	@SameType		bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeTypeID uniqueidentifier = NULL
		
	IF @SameType = 1 BEGIN
		SET @NodeTypeID = (
			SELECT TOP(1) NodeTypeID 
			FROM [dbo].[CN_Nodes] 
			WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID
		)
	END
 	
	;WITH hierarchy (ID, ParentID, [Level], Name)
	AS
	(
		SELECT NodeID AS ID, ParentNodeID AS ParentID, 0 AS [Level], Name
		FROM [dbo].[CN_Nodes]
		WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID
		
		UNION ALL
		
		SELECT Node.NodeID AS ID, Node.ParentNodeID AS ParentID, [Level] + 1, Node.Name
		FROM [dbo].[CN_Nodes] AS Node
			INNER JOIN hierarchy AS HR
			ON HR.ParentID = Node.NodeID
		WHERE ApplicationID = @ApplicationID AND 
			(@NodeTypeID IS NULL OR Node.NodeTypeID = @NodeTypeID) AND
			Node.NodeID <> HR.ID AND Node.Deleted = 0
	)
	
	SELECT * 
	FROM hierarchy
	ORDER BY hierarchy.[Level] ASC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetNodeHierarchy]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetNodeHierarchy]
GO

CREATE PROCEDURE [dbo].[CN_GetNodeHierarchy]
	@ApplicationID	uniqueidentifier,
	@NodeID			uniqueidentifier,
	@SameType		bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	EXEC [dbo].[CN_P_GetNodeHierarchy] @ApplicationID, @NodeID, @SameType
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetNodeTypesHierarchy]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetNodeTypesHierarchy]
GO

CREATE PROCEDURE [dbo].[CN_GetNodeTypesHierarchy]
	@ApplicationID	uniqueidentifier,
	@strNodeTypeIDs	nvarchar(max),
	@delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeTypeIds GuidTableType
	
	INSERT INTO @NodeTypeIDs (Value)
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strNodeTypeIds, @delimiter) AS Ref
	
	;WITH hierarchy (ID, ParentID, [Level], Name)
	AS
	(
		SELECT NT.NodeTypeID AS ID, NT.ParentID, 0 AS [Level], NT.Name
		FROM @NodeTypeIDs AS R
			INNER JOIN [dbo].[CN_NodeTypes] AS NT
			ON NT.ApplicationID = @ApplicationID AND NT.NodeTypeID = R.Value
		
		UNION ALL
		
		SELECT NT.NodeTypeID AS ID, NT.ParentID, [Level] + 1, NT.Name
		FROM [dbo].[CN_NodeTypes] AS NT
			INNER JOIN hierarchy AS HR
			ON HR.ParentID = NT.NodeTypeID
		WHERE NT.ApplicationID = @ApplicationID AND NT.NodeTypeID <> HR.ID AND NT.Deleted = 0
	)
	
	SELECT * 
	FROM hierarchy
	ORDER BY hierarchy.[Level] ASC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetTreeDepth]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetTreeDepth]
GO

CREATE PROCEDURE [dbo].[CN_GetTreeDepth]
	@ApplicationID	uniqueidentifier,
	@NodeTypeID		uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeIDs GuidTableType

	INSERT INTO @NodeIDs (Value)
	SELECT ND.NodeID
	FROM [dbo].[CN_Nodes] AS ND
	WHERE ND.ApplicationID = @ApplicationID AND ND.NodeTypeID = @NodeTypeID AND 
		ND.ParentNodeID IS NULL AND ND.Deleted = 0
		
	SELECT TOP(1) MAX(Ref.[Level]) + 1 AS Value
	FROM [dbo].[CN_FN_GetChildNodesDeepHierarchy](@ApplicationID, @NodeIDs) AS Ref
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_AddMember]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_AddMember]
GO

CREATE PROCEDURE [dbo].[CN_AddMember]
	@ApplicationID		uniqueidentifier,
    @NodeID				uniqueidentifier,
    @UserID				uniqueidentifier,
    @MembershipDate		datetime,
    @IsAdmin			bit,
    @IsPending			bit,
    @AcceptionDate		datetime,
    @Position			nvarchar(255)
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE @_Result int
	
	EXEC [dbo].[CN_P_AddMember] @ApplicationID, @NodeID, @UserID, @MembershipDate, 
		@IsAdmin, @IsPending, @AcceptionDate, @Position, @_Result output
	
	IF @_Result <= 0 BEGIN
		ROLLBACK TRANSACTION
		RETURN
	END
	
	-- Send new dashboards
	IF @IsPending = 1 BEGIN 
		DECLARE @AdminIDs GuidTableType
		
		INSERT INTO @AdminIDs (Value)
		SELECT NM.UserID
		FROM [dbo].[CN_View_NodeMembers] AS NM
		WHERE NM.ApplicationID = @ApplicationID AND NM.NodeID = @NodeID AND 
			NM.IsAdmin = 1 AND NM.IsPending = 0 AND NM.UserID <> @UserID
	
		DECLARE @Dashboards DashboardTableType
		
		INSERT INTO @Dashboards(UserID, NodeID, RefItemID, [Type], Removable, SendDate)
		SELECT	Ref.Value, 
				@NodeID,
				@UserID,
				N'MembershipRequest',
				0,
				@MembershipDate
		FROM @AdminIDs AS Ref
		
		EXEC [dbo].[NTFN_P_SendDashboards] @ApplicationID, @Dashboards, @_Result output
		
		IF @_Result <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
		ELSE BEGIN
			SELECT @_Result
		
			SELECT * 
			FROM @Dashboards
		END	
	END
	ELSE SELECT @_Result
	-- end of send new dashboards
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_ArithmeticDeleteMember]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_ArithmeticDeleteMember]
GO

CREATE PROCEDURE [dbo].[CN_ArithmeticDeleteMember]
	@ApplicationID	uniqueidentifier,
    @NodeID			uniqueidentifier,
    @UserID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE @_Result int
	
	EXEC [dbo].[CN_P_UpdateMember] @ApplicationID, @NodeID, @UserID, NULL, 
		NULL, NULL, NULL, NULL, 1, @_Result output
	
    IF @_Result <= 0 BEGIN
		ROLLBACK TRANSACTION
		RETURN
    END
    
    IF @_Result > 0 BEGIN
		EXEC [dbo].[NTFN_P_ArithmeticDeleteDashboards] @ApplicationID, 
			NULL, @NodeID, @UserID, N'MembershipRequest', NULL, @_Result output
			
		IF @_Result <= 0 BEGIN
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	SELECT @_Result
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_RemoveNodeMembers]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_RemoveNodeMembers]
GO

CREATE PROCEDURE [dbo].[CN_RemoveNodeMembers]
	@ApplicationID		uniqueidentifier,
    @NodeMembersTemp	GuidPairTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @NodeMembers GuidPairTableType
	INSERT INTO @NodeMembers (FirstValue, SecondValue)
	SELECT T.FirstValue, T.SecondValue
	FROM @NodeMembersTemp AS T

	UPDATE NM
	SET Deleted = 1
	FROM @NodeMembers AS Ref
		INNER JOIN [dbo].[CN_NodeMembers] AS NM
		ON NM.ApplicationID = @ApplicationID AND 
			NM.NodeID = Ref.FirstValue AND NM.UserID = Ref.SecondValue

    SELECT 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_AcceptMember]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_AcceptMember]
GO

CREATE PROCEDURE [dbo].[CN_AcceptMember]
	@ApplicationID	uniqueidentifier,
    @NodeID			uniqueidentifier,
    @UserID			uniqueidentifier,
    @AcceptionDate	datetime
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE @_Result int
	
	EXEC [dbo].[CN_P_UpdateMember] @ApplicationID, @NodeID, @UserID, NULL,
		NULL, 0, @AcceptionDate, NULL, NULL, @_Result output
	
    IF @_Result <= 0 BEGIN
		ROLLBACK TRANSACTION
		RETURN
    END
    
    IF @_Result > 0 BEGIN
		EXEC [dbo].[NTFN_P_ArithmeticDeleteDashboards] @ApplicationID, 
			NULL, @NodeID, @UserID, N'MembershipRequest', NULL, @_Result output
			
		IF @_Result <= 0 BEGIN
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	SELECT @_Result
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_SaveMembers]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_SaveMembers]
GO

CREATE PROCEDURE [dbo].[CN_SaveMembers]
	@ApplicationID	uniqueidentifier,
    @NodeID			uniqueidentifier,
    @UserIDsTemp	GuidTableType readonly,
	@Now			datetime
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserIDs GuidTableType
	INSERT INTO @UserIDs (Value) SELECT Ref.Value FROM @UserIDsTemp AS Ref

	UPDATE NM
	SET Deleted = CASE WHEN U.Value IS NULL THEN 1 ELSE 0 END
	FROM [dbo].[CN_NodeMembers] AS NM
		LEFT JOIN @UserIDs AS U
		ON U.Value = NM.UserID
	WHERE NM.ApplicationID = @ApplicationID AND NM.NodeID = @NodeID

	INSERT INTO [dbo].[CN_NodeMembers] (
		ApplicationID, 
		NodeID, 
		UserID, 
		[Status], 
		MembershipDate, 
		AcceptionDate, 
		IsAdmin, 
		UniqueID, 
		Deleted
	)
	SELECT @ApplicationID, @NodeID, U.Value, N'Accepted', @Now, @Now, 0, NEWID(), 0
	FROM @UserIDs AS U
		LEFT JOIN [dbo].[CN_NodeMembers] AS NM
		ON NM.ApplicationID = @ApplicationID AND NM.NodeID = @NodeID AND NM.UserID = U.Value
	WHERE NM.NodeID IS NULL

	SELECT 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_SetMemberPosition]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_SetMemberPosition]
GO

CREATE PROCEDURE [dbo].[CN_SetMemberPosition]
	@ApplicationID	uniqueidentifier,
    @NodeID			uniqueidentifier,
    @UserID			uniqueidentifier,
    @Position		nvarchar(255)
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE @_Result int
	
	EXEC [dbo].[CN_P_UpdateMember] @ApplicationID, @NodeID, @UserID, NULL,
		NULL, NULL, NULL, @Position, NULL, @_Result output
	
	SELECT @_Result
	
    IF @_Result <= 0 BEGIN
		ROLLBACK TRANSACTION
		RETURN
    END
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_IsNodeCreator]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_IsNodeCreator]
GO

CREATE PROCEDURE [dbo].[CN_P_IsNodeCreator]
	@ApplicationID	uniqueidentifier,
    @NodeID			uniqueidentifier,
    @UserID			uniqueidentifier,
    @_IsCreator		bit output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

    SELECT @_IsCreator = CAST(1 as bit) 
    WHERE EXISTS(
			SELECT TOP(1) * 
			FROM [dbo].[CN_Nodes]
			WHERE ApplicationID = @ApplicationID AND 
				NodeID = @NodeID AND CreatorUserID = @UserID
		) OR EXISTS(
			SELECT TOP(1) * 
			FROM [dbo].[CN_NodeCreators]
			WHERE ApplicationID = @ApplicationID AND 
				NodeID = @NodeID AND UserID = @UserID AND Deleted = 0
		)
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_IsNodeCreator]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_IsNodeCreator]
GO

CREATE PROCEDURE [dbo].[CN_IsNodeCreator]
	@ApplicationID	uniqueidentifier,
    @NodeID			uniqueidentifier,
    @NodeTypeID		uniqueidentifier,
    @AdditionalID	varchar(50),
    @UserID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF @NodeID IS NULL AND @AdditionalID IS NOT NULL BEGIN
		;WITH X (NodeID)
		AS
		(
			SELECT NodeID 
			FROM [dbo].[CN_Nodes] 
			WHERE ApplicationID = @ApplicationID AND 
				(@NodeTypeID IS NULL OR NodeTypeID = @NodeTypeID) AND 
				AdditionalID = @AdditionalID
		)
		SELECT TOP(1) @NodeID = X.NodeID
		FROM X
		WHERE (SELECT COUNT(*) FROM X) = 1
	END
	
	DECLARE @IsCreator bit

    EXEC [dbo].[CN_P_IsNodeCreator] @ApplicationID, @NodeID, @UserID, @IsCreator output
    
    SELECT @IsCreator
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_IsNodeMember]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_IsNodeMember]
GO

CREATE PROCEDURE [dbo].[CN_P_IsNodeMember]
	@ApplicationID	uniqueidentifier,
    @NodeID			uniqueidentifier,
    @UserID			uniqueidentifier,
    @IsAdmin		bit,
    @Status			varchar(20),
    @_IsMember		bit output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

    SELECT TOP(1) @_IsMember = 1
	FROM [dbo].[CN_NodeMembers]
	WHERE ApplicationID = @ApplicationID AND 
		NodeID = @NodeID AND UserID = @UserID AND Deleted = 0 AND
		(@IsAdmin IS NULL OR IsAdmin = @IsAdmin) AND
		(@Status IS NULL OR Status = @Status)
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_IsNodeMember]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_IsNodeMember]
GO

CREATE PROCEDURE [dbo].[CN_IsNodeMember]
	@ApplicationID	uniqueidentifier,
    @NodeID			uniqueidentifier,
    @UserID			uniqueidentifier,
    @IsAdmin		bit,
    @Status			varchar(20)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @IsMember bit

    EXEC [dbo].[CN_P_IsNodeMember] @ApplicationID, @NodeID, @UserID, 
		@IsAdmin, @Status, @IsMember output
    
    SELECT @IsMember
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_IsNodeAdmin]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_IsNodeAdmin]
GO

CREATE PROCEDURE [dbo].[CN_P_IsNodeAdmin]
	@ApplicationID	uniqueidentifier,
    @NodeID			uniqueidentifier,
    @UserID			uniqueidentifier,
    @_IsAdmin		bit output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
    SELECT TOP(1) @_IsAdmin = IsAdmin
    FROM [dbo].[CN_NodeMembers]
    WHERE ApplicationID = @ApplicationID AND
		NodeID = @NodeID AND UserID = @UserID AND Deleted = 0
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_IsNodeAdmin]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_IsNodeAdmin]
GO

CREATE PROCEDURE [dbo].[CN_IsNodeAdmin]
	@ApplicationID	uniqueidentifier,
    @NodeID			uniqueidentifier,
    @UserID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @IsAdmin bit
	EXEC [dbo].[CN_P_IsNodeAdmin] @ApplicationID, @NodeID, @UserID, @IsAdmin output

    SELECT @IsAdmin
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_HasAdmin]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_HasAdmin]
GO

CREATE PROCEDURE [dbo].[CN_HasAdmin]
	@ApplicationID	uniqueidentifier,
    @NodeID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

    SELECT CAST(1 AS bit) 
    WHERE EXISTS(
			SELECT TOP(1) * 
			FROM [dbo].[CN_NodeMembers] AS NM
				INNER JOIN [dbo].[Users_Normal] AS UN
				ON UN.ApplicationID = @ApplicationID AND UN.UserID = NM.UserID
			WHERE NM.ApplicationID = @ApplicationID AND 
				NM.NodeID = @NodeID AND NM.IsAdmin = 1 AND 
				NM.[Status] <> N'Pending' AND NM.Deleted = 0 AND UN.IsApproved = 1
		)
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_SetUnsetNodeAdmin]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_SetUnsetNodeAdmin]
GO

CREATE PROCEDURE [dbo].[CN_SetUnsetNodeAdmin]
	@ApplicationID	uniqueidentifier,
    @NodeID			uniqueidentifier,
    @UserID			uniqueidentifier,
    @Admin			bit,
    @Unique			bit
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE @_Result int
	
	IF @Admin IS NULL SET @Admin = 0
	
	IF @Admin = 1 AND @Unique = 1 BEGIN
		DECLARE @Members GuidPairTableType
		
		INSERT INTO @Members (FirstValue, SecondValue)
		SELECT NM.NodeID, NM.UserID
		FROM [dbo].[CN_NodeMembers] AS NM
		WHERE NM.ApplicationID = @ApplicationID AND NM.NodeID = @NodeID AND NM.IsAdmin = 1
		
		EXEC [dbo].[CN_P_UpdateMembers] @ApplicationID, @Members, NULL, 0, 
			NULL, NULL, NULL, NULL, @_Result output
		
		IF @_Result <= 0 BEGIN
			SELECT @_Result
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	EXEC [dbo].[CN_P_UpdateMember] @ApplicationID, @NodeID, @UserID, NULL, 
		@Admin, NULL, NULL, NULL, NULL, @_Result output
	
	SELECT @_Result
	
	IF @_Result <= 0 BEGIN
		ROLLBACK TRANSACTION
		RETURN
	END
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_AddComplexAdmin]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_AddComplexAdmin]
GO

CREATE PROCEDURE [dbo].[CN_AddComplexAdmin]
	@ApplicationID	uniqueidentifier,
	@ListID			uniqueidentifier,
	@UserID			uniqueidentifier,
	@CurrentUserID	uniqueidentifier,
	@Now			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) * 
		FROM [dbo].[CN_ListAdmins]
		WHERE ApplicationID = @ApplicationID AND ListID = @ListID AND UserID = @UserID
	) BEGIN
		
		UPDATE [dbo].[CN_ListAdmins]
			SET LastModifierUserID = @CurrentUserID,
				LastModificationDate = @Now,
				Deleted = 0
		WHERE ApplicationID = @ApplicationID AND ListID = @ListID AND UserID = @UserID
	END
	ELSE BEGIN
		INSERT INTO [dbo].[CN_ListAdmins](
			ApplicationID,
			ListID,
			UserID,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES(
			@ApplicationID,
			@ListID,
			@UserID,
			@CurrentUserID,
			@Now,
			0
		)
	END
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_RemoveComplexAdmin]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_RemoveComplexAdmin]
GO

CREATE PROCEDURE [dbo].[CN_RemoveComplexAdmin]
	@ApplicationID		uniqueidentifier,
	@ListID				uniqueidentifier,
	@UserID				uniqueidentifier,
	@CurrentUserID		uniqueidentifier,
	@Now				datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[CN_ListAdmins]
		SET LastModifierUserID = @CurrentUserID,
			LastModificationDate = @Now,
			Deleted = 1
	WHERE ApplicationID = @ApplicationID AND ListID = @ListID AND UserID = @UserID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetComplexAdmins]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetComplexAdmins]
GO

CREATE PROCEDURE [dbo].[CN_GetComplexAdmins]
	@ApplicationID		uniqueidentifier,
	@ListIDOrNodeID		uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @IsList bit = (
		SELECT TOP(1) CAST(1 AS bit) 
		FROM [dbo].[CN_Lists] 
		WHERE ApplicationID = @ApplicationID AND ListID = @ListIDOrNodeID
	)
	
	IF @IsList = 1 BEGIN
		SELECT DISTINCT UserID AS ID
		FROM [dbo].[CN_View_ListAdmins]
		WHERE ApplicationID = @ApplicationID AND ListID = @ListIDOrNodeID
	END
	ELSE BEGIN
		SELECT DISTINCT UserID AS ID
		FROM [dbo].[CN_View_ListAdmins]
		WHERE ApplicationID = @ApplicationID AND NodeID = @ListIDOrNodeID
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetComplexTypeID]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetComplexTypeID]
GO

CREATE PROCEDURE [dbo].[CN_GetComplexTypeID]
	@ApplicationID	uniqueidentifier,
	@ListID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT NodeTypeID AS ID
	FROM [dbo].[CN_Lists]
	WHERE ApplicationID = @ApplicationID AND ListID = @ListID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_IsComplexAdmin]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_IsComplexAdmin]
GO

CREATE PROCEDURE [dbo].[CN_IsComplexAdmin]
	@ApplicationID	uniqueidentifier,
    @NodeID			uniqueidentifier,
    @UserID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT TOP(1) CAST(1 AS bit)
	FROM [dbo].[CN_View_ListAdmins]
	WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID AND UserID = @UserID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetUser2NodeStatus]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetUser2NodeStatus]
GO

CREATE PROCEDURE [dbo].[CN_GetUser2NodeStatus]
	@ApplicationID	uniqueidentifier,
	@UserID			uniqueidentifier,
    @NodeID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT TOP(1)
		ND.NodeTypeID AS NodeTypeID,
		ND.AreaID AS AreaID,
		CASE
			WHEN ND.CreatorUserID = @UserID THEN CAST(1 AS bit)
			ELSE CAST(0 AS bit)
		END AS IsCreator,
		CASE
			WHEN NC.UserID IS NULL THEN CAST(0 AS bit)
			ELSE CAST(1 AS bit)
		END AS IsContributor,
		CASE
			WHEN Ex.UserID IS NULL THEN CAST(0 AS bit)
			ELSE CAST(1 AS bit)
		END AS IsExpert,
		CASE
			WHEN NM.UserID IS NULL THEN CAST(0 AS bit)
			ELSE CAST(1 AS bit)
		END AS IsMember,
		CASE
			WHEN NM.UserID IS NULL OR ISNULL(NM.IsAdmin, 0) = 0 THEN CAST(0 AS bit)
			ELSE CAST(1 AS bit)
		END AS IsAdminMember,
		CASE
			WHEN SA.UserID IS NULL THEN CAST(0 AS bit)
			ELSE CAST(1 AS bit)
		END AS IsServiceAdmin
	FROM [dbo].[CN_Nodes] AS ND
		LEFT JOIN [dbo].[CN_NodeCreators] AS NC
		ON NC.ApplicationID = @ApplicationID AND 
			NC.NodeID = ND.NodeID AND NC.UserID = @UserID AND NC.Deleted = 0
		LEFT JOIN [dbo].[CN_View_Experts] AS Ex
		ON EX.ApplicationID = @ApplicationID AND 
			EX.UserID = @UserID AND EX.NodeID = ND.NodeID
		LEFT JOIN [dbo].[CN_View_NodeMembers] AS NM
		ON NM.ApplicationID = @ApplicationID AND 
			NM.UserID = @UserID AND NM.NodeID = ND.NodeID AND NM.IsPending = 0
		LEFT JOIN [dbo].[CN_ServiceAdmins] AS SA
		ON SA.ApplicationID = @ApplicationID AND 
			SA.NodeTypeID = ND.NodeTypeID AND SA.UserID = @UserID AND SA.Deleted = 0
	WHERE ND.ApplicationID = @ApplicationID AND ND.NodeID = @NodeID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_GetNodeHierarchyAdminIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_GetNodeHierarchyAdminIDs]
GO

CREATE PROCEDURE [dbo].[CN_P_GetNodeHierarchyAdminIDs]
	@ApplicationID	uniqueidentifier,
    @NodeID			uniqueidentifier,
    @SameType		bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @NodeTypeID uniqueidentifier = NULL
		
	IF @SameType = 1 BEGIN
		SET @NodeTypeID = (
			SELECT NodeTypeID 
			FROM [dbo].[CN_Nodes] 
			WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID
		)
	END

	DECLARE @NodeHierarchy NodesHierarchyTableType
	INSERT INTO @NodeHierarchy
    EXEC [dbo].[CN_P_GetNodeHierarchy] @ApplicationID, @NodeID, @SameType
    
    DECLARE @Admins GuidPairTableType
    INSERT INTO @Admins
    SELECT DISTINCT NM.NodeID, NM.UserID
    FROM @NodeHierarchy AS HRC
		INNER JOIN [dbo].[CN_NodeMembers] AS NM 
		ON NM.ApplicationID = @ApplicationID AND NM.NodeID = HRC.NodeID
		INNER JOIN [dbo].[Users_Normal] AS USR 
		ON USR.ApplicationID = @ApplicationID AND USR.UserID = NM.UserID
	WHERE NM.IsAdmin = 1 AND NM.Deleted = 0 AND USR.IsApproved = 1
    
    
    SELECT NH.NodeID AS NodeID, AD.SecondValue AS UserID, NH.[Level] AS [Level]
    FROM @NodeHierarchy AS NH
		INNER JOIN @Admins AS AD
		ON NH.NodeID = AD.FirstValue 
	ORDER BY NH.[Level] ASC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetNodeHierarchyAdminIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetNodeHierarchyAdminIDs]
GO

CREATE PROCEDURE [dbo].[CN_GetNodeHierarchyAdminIDs]
	@ApplicationID	uniqueidentifier,
    @NodeID			uniqueidentifier,
    @SameType		bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	EXEC [dbo].[CN_P_GetNodeHierarchyAdminIDs] @ApplicationID, @NodeID, @SameType
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_GetMembers]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_GetMembers]
GO

CREATE PROCEDURE [dbo].[CN_P_GetMembers]
	@ApplicationID	uniqueidentifier,
    @MembersTemp	GuidPairTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Members GuidPairTableType
	INSERT INTO @Members SELECT * FROM @MembersTemp

    SELECT NM.NodeID AS NodeID,
		   NM.UserID AS UserID,
		   NM.MembershipDate AS MembershipDate,
		   NM.IsAdmin AS IsAdmin,
		   CAST((CASE WHEN NM.[Status] = 'Pending' THEN 1 ELSE 0 END) AS bit) AS IsPending,
		   NM.[Status] AS [Status],
		   NM.AcceptionDate AS AcceptionDate,
		   NM.Position AS Position,
		   USR.UserName AS UserName,
		   USR.FirstName AS FirstName,
		   USR.LastName AS LastName,
		   USR.AvatarName,
		   USR.UseAvatar
    FROM @Members AS ExternalIDs
		INNER JOIN [dbo].[CN_NodeMembers] AS NM 
		ON NM.ApplicationID = @ApplicationID AND 
			NM.NodeID = ExternalIDs.FirstValue AND NM.UserID = ExternalIDs.SecondValue
		INNER JOIN [dbo].[Users_Normal] AS USR 
		ON USR.ApplicationID = @ApplicationID AND USR.UserID = NM.UserID
	ORDER BY USR.LastActivityDate DESC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetMembers]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetMembers]
GO

CREATE PROCEDURE [dbo].[CN_GetMembers]
	@ApplicationID	uniqueidentifier,
    @strNodeIDs		varchar(max),
    @delimiter		char,
    @IsPending		bit,
    @IsAdmin		bit,
    @SearchText		nvarchar(255),
    @Count			int,
    @LowerBoundary	bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeIDs GuidTableType
	
	INSERT INTO @NodeIDs
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strNodeIDs, @delimiter) AS Ref

	DECLARE @Members GuidPairTableType
	
	DECLARE @MMS Table (NodeID uniqueidentifier, UserID uniqueidentifier, TotalCount bigint)
	
	IF ISNULL(@Count, 0) <= 0 SET @Count = 1000000
	
	IF @IsPending = 1 SET @IsAdmin = NULL
	
	IF ISNULL(@SearchText, N'') = N'' BEGIN
		INSERT INTO @MMS (NodeID, UserID, TotalCount)
		SELECT TOP(@Count) 
			Ref.NodeID, 
			Ref.UserID, 
			(Ref.RowNumber + Ref.RevRowNumber - 1)
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY NM.IsAdmin DESC, NM.NodeID DESC, NM.UserID DESC) AS RowNumber,
						ROW_NUMBER() OVER (ORDER BY NM.IsAdmin ASC, NM.NodeID ASC, NM.UserID ASC) AS RevRowNumber,
						NM.NodeID AS NodeID,
						NM.UserID AS UserID
				FROM @NodeIDs AS Ref
					INNER JOIN [dbo].[CN_View_NodeMembers] AS NM 
					ON NM.NodeID = Ref.Value
				WHERE NM.ApplicationID = @ApplicationID AND 
					(@IsPending IS NULL OR NM.IsPending = @IsPending) AND
					(@IsAdmin IS NULL OR NM.IsAdmin = @IsAdmin)
			) AS Ref
		WHERE Ref.RowNumber >= ISNULL(@LowerBoundary, 0)
		ORDER BY Ref.RowNumber ASC
	END
	ELSE BEGIN
		INSERT INTO @MMS (NodeID, UserID, TotalCount)
		SELECT TOP(@Count) 
			Ref.NodeID, 
			Ref.UserID, 
			(Ref.RowNumber + Ref.RevRowNumber - 1)
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY SRCH.[Rank] DESC, NM.NodeID DESC, NM.UserID DESC) AS RowNumber,
						ROW_NUMBER() OVER (ORDER BY SRCH.[Rank] ASC, NM.NodeID ASC, NM.UserID ASC) AS RevRowNumber,
						NM.NodeID AS NodeID,
						NM.UserID AS UserID
				FROM @NodeIDs AS Ref
					INNER JOIN [dbo].[CN_View_NodeMembers] AS NM 
					ON NM.NodeID = Ref.Value
					INNER JOIN CONTAINSTABLE([dbo].[USR_View_Users], ([UserName], [FirstName], [LastName]), @SearchText) AS SRCH
					ON SRCH.[Key] = NM.UserID
				WHERE NM.ApplicationID = @ApplicationID AND 
					(@IsPending IS NULL OR NM.IsPending = @IsPending) AND
					(@IsAdmin IS NULL OR NM.IsAdmin = @IsAdmin)
			) AS Ref
		WHERE Ref.RowNumber >= ISNULL(@LowerBoundary, 0)
		ORDER BY Ref.RowNumber ASC
	END
	
	INSERT INTO @Members (FirstValue, SecondValue)
	SELECT M.NodeID, M.UserID
	FROM @MMS AS M
		
	EXEC [dbo].[CN_P_GetMembers] @ApplicationID, @Members
	
	SELECT TOP(1) M.TotalCount
	FROM @MMS AS M
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetMember]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetMember]
GO

CREATE PROCEDURE [dbo].[CN_GetMember]
	@ApplicationID	uniqueidentifier,
    @NodeID			uniqueidentifier,
    @UserID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @Members GuidPairTableType

	INSERT INTO @Members (FirstValue, SecondValue)
    SELECT NM.NodeID, NM.UserID
    FROM [dbo].[CN_NodeMembers] AS NM
    WHERE NM.ApplicationID = @ApplicationID AND 
		NM.NodeID = @NodeID AND NM.UserID = @UserID AND NM.Deleted = 0
		
	EXEC [dbo].[CN_P_GetMembers] @ApplicationID, @Members
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_GetMemberUserIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_GetMemberUserIDs]
GO

CREATE PROCEDURE [dbo].[CN_P_GetMemberUserIDs]
	@ApplicationID	uniqueidentifier,
    @NodeIDsTemp	GuidTableType readonly,
    @Status			varchar(20),
    @IsAdmin		bit
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeIDs GuidTableType
	INSERT INTO @NodeIDs SELECT * FROM @NodeIDsTemp

	SELECT DISTINCT NM.UserID AS ID
    FROM @NodeIDs AS ExternalIDs
		INNER JOIN [dbo].[CN_NodeMembers] AS NM 
		ON NM.ApplicationID = @ApplicationID AND NM.NodeID = ExternalIDs.Value
		INNER JOIN [dbo].[Users_Normal] AS USR 
		ON USR.ApplicationID = @ApplicationID AND 
			USR.UserID = NM.UserID AND USR.IsApproved = 1
	WHERE (@Status IS NULL OR NM.[Status] = @Status) AND
		(@IsAdmin IS NULL OR NM.IsAdmin = @IsAdmin) AND NM.Deleted = 0
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetMemberUserIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetMemberUserIDs]
GO

CREATE PROCEDURE [dbo].[CN_GetMemberUserIDs]
	@ApplicationID	uniqueidentifier,
    @strNodeIDs		varchar(max),
    @delimiter		char,
    @Status			varchar(20),
    @IsAdmin		bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeIDs GuidTableType
	INSERT INTO @NodeIDs
	SELECT DISTINCT Ref.Value FROM GFN_StrToGuidTable(@strNodeIDs, @delimiter) AS Ref

	EXEC [dbo].[CN_P_GetMemberUserIDs] @ApplicationID, @NodeIDs, @Status, @IsAdmin
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetMembersCount]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetMembersCount]
GO

CREATE PROCEDURE [dbo].[CN_GetMembersCount]
	@ApplicationID	uniqueidentifier,
    @NodeID			uniqueidentifier,
    @Status			varchar(20),
    @IsAdmin		bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

    SELECT COUNT(*)
    FROM [dbo].[CN_NodeMembers] AS NM 
		INNER JOIN [dbo].[Users_Normal] AS USR 
		ON USR.ApplicationID = @ApplicationID AND 
			USR.UserID = NM.UserID AND USR.IsApproved = 1
	WHERE NM.ApplicationID = @ApplicationID AND 
		NM.NodeID = @NodeID AND (@Status IS NULL OR NM.[Status] = @Status) AND
		(@IsAdmin IS NULL OR NM.IsAdmin = @IsAdmin) AND NM.Deleted = 0
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetHierarchyMemberIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetHierarchyMemberIDs]
GO

CREATE PROCEDURE [dbo].[CN_GetHierarchyMemberIDs]
	@ApplicationID		uniqueidentifier,
    @NodeID				uniqueidentifier,
	@ParentHierarchy	bit,
    @SearchText			nvarchar(255),
    @Count				int,
    @LowerBoundary		bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @IDs GuidTableType
	
	INSERT INTO @IDs
	SELECT @NodeID
	
	DECLARE @NodeIDs GuidTableType
	
	IF @ParentHierarchy = 1 BEGIN
		INSERT INTO @NodeIDs (Value)
		SELECT DISTINCT Ref.NodeID
		FROM [dbo].[CN_FN_GetNodesHierarchy](@ApplicationID, @IDs) AS Ref
	END
	ELSE BEGIN
		INSERT INTO @NodeIDs (Value)
		SELECT DISTINCT Ref.NodeID
		FROM [dbo].[CN_FN_GetChildNodesDeepHierarchy](@ApplicationID, @IDs) AS Ref
	END

	DECLARE @Members GuidPairTableType
	
	DECLARE @US Table (UserID uniqueidentifier, TotalCount bigint)
	
	IF ISNULL(@Count, 0) <= 0 SET @Count = 1000000
	
	IF ISNULL(@SearchText, N'') = N'' BEGIN
		INSERT INTO @US (UserID, TotalCount)
		SELECT TOP(@Count) 
			Ref.UserID, 
			(Ref.RowNumber + Ref.RevRowNumber - 1)
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY U.UserID ASC) AS RowNumber,
						ROW_NUMBER() OVER (ORDER BY U.UserID DESC) AS RevRowNumber,
						U.UserID AS UserID
				FROM (
						SELECT DISTINCT NM.UserID
						FROM @NodeIDs AS Ref
							INNER JOIN [dbo].[CN_View_NodeMembers] AS NM 
							ON NM.NodeID = Ref.Value
						WHERE NM.ApplicationID = @ApplicationID AND NM.IsPending = 0
					) AS U
					INNER JOIN [dbo].[Users_Normal] AS UN
					ON UN.ApplicationID = @ApplicationID AND
						UN.UserID = U.UserID AND UN.IsApproved = 1
			) AS Ref
		WHERE Ref.RowNumber >= ISNULL(@LowerBoundary, 0)
		ORDER BY Ref.RowNumber ASC
	END
	ELSE BEGIN
		INSERT INTO @US (UserID, TotalCount)
		SELECT TOP(@Count) 
			Ref.UserID, 
			(Ref.RowNumber + Ref.RevRowNumber - 1)
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY SRCH.[Rank] DESC, U.UserID ASC) AS RowNumber,
						ROW_NUMBER() OVER (ORDER BY SRCH.[Rank] ASC, U.UserID DESC) AS RevRowNumber,
						U.UserID AS UserID
				FROM (
						SELECT DISTINCT NM.UserID
						FROM @NodeIDs AS Ref
							INNER JOIN [dbo].[CN_View_NodeMembers] AS NM 
							ON NM.NodeID = Ref.Value
						WHERE NM.ApplicationID = @ApplicationID AND NM.IsPending = 0
					) AS U
					INNER JOIN [dbo].[Users_Normal] AS UN
					ON UN.ApplicationID = @ApplicationID AND
						UN.UserID = U.UserID AND UN.IsApproved = 1
					INNER JOIN CONTAINSTABLE([dbo].[USR_View_Users], ([UserName], [FirstName], [LastName]), @SearchText) AS SRCH
					ON SRCH.[Key] = UN.UserID
			) AS Ref
		WHERE Ref.RowNumber >= ISNULL(@LowerBoundary, 0)
		ORDER BY Ref.RowNumber ASC
	END
	
	SELECT U.UserID AS ID
	FROM @US AS U
	
	SELECT TOP(1) U.TotalCount
	FROM @US AS U
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetHierarchyExpertIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetHierarchyExpertIDs]
GO

CREATE PROCEDURE [dbo].[CN_GetHierarchyExpertIDs]
	@ApplicationID		uniqueidentifier,
    @NodeID				uniqueidentifier,
	@ParentHierarchy	bit,
    @SearchText			nvarchar(255),
    @Count				int,
    @LowerBoundary		bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @IDs GuidTableType
	
	INSERT INTO @IDs
	SELECT @NodeID
	
	DECLARE @NodeIDs GuidTableType
	
	IF @ParentHierarchy = 1 BEGIN
		INSERT INTO @NodeIDs (Value)
		SELECT DISTINCT Ref.NodeID
		FROM [dbo].[CN_FN_GetNodesHierarchy](@ApplicationID, @IDs) AS Ref
	END
	ELSE BEGIN
		INSERT INTO @NodeIDs (Value)
		SELECT DISTINCT Ref.NodeID
		FROM [dbo].[CN_FN_GetChildNodesDeepHierarchy](@ApplicationID, @IDs) AS Ref
	END

	DECLARE @Members GuidPairTableType
	
	DECLARE @US Table (UserID uniqueidentifier, TotalCount bigint)
	
	IF ISNULL(@Count, 0) <= 0 SET @Count = 1000000
	
	IF ISNULL(@SearchText, N'') = N'' BEGIN
		INSERT INTO @US (UserID, TotalCount)
		SELECT TOP(@Count) 
			Ref.UserID, 
			(Ref.RowNumber + Ref.RevRowNumber - 1)
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY U.UserID ASC) AS RowNumber,
						ROW_NUMBER() OVER (ORDER BY U.UserID DESC) AS RevRowNumber,
						U.UserID AS UserID
				FROM (
						SELECT DISTINCT Ex.UserID
						FROM @NodeIDs AS Ref
							INNER JOIN [dbo].[CN_View_Experts] AS Ex
							ON Ex.NodeID = Ref.Value
						WHERE Ex.ApplicationID = @ApplicationID
					) AS U
					INNER JOIN [dbo].[Users_Normal] AS UN
					ON UN.ApplicationID = @ApplicationID AND
						UN.UserID = U.UserID AND UN.IsApproved = 1
			) AS Ref
		WHERE Ref.RowNumber >= ISNULL(@LowerBoundary, 0)
		ORDER BY Ref.RowNumber ASC
	END
	ELSE BEGIN
		INSERT INTO @US (UserID, TotalCount)
		SELECT TOP(@Count) 
			Ref.UserID, 
			(Ref.RowNumber + Ref.RevRowNumber - 1)
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY SRCH.[Rank] DESC, U.UserID ASC) AS RowNumber,
						ROW_NUMBER() OVER (ORDER BY SRCH.[Rank] ASC, U.UserID DESC) AS RevRowNumber,
						U.UserID AS UserID
				FROM (
						SELECT DISTINCT Ex.UserID
						FROM @NodeIDs AS Ref
							INNER JOIN [dbo].[CN_View_Experts] AS Ex
							ON Ex.NodeID = Ref.Value
						WHERE Ex.ApplicationID = @ApplicationID
					) AS U
					INNER JOIN [dbo].[Users_Normal] AS UN
					ON UN.ApplicationID = @ApplicationID AND
						UN.UserID = U.UserID AND UN.IsApproved = 1
					INNER JOIN CONTAINSTABLE([dbo].[USR_View_Users], ([UserName], [FirstName], [LastName]), @SearchText) AS SRCH
					ON SRCH.[Key] = UN.UserID
			) AS Ref
		WHERE Ref.RowNumber >= ISNULL(@LowerBoundary, 0)
		ORDER BY Ref.RowNumber ASC
	END
	
	SELECT U.UserID AS ID
	FROM @US AS U
	
	SELECT TOP(1) U.TotalCount
	FROM @US AS U
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetUserManagedNodeIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetUserManagedNodeIDs]
GO

CREATE PROCEDURE [dbo].[CN_GetUserManagedNodeIDs]
	@ApplicationID	uniqueidentifier,
    @UserID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

    SELECT NodeID 
    FROM [dbo].[CN_NodeMembers]
    WHERE ApplicationID = @ApplicationID AND UserID = @UserID AND IsAdmin = 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetMembershipRequestsDashboards]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetMembershipRequestsDashboards]
GO

CREATE PROCEDURE [dbo].[CN_GetMembershipRequestsDashboards]
	@ApplicationID	uniqueidentifier,
    @UserID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @NodeIDs GuidTableType
	INSERT INTO @NodeIDs
	EXEC [dbo].[CN_GetUserManagedNodeIDs] @ApplicationID, @UserID

    SELECT NM.NodeID AS NodeID,
		   NM.UserID AS UserID,
		   NM.MembershipDate AS MembershipDate,
		   NM.IsAdmin AS IsAdmin,
		   NM.[Status] AS [Status],
		   NM.AcceptionDate AS AcceptionDate,
		   NM.Position AS Position,
		   USR.UserName AS UserName,
		   USR.FirstName AS FirstName,
		   USR.LastName AS LastName,
		   VN.NodeAdditionalID AS NodeAdditionalID,
		   VN.NodeName AS NodeName,
		   VN.NodeTypeID AS NodeTypeID,
		   VN.TypeName AS NodeType
    FROM @NodeIDs AS ExternalIDs 
		INNER JOIN [dbo].[CN_NodeMembers] AS NM 
		ON NM.ApplicationID = @ApplicationID AND NM.NodeID = ExternalIDs.Value
		INNER JOIN [dbo].[Users_Normal] AS USR 
		ON USR.ApplicationID = @ApplicationID AND USR.UserID = NM.UserID
		INNER JOIN [dbo].[CN_View_Nodes_Normal] AS VN 
		ON VN.ApplicationID = @ApplicationID AND VN.NodeID = NM.NodeID
	WHERE NM.[Status] = N'Pending' AND NM.Deleted = 0 AND 
		USR.IsApproved = 1 AND VN.Deleted = 0
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetMembershipRequestsDashboardsCount]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetMembershipRequestsDashboardsCount]
GO

CREATE PROCEDURE [dbo].[CN_GetMembershipRequestsDashboardsCount]
	@ApplicationID	uniqueidentifier,
    @UserID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @NodeIDs GuidTableType
	INSERT INTO @NodeIDs
	EXEC [dbo].[CN_GetUserManagedNodeIDs] @ApplicationID, @UserID

    SELECT COUNT(NM.NodeID)
    FROM @NodeIDs AS ExternalIDs 
		INNER JOIN [dbo].[CN_NodeMembers] AS NM 
		ON NM.ApplicationID = @ApplicationID AND NM.NodeID = ExternalIDs.Value
		INNER JOIN [dbo].[Users_Normal] AS USR 
		ON USR.ApplicationID = @ApplicationID AND USR.UserID = NM.UserID
		INNER JOIN [dbo].[CN_View_Nodes_Normal] AS VN 
		ON VN.ApplicationID = @ApplicationID AND VN.NodeID = NM.NodeID
	WHERE NM.[Status] = N'Pending' AND NM.Deleted = 0 AND 
		USR.IsApproved = 1 AND VN.Deleted = 0
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetMembershipDomainsCount]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetMembershipDomainsCount]
GO

CREATE PROCEDURE [dbo].[CN_GetMembershipDomainsCount]
	@ApplicationID	uniqueidentifier,
	@UserID			uniqueidentifier,
	@NodeTypeID		uniqueidentifier,
	@NodeID			uniqueidentifier,
	@AdditionalID	varchar(50),
	@LowerDateLimit	datetime,
	@UpperDateLimit	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF @NodeID IS NOT NULL SET @NodeTypeID = NULL
	IF @NodeID IS NOT NULL OR @AdditionalID = N'' SET @AdditionalID = NULL
	
	SELECT	ND.NodeTypeID, 
			MAX(ND.TypeAdditionalID) AS NodeTypeAdditionalID,
			MAX(ND.TypeName) AS TypeName, 
			COUNT(ND.NodeID) AS NodesCount
	FROM [dbo].[CN_View_NodeMembers] AS NM
		INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.NodeID = NM.NodeID
	WHERE NM.ApplicationID = @ApplicationID AND NM.UserID = @UserID AND 
		NM.IsPending = 0 AND (@NodeID IS NULL OR ND.NodeID = @NodeID) AND
		(@NodeTypeID IS NULL OR ND.NodeTypeID = @NodeTypeID) AND 
		(@AdditionalID IS NULL OR ND.NodeAdditionalID = @AdditionalID) AND
		(@LowerDateLimit IS NULL OR ND.CreationDate>= @LowerDateLimit) AND
		(@UpperDateLimit IS NULL OR ND.CreationDate <= @UpperDateLimit) AND
		ND.Deleted = 0
	GROUP BY ND.NodeTypeID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetMembershipDomains]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetMembershipDomains]
GO

CREATE PROCEDURE [dbo].[CN_GetMembershipDomains]
	@ApplicationID	uniqueidentifier,
	@UserID			uniqueidentifier,
	@strNodeTypeIDs	varchar(max),
	@delimiter		char,
	@NodeID			uniqueidentifier,
	@AdditionalID	varchar(50),
	@SearchText		nvarchar(1000),
	@LowerDateLimit	datetime,
	@UpperDateLimit	datetime,
	@LowerBoundary	int,
	@Count			int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeTypeIDs GuidTableType
	
	INSERT INTO @NodeTypeIDs (Value)
	SELECT DISTINCT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strNodeTypeIDs, @delimiter) AS Ref
	
	DECLARE @NTCount int = (SELECT COUNT(*) FROM @NodeTypeIDs)
	
	IF @NodeID IS NOT NULL SET @NTCount = 0
	IF @NodeID IS NOT NULL OR @AdditionalID = N'' SET @AdditionalID = NULL
	IF @Count IS NULL OR @Count <= 0 SET @Count = 10
	
	SET @SearchText = [dbo].[GFN_VerifyString](@SearchText)
	IF @SearchText IS NULL OR @SearchText = N'' SET @SearchText = NULL
	
	DECLARE @SelectedIDs KeyLessGuidTableType
	
	IF @SearchText IS NULL BEGIN
		INSERT INTO @SelectedIDs (Value)
		SELECT Ref.NodeID
		FROM (
				SELECT ROW_NUMBER() OVER (ORDER BY ND.CreationDate DESC, ND.NodeID DESC) AS RowNumber, ND.NodeID
				FROM [dbo].[CN_View_NodeMembers] AS NM
					INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
					ON ND.ApplicationID = @ApplicationID AND ND.NodeID = NM.NodeID
				WHERE NM.ApplicationID = @ApplicationID AND NM.UserID = @UserID AND 
					NM.IsPending = 0 AND (@NodeID IS NULL OR ND.NodeID = @NodeID) AND
					(@NTCount = 0 OR ND.NodeTypeID IN (SELECT NTIDs.Value FROM @NodeTypeIDs AS NTIDs)) AND 
					(@AdditionalID IS NULL OR ND.NodeAdditionalID = @AdditionalID) AND
					(@LowerDateLimit IS NULL OR ND.CreationDate>= @LowerDateLimit) AND
					(@UpperDateLimit IS NULL OR ND.CreationDate <= @UpperDateLimit) AND
					ND.Deleted = 0
			) AS Ref
		ORDER BY Ref.RowNumber ASC
	END
	ELSE BEGIN
		INSERT INTO @SelectedIDs (Value)
		SELECT Ref.NodeID
		FROM (
				SELECT ROW_NUMBER() OVER (ORDER BY SRCH.[Rank] DESC, SRCH.[Key] DESC) AS RowNumber, ND.NodeID
				FROM CONTAINSTABLE([dbo].[CN_Nodes], ([Name], [AdditionalID]), @SearchText) AS SRCH
					INNER JOIN [dbo].[CN_View_NodeMembers] AS NM
					INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
					ON ND.ApplicationID = @ApplicationID AND ND.NodeID = NM.NodeID
					ON ND.NodeID = SRCH.[Key]
				WHERE ND.ApplicationID = @ApplicationID AND NM.UserID = @UserID AND 
					NM.IsPending = 0 AND (@NodeID IS NULL OR ND.NodeID = @NodeID) AND
					(@NTCount = 0 OR ND.NodeTypeID IN (SELECT NTIDs.Value FROM @NodeTypeIDs AS NTIDs)) AND 
					(@AdditionalID IS NULL OR ND.NodeAdditionalID = @AdditionalID) AND
					(@LowerDateLimit IS NULL OR ND.CreationDate>= @LowerDateLimit) AND
					(@UpperDateLimit IS NULL OR ND.CreationDate <= @UpperDateLimit) AND
					ND.Deleted = 0
			) AS Ref
		ORDER BY Ref.RowNumber ASC
	END
	
	DECLARE @NodeIDs KeyLessGuidTableType

	INSERT INTO @NodeIDs (Value)
	SELECT TOP(@Count) S.Value 
	FROM @SelectedIDs AS S
	WHERE S.SequenceNumber >= ISNULL(@LowerBoundary, 0)
	
	EXEC [dbo].[CN_P_GetNodesByIDs] @ApplicationID, @NodeIDs, 0, NULL
	
	SELECT TOP(1) COUNT(S.Value) AS TotalCount FROM @SelectedIDs AS S
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_GetMemberNodes]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_GetMemberNodes]
GO

CREATE PROCEDURE [dbo].[CN_P_GetMemberNodes]
	@ApplicationID		uniqueidentifier,
    @NodeUserIDsTemp	GuidPairTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeUserIDs GuidPairTableType
	INSERT INTO @NodeUserIDs SELECT * FROM @NodeUserIDsTemp

    SELECT NM.NodeID AS NodeID,
		   NM.UserID AS UserID,
		   NM.MembershipDate AS MembershipDate,
		   NM.IsAdmin AS IsAdmin,
		   CAST((CASE WHEN NM.[Status] = 'Pending' THEN 1 ELSE 0 END) AS bit) AS IsPending,
		   NM.[Status] AS [Status],
		   NM.AcceptionDate AS AcceptionDate,
		   NM.Position AS Position,
		   VN.NodeAdditionalID AS NodeAdditionalID,
		   VN.NodeName AS NodeName,
		   VN.NodeTypeID AS NodeTypeID,
		   VN.TypeName AS NodeType,
		   VN.AvatarName,
		   VN.UseAvatar
    FROM @NodeUserIDs AS ExternalIDs
		INNER JOIN [dbo].[CN_NodeMembers] AS NM 
		ON NM.ApplicationID = @ApplicationID AND
			NM.NodeID = ExternalIDs.FirstValue AND NM.UserID = ExternalIDs.SecondValue
		INNER JOIN [dbo].[CN_View_Nodes_Normal] AS VN 
		ON VN.ApplicationID = @ApplicationID AND VN.NodeID = NM.NodeID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetMemberNodes]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetMemberNodes]
GO

CREATE PROCEDURE [dbo].[CN_GetMemberNodes]
	@ApplicationID			uniqueidentifier,
    @strUserIDs				varchar(max),
    @strNodeTypeIDs			varchar(max),
    @delimiter				char,
    @NodeTypeAdditionalID	varchar(20),
    @IsAdmin				bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeTypeIDs GuidTableType, @UserIDs GuidTableType
	DECLARE @NTCount int
	
	INSERT INTO @UserIDs
	SELECT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strUserIDs, @delimiter) AS Ref
	
	INSERT INTO @NodeTypeIDs
	SELECT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strNodeTypeIDs, @delimiter) AS Ref
	
	DECLARE @AddID uniqueidentifier = [dbo].[CN_FN_GetNodeTypeID](@ApplicationID, @NodeTypeAdditionalID)
	IF @AddID IS NOT NULL BEGIN
		INSERT INTO @NodeTypeIDs(Value)
		VALUES(@AddID)
	END
	
	SET @NTCount = (SELECT COUNT(*) FROM @NodeTypeIDs)
	
	DECLARE @NodeUserIDs GuidPairTableType

	INSERT INTO @NodeUserIDs (FirstValue, SecondValue)
    SELECT NM.NodeID, NM.UserID
    FROM @UserIDs AS U
		INNER JOIN [dbo].[CN_View_NodeMembers] AS NM 
		ON NM.ApplicationID = @ApplicationID AND NM.UserID = U.Value
	WHERE (@NTCount = 0 OR NM.NodeTypeID IN(SELECT * FROM @NodeTypeIDs)) AND
		(@IsAdmin IS NULL OR NM.IsAdmin = @IsAdmin) AND NM.IsPending = 0
		
	EXEC [dbo].[CN_P_GetMemberNodes] @ApplicationID, @NodeUserIDs
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_GetMemberNodeIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_GetMemberNodeIDs]
GO

CREATE PROCEDURE [dbo].[CN_P_GetMemberNodeIDs]
	@ApplicationID			uniqueidentifier,
    @UserID					uniqueidentifier,
    @NodeTypeAdditionalID	varchar(20),
    @Status					varchar(20),
    @IsAdmin				bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

    SELECT NM.NodeID AS ID
    FROM [dbo].[CN_NodeMembers] AS NM 
		INNER JOIN [dbo].[CN_View_Nodes_Normal] AS VN 
		ON VN.ApplicationID = @ApplicationID AND VN.NodeID = NM.NodeID AND 
			(@NodeTypeAdditionalID IS NULL OR VN.TypeAdditionalID = @NodeTypeAdditionalID) AND 
			VN.Deleted = 0
	WHERE NM.ApplicationID = @ApplicationID AND NM.UserID = @UserID AND 
		(@Status IS NULL OR NM.[Status] = @Status) AND
		(@IsAdmin IS NULL OR NM.IsAdmin = @IsAdmin) AND NM.Deleted = 0
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetNodeTypeMembers]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetNodeTypeMembers]
GO

CREATE PROCEDURE [dbo].[CN_GetNodeTypeMembers]
	@ApplicationID	uniqueidentifier,
    @NodeTypeID		uniqueidentifier,
    @Count			int,
    @LowerBoundary	bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

    ;WITH AllNodeMembers AS (
		SELECT	ROW_NUMBER() OVER (ORDER BY NM.NodeID ASC, NM.UserID ASC) AS Seq,
				NM.NodeID, 
				NM.UserID, 
				NM.IsAdmin,
				UN.UserName
		FROM [dbo].[CN_View_NodeMembers] AS NM
			INNER JOIN [dbo].[Users_Normal] AS UN
			ON UN.UserID = NM.UserID AND UN.IsApproved = 1
		WHERE NM.ApplicationID = @ApplicationID AND 
			NM.NodeTypeID = @NodeTypeID AND NM.IsPending = 0
	),
	Total AS (
		SELECT COUNT(A.Seq) AS TotalCount
		FROM AllNodeMembers AS A
	)
	SELECT TOP(ISNULL(@Count, 1000))
		A.NodeID,
		ND.AdditionalID AS NodeAdditionalID,
		A.UserID,
		A.UserName,
		A.IsAdmin,
		T.TotalCount
	FROM AllNodeMembers AS A
		CROSS JOIN Total AS T
		INNER JOIN [dbo].[CN_Nodes] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.NodeID = A.NodeID
	WHERE A.Seq >= ISNULL(@LowerBoundary, 0)
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetUsersDepartments]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetUsersDepartments]
GO

CREATE PROCEDURE [dbo].[CN_GetUsersDepartments]
	@ApplicationID	uniqueidentifier,
    @strUserIDs		varchar(max),
    @delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserIDs GuidTableType
	INSERT INTO @UserIDs
	SELECT DISTINCT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strUserIDs, @delimiter) AS Ref
	
	DECLARE @DepTypeIDs GuidTableType
	INSERT INTO @DepTypeIDs (Value)
	SELECT Ref.NodeTypeID
	FROM [dbo].[CN_FN_GetDepartmentNodeTypeIDs](@ApplicationID) AS Ref
	
	DECLARE @NodeUserIDs GuidPairTableType

	INSERT INTO @NodeUserIDs (FirstValue, SecondValue)
    SELECT NM.NodeID, NM.UserID
    FROM @UserIDs AS ExternalIDs
		INNER JOIN [dbo].[CN_NodeMembers] AS NM 
		ON NM.ApplicationID = @ApplicationID AND NM.UserID = ExternalIDs.Value
		INNER JOIN [dbo].[CN_View_Nodes_Normal] AS VN 
		ON VN.ApplicationID = @ApplicationID AND VN.NodeID = NM.NodeID
	WHERE VN.NodeTypeID IN (SELECT Value FROM @DepTypeIDs) AND 
		NM.Deleted = 0 AND VN.Deleted = 0
		
	EXEC [dbo].[CN_P_GetMemberNodes] @ApplicationID, @NodeUserIDs
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_LikeNodes]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_LikeNodes]
GO

CREATE PROCEDURE [dbo].[CN_LikeNodes]
	@ApplicationID	uniqueidentifier,
	@strNodeIDs		varchar(max),
	@delimiter		char,
    @UserID			uniqueidentifier,
    @LikeDate		datetime
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON

	DECLARE @NodeIDs GuidTableType
	INSERT INTO @NodeIDs
	SELECT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strNodeIDs, @delimiter) AS Ref
	
	DECLARE @Existing GuidTableType
	INSERT INTO @Existing
	SELECT Ref.Value
	FROM @NodeIDs AS Ref
		INNER JOIN [dbo].[CN_NodeLikes] AS NL
		ON NL.ApplicationID = @ApplicationID AND NL.NodeID = Ref.Value
	WHERE NL.UserID = @UserID
	
	DECLARE @NotExisting GuidTableType
	INSERT INTO @NotExisting
	SELECT Ref.Value
	FROM @NodeIDs AS Ref
	WHERE Ref.Value NOT IN (SELECT * FROM @Existing)
	
	IF EXISTS(SELECT TOP(1) * FROM @Existing) BEGIN
		UPDATE NL
			SET LikeDate = @LikeDate,
				Deleted = 0
		FROM @Existing AS Ref
			INNER JOIN [dbo].[CN_NodeLikes] AS NL
			ON NL.ApplicationID = @ApplicationID AND NL.[NodeID] = Ref.Value
		WHERE NL.[UserID] = @UserID
		
		IF @@ROWCOUNT <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	IF EXISTS(SELECT TOP(1) * FROM @NotExisting) BEGIN
		INSERT INTO [dbo].[CN_NodeLikes](
			ApplicationID,
			NodeID,
			UserID,
			LikeDate,
			Deleted,
			UniqueID
		)
		SELECT @ApplicationID, Ref.Value, @UserID, @LikeDate, 0, NEWID()
		FROM @NotExisting AS Ref
		
		IF @@ROWCOUNT <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END

	SELECT 1
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_UnlikeNodes]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_UnlikeNodes]
GO

CREATE PROCEDURE [dbo].[CN_UnlikeNodes]
	@ApplicationID	uniqueidentifier,
    @strNodeIDs		varchar(max),
    @delimiter		char,
    @UserID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeIDs GuidTableType
	INSERT INTO @NodeIDs
	SELECT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strNodeIDs, @delimiter) AS Ref

	UPDATE NL
		SET Deleted = 1
	FROM @NodeIDs AS Ref
		INNER JOIN [dbo].[CN_NodeLikes] AS NL
		ON NL.ApplicationID = @ApplicationID AND NL.[NodeID] = Ref.Value
	WHERE NL.[UserID] = @UserID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_IsFan]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_IsFan]
GO

CREATE PROCEDURE [dbo].[CN_IsFan]
	@ApplicationID	uniqueidentifier,
    @strNodeIDs		varchar(max),
    @delimiter		char,
    @UserID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeIDs GuidTableType
	INSERT INTO @NodeIDs
	SELECT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strNodeIDs, @delimiter) AS Ref

	SELECT Ref.Value AS ID
	FROM @NodeIDs AS Ref
		INNER JOIN [dbo].[CN_NodeLikes] AS NL
		ON NL.ApplicationID = @ApplicationID AND NL.NodeID = Ref.Value
	WHERE NL.UserID = @UserID AND NL.Deleted = 0
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetNodeFansUserIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetNodeFansUserIDs]
GO

CREATE PROCEDURE [dbo].[CN_GetNodeFansUserIDs]
	@ApplicationID	uniqueidentifier,
    @NodeID			uniqueidentifier,
    @Count			int,
    @LowerBoundary	bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF ISNULL(@Count, 0) <= 0 SET @Count = 1000000
	
	SELECT TOP(@Count)
		Ref.RowNumber AS [Order],
		(Ref.RowNumber + Ref.RevRowNumber - 1) AS TotalCount,
		Ref.UserID AS UserID
	FROM (
			SELECT	ROW_NUMBER() OVER (ORDER BY NL.LikeDate DESC, NL.UserID DESC) AS RowNumber,
					ROW_NUMBER() OVER (ORDER BY NL.LikeDate ASC, NL.UserID ASC) AS RevRowNumber,
					NL.UserID
			FROM [dbo].[CN_NodeLikes] AS NL
			WHERE NL.ApplicationID = @ApplicationID AND NL.NodeID = @NodeID AND NL.Deleted = 0
		) AS Ref
	WHERE Ref.RowNumber >= ISNULL(@LowerBoundary, 0)
	ORDER BY Ref.RowNumber ASC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetFavoriteNodesCount]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetFavoriteNodesCount]
GO

CREATE PROCEDURE [dbo].[CN_GetFavoriteNodesCount]
	@ApplicationID	uniqueidentifier,
	@UserID			uniqueidentifier,
	@NodeTypeID		uniqueidentifier,
	@NodeID			uniqueidentifier,
	@AdditionalID	varchar(50),
	@IsDocument		bit,
	@LowerDateLimit	datetime,
	@UpperDateLimit	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF @NodeID IS NOT NULL SET @NodeTypeID = NULL
	IF @NodeID IS NOT NULL OR @AdditionalID = N'' SET @AdditionalID = NULL
	
	SELECT	ND.NodeTypeID, 
			MAX(ND.TypeAdditionalID) AS NodeTypeAdditionalID,
			MAX(ND.TypeName) AS TypeName, 
			COUNT(ND.NodeID) AS NodesCount
	FROM [dbo].[CN_NodeLikes] AS NL
		INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.NodeID = NL.NodeID
		LEFT JOIN [dbo].[CN_Services] AS S
		ON S.ApplicationID = @ApplicationID AND S.NodeTypeID = ND.NodeTypeID AND S.Deleted = 0
	WHERE NL.ApplicationID = @ApplicationID AND NL.UserID = @UserID AND 
		(@NodeID IS NULL OR ND.NodeID = @NodeID) AND
		(@NodeTypeID IS NULL OR ND.NodeTypeID = @NodeTypeID) AND 
		(@AdditionalID IS NULL OR ND.NodeAdditionalID = @AdditionalID) AND
		(@IsDocument IS NULL OR ISNULL(S.IsDocument, 0) = @IsDocument) AND
		(@LowerDateLimit IS NULL OR ND.CreationDate>= @LowerDateLimit) AND
		(@UpperDateLimit IS NULL OR ND.CreationDate <= @UpperDateLimit) AND
		 NL.Deleted = 0 AND ND.Deleted = 0
	GROUP BY ND.NodeTypeID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetFavoriteNodes]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetFavoriteNodes]
GO

CREATE PROCEDURE [dbo].[CN_GetFavoriteNodes]
	@ApplicationID			uniqueidentifier,
    @UserID					uniqueidentifier,
	@strNodeTypeIDs			nvarchar(max),
	@delimiter				char,
	@NodeID					uniqueidentifier,
	@AdditionalID			varchar(50),
	@SearchText				nvarchar(1000),
	@IsDocument				bit,
	@LowerDateLimit			datetime,
	@UpperDateLimit			datetime,
	@LowerBoundary			int,
	@Count					int
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @NodeTypeIDs KeyLessGuidTableType
	
	INSERT INTO @NodeTypeIDs ([Value])
	SELECT DISTINCT Ref.[Value]
	FROM [dbo].[GFN_StrToGuidTable](@strNodeTypeIDs, @delimiter) AS Ref
	
	DECLARE @NTCount int = (SELECT COUNT(*) FROM @NodeTypeIDs)
	
	IF @NodeID IS NOT NULL SET @NTCount = 0
	IF @NodeID IS NOT NULL OR @AdditionalID = N'' SET @AdditionalID = NULL
	IF @Count IS NULL OR @Count <= 0 SET @Count = 10
	
	SET @SearchText = [dbo].[GFN_VerifyString](@SearchText)
	IF @SearchText IS NULL OR @SearchText = N'' SET @SearchText = NULL

	DECLARE @SelectedIDs KeyLessGuidTableType

	IF @SearchText IS NULL BEGIN
		INSERT INTO @SelectedIDs (Value)
		SELECT Ref.NodeID
		FROM (
				SELECT ROW_NUMBER() OVER (ORDER BY NL.LikeDate DESC, NL.NodeID DESC) AS RowNumber, ND.NodeID
				FROM [dbo].[CN_NodeLikes] AS NL
					INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
					ON ND.ApplicationID = @ApplicationID AND ND.NodeID = NL.NodeID
					LEFT JOIN [dbo].[CN_Services] AS S
					ON S.ApplicationID = @ApplicationID AND S.NodeTypeID = ND.NodeTypeID AND S.Deleted = 0
				WHERE NL.ApplicationID = @ApplicationID AND NL.UserID = @UserID AND 
					(@NodeID IS NULL OR ND.NodeID = @NodeID) AND
					(@NTCount = 0 OR ND.NodeTypeID IN (SELECT NTIDs.Value FROM @NodeTypeIDs AS NTIDs)) AND 
					(@AdditionalID IS NULL OR ND.NodeAdditionalID = @AdditionalID) AND
					(@IsDocument IS NULL OR ISNULL(S.IsDocument, 0) = @IsDocument) AND
					(@LowerDateLimit IS NULL OR ND.CreationDate >= @LowerDateLimit) AND
					(@UpperDateLimit IS NULL OR ND.CreationDate <= @UpperDateLimit) AND
					NL.Deleted = 0 AND ND.Deleted = 0
			) AS Ref
		ORDER BY Ref.RowNumber ASC
	END
	ELSE BEGIN
		INSERT INTO @SelectedIDs (Value)
		SELECT Ref.NodeID
		FROM (
				SELECT ROW_NUMBER() OVER (ORDER BY SRCH.[Rank] DESC, SRCH.[Key] DESC) AS RowNumber, ND.NodeID
				FROM CONTAINSTABLE([dbo].[CN_Nodes], ([Name], [AdditionalID]), @SearchText) AS SRCH
					INNER JOIN [dbo].[CN_NodeLikes] AS NL
					INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
					ON ND.ApplicationID = @ApplicationID AND ND.NodeID = NL.NodeID
					ON ND.NodeID = SRCH.[Key]
					LEFT JOIN [dbo].[CN_Services] AS S
					ON S.ApplicationID = @ApplicationID AND S.NodeTypeID = ND.NodeTypeID AND S.Deleted = 0
				WHERE NL.ApplicationID = @ApplicationID AND NL.UserID = @UserID AND 
					(@NodeID IS NULL OR ND.NodeID = @NodeID) AND
					(@NTCount = 0 OR ND.NodeTypeID IN (SELECT NTIDs.Value FROM @NodeTypeIDs AS NTIDs)) AND 
					(@AdditionalID IS NULL OR ND.NodeAdditionalID = @AdditionalID) AND
					(@IsDocument IS NULL OR ISNULL(S.IsDocument, 0) = @IsDocument) AND
					(@LowerDateLimit IS NULL OR ND.CreationDate >= @LowerDateLimit) AND
					(@UpperDateLimit IS NULL OR ND.CreationDate <= @UpperDateLimit) AND
					NL.Deleted = 0 AND ND.Deleted = 0
			) AS Ref
		ORDER BY Ref.RowNumber ASC	
	END

	DECLARE @NodeIDs KeyLessGuidTableType

	INSERT INTO @NodeIDs (Value)
	SELECT TOP(@Count) S.Value 
	FROM @SelectedIDs AS S
	WHERE S.SequenceNumber >= ISNULL(@LowerBoundary, 0)
	
	EXEC [dbo].[CN_P_GetNodesByIDs] @ApplicationID, @NodeIDs, 0, NULL
	
	SELECT TOP(1) COUNT(S.[Value]) AS TotalCount FROM @SelectedIDs AS S
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_AddComplex]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_AddComplex]
GO

CREATE PROCEDURE [dbo].[CN_AddComplex]
	@ApplicationID			uniqueidentifier,
    @ListID					uniqueidentifier,
    @NodeTypeID				uniqueidentifier,
    @Name					nvarchar(255),
    @Description			nvarchar(2000),
    @CreatorUserID			uniqueidentifier,
    @CreationDate			datetime,
    @ParentListID			uniqueidentifier,
    @OwnerID				uniqueidentifier,
    @OwnerType				varchar(20)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @Name = [dbo].[GFN_VerifyString](@Name)
	SET @Description = [dbo].[GFN_VerifyString](@Description)

	INSERT INTO [dbo].[CN_Lists](
		ApplicationID,
		ListID,
		NodeTypeID,
		Name,
		[Description],
		CreatorUserID,
		CreationDate,
		ParentListID,
		OwnerID,
		OwnerType,
		Deleted
	)
	VALUES(
		@ApplicationID,
		@ListID,
		@NodeTypeID,
		@Name,
		@Description,
		@CreatorUserID,
		@CreationDate,
		@ParentListID,
		@OwnerID,
		@OwnerType,
		0
	)

	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_ModifyComplex]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_ModifyComplex]
GO

CREATE PROCEDURE [dbo].[CN_ModifyComplex]
	@ApplicationID			uniqueidentifier,
    @ListID					uniqueidentifier,
    @Name					nvarchar(255),
    @Description			nvarchar(2000),
    @LastModifierUserID		uniqueidentifier,
    @LastModificationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SET @Name = [dbo].[GFN_VerifyString](@Name)
	SET @Description = [dbo].[GFN_VerifyString](@Description)

	UPDATE [dbo].[CN_Lists]
		SET Name = @Name,
			[Description] = @Description,
			LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate
	WHERE ApplicationID = @ApplicationID AND ListID = @ListID

	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_ArithmeticDeleteComplexes]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_ArithmeticDeleteComplexes]
GO

CREATE PROCEDURE [dbo].[CN_ArithmeticDeleteComplexes]
	@ApplicationID			uniqueidentifier,
    @strListIDs				varchar(max),
    @delimiter				char,
    @LastModifierUsreID		uniqueidentifier,
    @LastModificationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @ListIDs GuidTableType
	INSERT INTO @ListIDs 
	SELECT DISTINCT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strListIDs, @delimiter) AS Ref

	UPDATE L
		SET Deleted = 1,
			LastModifierUserID = @LastModifierUsreID,
			LastModificationDate = @LastModificationDate
	FROM @ListIDs AS ExternalIDs
		INNER JOIN [dbo].[CN_Lists] AS L
		ON L.ApplicationID = @ApplicationID AND L.[ListID] = ExternalIDs.Value
	WHERE L.[Deleted] = 0

	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_GetListsByIDs]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_GetListsByIDs]
GO

CREATE PROCEDURE [dbo].[CN_P_GetListsByIDs]
	@ApplicationID	uniqueidentifier,
    @ListIDsTemp	GuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @ListIDs GuidTableType
	INSERT INTO @ListIDs SELECT * FROM @ListIDsTemp
	
	SELECT LS.ListID AS ListID,
		   LS.Name AS ListName,
		   LS.[Description] AS [Description],
		   LS.AdditionalID AS AdditionalID,
		   LS.NodeTypeID AS NodeTypeID,
		   NT.Name AS NodeType,
		   OwnerID AS OwnerID,
		   OwnerType AS OwnerType
	FROM @ListIDs AS Ref
		INNER JOIN [dbo].[CN_Lists] AS LS
		ON LS.ApplicationID = @ApplicationID AND LS.ListID = Ref.Value
		INNER JOIN [dbo].[CN_NodeTypes] AS NT
		ON NT.ApplicationID = @ApplicationID AND NT.NodeTypeID = LS.NodeTypeID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetListsByIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetListsByIDs]
GO

CREATE PROCEDURE [dbo].[CN_GetListsByIDs]
	@ApplicationID	uniqueidentifier,
	@strListIDs		varchar(max),
	@delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @ListIDs GuidTableType
	INSERT INTO @ListIDs
	SELECT DISTINCT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strListIDs, @delimiter) AS Ref
	
	EXEC [dbo].[CN_P_GetListsByIDs] @ApplicationID, @ListIDs
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetLists]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetLists]
GO

CREATE PROCEDURE [dbo].[CN_GetLists]
	@ApplicationID			uniqueidentifier,
	@NodeTypeID				uniqueidentifier,
	@NodeTypeAdditionalID	varchar(50),
    @SearchText				nvarchar(1000),
    @Count					int,
    @MinID					uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SET @SearchText = [dbo].[GFN_VerifyString](@SearchText)
	
	IF @NodeTypeID IS NULL AND @NodeTypeAdditionalID IS NOT NULL BEGIN
		SET @NodeTypeID = (
			SELECT TOP(1) NodeTypeID 
			FROM [dbo].[CN_NodeTypes] 
			WHERE ApplicationID = @ApplicationID AND AdditionalID = @NodeTypeAdditionalID
		)
	END

	DECLARE @TempIDs Table(sqno bigint IDENTITY(1, 1), ListID uniqueidentifier)
	DECLARE @ListIDs GuidTableType
	
	DECLARE @_ST nvarchar(1000) = @SearchText
	IF @SearchText IS NULL OR @SearchText = N'' SET @_ST = NULL
	
	IF @Count IS NULL OR @Count <= 0 SET @Count = 1000
	
	IF @_ST IS NULL BEGIN
		INSERT INTO @TempIDs
		SELECT LS.[ListID] 
		FROM [dbo].[CN_Lists] AS LS
		WHERE LS.ApplicationID = @ApplicationID AND 
			(@NodeTypeID IS NULL OR LS.[NodeTypeID] = @NodeTypeID) AND LS.[Deleted] = 0
	END
	ELSE BEGIN
		INSERT INTO @ListIDs
		SELECT LS.[ListID] 
		FROM [dbo].[CN_Lists] AS LS
		WHERE LS.ApplicationID = @ApplicationID AND 
			(@NodeTypeID IS NULL OR LS.[NodeTypeID] = @NodeTypeID) AND 
			LS.[Deleted] = 0 AND CONTAINS(LS.[Name], @_ST)
	END
	
	DECLARE @Loc bigint = 0
	IF @MinID IS NOT NULL 
		SET @Loc = (SELECT TOP(1) Ref.sqno FROM @TempIDs AS Ref WHERE Ref.ListID = @MinID)
	IF @Loc IS NULL SET @Loc = 0
	
	INSERT INTO @ListIDs
	SELECT TOP(@Count) Ref.ListID FROM @TempIDs AS Ref WHERE Ref.sqno > @Loc
	
	EXEC [dbo].[CN_P_GetListsByIDs] @ApplicationID, @ListIDs
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_AddNodesToList]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_AddNodesToList]
GO

CREATE PROCEDURE [dbo].[CN_P_AddNodesToList]
	@ApplicationID	uniqueidentifier,
	@ListID			uniqueidentifier,
    @NodeIDsTemp	GuidTableType readonly,
    @CreatorUserID	uniqueidentifier,
    @CreationDate	datetime,
    @_Result		int output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE @NodeIDs GuidTableType
	INSERT INTO @NodeIDs SELECT * FROM @NodeIDsTemp
	
	SET @_Result = -1
	
	DECLARE @_existingNodes GuidTableType, @_notExistingNodes GuidTableType
	DECLARE @_count int
	
	INSERT INTO @_existingNodes
	SELECT NID.Value
	FROM @NodeIDs AS NID
		INNER JOIN [dbo].[CN_ListNodes] AS LN
		ON LN.ApplicationID = @ApplicationID AND LN.NodeID = NID.Value
	WHERE LN.ListID = @ListID
	
	SET @_count = (SELECT COUNT(*) FROM @_existingNodes)
	
	IF @_count > 0 BEGIN
		UPDATE LN
			SET LastModifierUserID = @CreatorUserID,
				LastModificationDate = @CreationDate,
				Deleted = 0
		FROM @_existingNodes AS EN
			INNER JOIN [dbo].[CN_ListNodes] AS LN
			ON LN.NodeID = EN.Value
		WHERE LN.ApplicationID = @ApplicationID AND LN.ListID = @ListID
		
		IF @@ROWCOUNT <= 0 BEGIN
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	
	INSERT INTO @_notExistingNodes
	SELECT NID.Value
	FROM @NodeIDs AS NID
	WHERE NOT EXISTS(SELECT TOP(1) * FROM @_existingNodes AS Ref
		WHERE NID.Value = Ref.Value)
	
	SET @_count = (SELECT COUNT(*) FROM @_notExistingNodes)
	
	IF @_count > 0 BEGIN
		INSERT INTO [dbo].[CN_ListNodes](
			ApplicationID,
			ListID,
			NodeID,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		SELECT @ApplicationID, @ListID, NEN.Value, @CreatorUserID, @CreationDate, 0
		FROM @_notExistingNodes AS NEN
	
		IF @@ROWCOUNT <= 0 BEGIN
			ROLLBACK TRANSACTION
			RETURN
		END
	END	

	SET @_Result = 1
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_AddNodesToComplex]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_AddNodesToComplex]
GO

CREATE PROCEDURE [dbo].[CN_AddNodesToComplex]
	@ApplicationID	uniqueidentifier,
	@ListID			uniqueidentifier,
    @strNodeIDs		varchar(max),
    @delimiter		char,
    @CreatorUserID	uniqueidentifier,
    @CreationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeIDs GuidTableType
	INSERT INTO @NodeIDs
	SELECT DISTINCT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strNodeIDs, @delimiter) AS Ref
	
	DECLARE @_Result int
	
	EXEC [dbo].[CN_P_AddNodesToList] @ApplicationID, @ListID, @NodeIDs, 
		@CreatorUserID, @CreationDate, @_Result output
		
	SELECT @_Result
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_ArithmeticDeleteComplexNodes]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_ArithmeticDeleteComplexNodes]
GO

CREATE PROCEDURE [dbo].[CN_ArithmeticDeleteComplexNodes]
	@ApplicationID			uniqueidentifier,
	@ListID					uniqueidentifier,
    @strNodeIDs				varchar(max),
    @delimiter				char,
    @LastModifierUserID		uniqueidentifier,
    @LastModificationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeIDs GuidTableType
	INSERT INTO @NodeIDs
	SELECT DISTINCT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strNodeIDs, @delimiter) AS Ref
		
	UPDATE LN
		SET Deleted = 1,
			LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate
	FROM @NodeIDs AS NID
		INNER JOIN [dbo].[CN_ListNodes] AS LN
		ON LN.NodeID = NID.Value
	WHERE LN.ApplicationID = @ApplicationID AND LN.ListID = @ListID AND LN.Deleted = 0

	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetListNodes]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetListNodes]
GO

CREATE PROCEDURE [dbo].[CN_GetListNodes]
	@ApplicationID			uniqueidentifier,
	@ListID					uniqueidentifier,
	@NodeTypeID				uniqueidentifier,
	@NodeTypeAdditionalID	varchar(50)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF @NodeTypeID IS NULL 
		SET @NodeTypeID = [dbo].[CN_FN_GetNodeTypeID](@ApplicationID, @NodeTypeAdditionalID)
	
	DECLARE @NodeIDs KeyLessGuidTableType
	
	INSERT INTO @NodeIDs (Value)
	SELECT LN.NodeID
	FROM [dbo].[CN_ListNodes] AS LN
		INNER JOIN [dbo].[CN_Nodes] AS Node
		ON Node.ApplicationID = @ApplicationID AND Node.NodeID = LN.NodeID
	WHERE LN.ApplicationID = @ApplicationID AND LN.ListID = @ListID AND LN.Deleted = 0 AND 
		(@NodeTypeID IS NULL OR Node.NodeTypeID = @NodeTypeID) AND Node.Deleted = 0

	EXEC [dbo].[CN_P_GetNodesByIDs] @ApplicationID, @NodeIDs, 0, NULL
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_AddTags]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_AddTags]
GO

CREATE PROCEDURE [dbo].[CN_P_AddTags]
	@ApplicationID	uniqueidentifier,
	@TagsTemp		StringTableType readonly,
	@CreatorUserID	uniqueidentifier,
	@CreationDate	datetime,
	@TagID			uniqueidentifier output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Tags StringTableType
	INSERT INTO @Tags SELECT * FROM @TagsTemp
	
	DECLARE @VerifiedTags GuidStringTableType
	INSERT INTO @VerifiedTags (FirstValue, SecondValue)
	SELECT NEWID(), Ref.Val
	FROM (
			SELECT DISTINCT [dbo].[GFN_VerifyString](TG.Value) AS Val
			FROM @Tags AS TG
		) AS Ref
	
	DECLARE @ExistingTags GuidPairTableType
	INSERT INTO @ExistingTags
	SELECT TG.TagID, Ref.FirstValue
	FROM @VerifiedTags AS Ref
		INNER JOIN [dbo].[CN_Tags] AS TG
		ON TG.ApplicationID = @ApplicationID AND TG.Tag = Ref.SecondValue
		
	DECLARE @NotExistingTags GuidStringTableType
	INSERT INTO @NotExistingTags
	SELECT Ref.FirstValue, Ref.SecondValue
	FROM @VerifiedTags AS Ref
	WHERE Ref.FirstValue NOT IN (SELECT ET.SecondValue FROM @ExistingTags AS ET)
	
	IF EXISTS(SELECT TOP(1) * FROM @ExistingTags) BEGIN
		SET @TagID = (SELECT TOP(1) FirstValue FROM @ExistingTags AS Ref)
		
		UPDATE TG
			SET CallsCount = CallsCount + 1
		FROM @ExistingTags AS ET
			INNER JOIN [dbo].[CN_Tags] AS TG
			ON TG.ApplicationID = @ApplicationID AND TG.TagID = ET.FirstValue
	END
	ELSE BEGIN
		SET @TagID = (SELECT TOP(1) FirstValue FROM @NotExistingTags AS Ref)
		
		INSERT INTO [dbo].[CN_Tags](
			ApplicationID,
			TagID,
			Tag,
			IsApproved,
			CallsCount,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		SELECT @ApplicationID, Ref.FirstValue, Ref.SecondValue, 0, 0, 
			@CreatorUserID, @CreationDate, 0
		FROM @NotExistingTags AS Ref
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_AddTags]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_AddTags]
GO

CREATE PROCEDURE [dbo].[CN_AddTags]
	@ApplicationID	uniqueidentifier,
	@TagsTemp		StringTableType readonly,
	@CreatorUserID	uniqueidentifier,
	@CreationDate	datetime
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Tags StringTableType
	INSERT INTO @Tags SELECT * FROM @TagsTemp
	
	DECLARE @TagID uniqueidentifier
	
	EXEC [dbo].[CN_P_AddTags] @ApplicationID, @Tags, 
		@CreatorUserID, @CreationDate, @TagID output
	
	SELECT @TagID AS ID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_SearchTags]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_SearchTags]
GO

CREATE PROCEDURE [dbo].[CN_P_SearchTags]
	@ApplicationID	uniqueidentifier,
	@SearchText		nvarchar(1000),
	@Count			int,
	@LowerBoundary	int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @SearchText = [dbo].[GFN_VerifyString](@SearchText)
	
	IF @Count IS NULL OR @Count <= 0 SET @Count = 1000
	
	IF ISNULL(@SearchText, N'') = N'' BEGIN
		SELECT TOP(@Count) X.TagID, X.Tag, X.IsApproved, X.CallsCount
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY Tag ASC) AS RowNumber,
						TagID, 
						Tag, 
						IsApproved, 
						CallsCount
				FROM [dbo].[CN_Tags] AS TG
				WHERE TG.ApplicationID = @ApplicationID AND TG.Deleted = 0 AND ISNULL(TG.Tag, N'') <> N''
			) AS X
		WHERE X.RowNumber >= ISNULL(@LowerBoundary, 0)
		ORDER BY X.RowNumber ASC
	END
	ELSE BEGIN
		SELECT TOP(@Count) X.TagID, X.Tag, X.IsApproved, X.CallsCount
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY SRCH.[Rank] DESC, Tag ASC) AS RowNumber,
						TagID, 
						Tag, 
						IsApproved, 
						CallsCount
				FROM CONTAINSTABLE([dbo].[CN_Tags], Tag, @SearchText) AS SRCH
					INNER JOIN [dbo].[CN_Tags] AS TG
					ON TG.ApplicationID = @ApplicationID AND TG.TagID = SRCH.[Key] AND TG.Deleted = 0
			) AS X
		WHERE X.RowNumber >= ISNULL(@LowerBoundary, 0)
		ORDER BY X.RowNumber ASC
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_SearchTags]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_SearchTags]
GO

CREATE PROCEDURE [dbo].[CN_SearchTags]
	@ApplicationID	uniqueidentifier,
	@SearchText		nvarchar(1000),
	@Count			int,
	@LowerBoundary	int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	EXEC [dbo].[CN_P_SearchTags] @ApplicationID, @SearchText, @Count, @LowerBoundary
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_SetNodeCreators]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_SetNodeCreators]
GO

CREATE PROCEDURE [dbo].[CN_P_SetNodeCreators]
	@ApplicationID	uniqueidentifier,
	@NodeID			uniqueidentifier,
	@CreatorsTemp	GuidFloatTableType readonly,
	@Status			varchar(20),
	@CreatorUserID	uniqueidentifier,
	@CreationDate	datetime,
	@_Result		int	output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Creators GuidFloatTableType
	INSERT INTO @Creators SELECT * FROM @CreatorsTemp
	
	IF (SELECT COUNT(*) FROM @Creators) = 0 BEGIN
		SET @_Result = 1
		RETURN
	END
	
	DECLARE @Shares Table (UserID uniqueidentifier, Share float, [Exists] bit)
	
	INSERT INTO @Shares (UserID, Share, [Exists])
	SELECT Ref.FirstValue, Ref.SecondValue, CASE WHEN NC.NodeID IS NULL THEN 0 ELSE 1 END
	FROM @Creators AS Ref
		LEFT JOIN [dbo].[CN_NodeCreators] AS NC
		ON NC.ApplicationID = @ApplicationID AND 
			NC.NodeID = @NodeID AND NC.UserID = Ref.FirstValue
	
		
	UPDATE [dbo].[CN_NodeCreators]
		SET Deleted = 1,
			LastModifierUserID = @CreatorUserID,
			LastModificationDate = @CreationDate
	FROM [dbo].[CN_NodeCreators]
	WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID
		
		
	IF EXISTS(SELECT TOP(1) UserID FROM @Shares WHERE [Exists] = 1) BEGIN
		UPDATE NC
			SET Deleted = 0,
				CollaborationShare = Ref.Share,
				[Status] = @Status,
				LastModifierUserID = @CreatorUserID,
				LastModificationDate = @CreationDate
		FROM @Shares AS Ref
			INNER JOIN [dbo].[CN_NodeCreators] AS NC
			ON NC.UserID = Ref.UserID
		WHERE NC.ApplicationID = @ApplicationID AND NC.NodeID = @NodeID
		
		IF @@ROWCOUNT <= 0 BEGIN
			SET @_Result = -1
			RETURN
		END
	END
	
	IF EXISTS(SELECT TOP(1) UserID FROM @Shares WHERE [Exists] = 0) BEGIN
		INSERT INTO [dbo].[CN_NodeCreators](
			ApplicationID,
			NodeID,
			UserID,
			CollaborationShare,
			[Status],
			CreatorUserID,
			CreationDate,
			Deleted,
			UniqueID
		)
		SELECT	@ApplicationID, @NodeID, Ref.UserID, Ref.Share, @Status, 
				@CreatorUserID, @CreationDate, 0, NEWID()
		FROM @Shares AS Ref
		WHERE Ref.[Exists] = 0
		
		IF @@ROWCOUNT <= 0 BEGIN
			SET @_Result = -1
			RETURN
		END
	END
	
	SET @_Result = 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_SetContributors]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_SetContributors]
GO

CREATE PROCEDURE [dbo].[CN_SetContributors]
	@ApplicationID			uniqueidentifier,
	@NodeID					uniqueidentifier,
	@ContributorsTemp		GuidFloatTableType readonly,
	@OwnerID				uniqueidentifier,
	@LastModifierUserID		uniqueidentifier,
	@LastModificationDate	datetime
WITH ENCRYPTION, RECOMPILE
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE @Contributors GuidFloatTableType
	INSERT INTO @Contributors SELECT * FROM @ContributorsTemp
	
	DECLARE @_Result int = 0
	
	EXEC [dbo].[CN_P_SetNodeCreators] @ApplicationID, @NodeID, @Contributors, N'Accepted', 
		@LastModifierUserID, @LastModificationDate, @_Result output 
	
	IF @_Result <= 0 BEGIN
		SELECT -1, N'ErrorInAddingNodeCreators'
		ROLLBACK TRANSACTION
		RETURN
	END
	
	UPDATE [dbo].[CN_Nodes]
		SET OwnerID = @OwnerID,
			LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate
	WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID
	
	IF @@ROWCOUNT <= 0 BEGIN
		SELECT -1, N'SettingNodeOwnerFailed'
		ROLLBACK TRANSACTION
		RETURN
	END
	
	SELECT 1
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetNodeCreators]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetNodeCreators]
GO

CREATE PROCEDURE [dbo].[CN_GetNodeCreators]
	@ApplicationID	uniqueidentifier,
	@NodeIDsTemp	GuidTableType readonly,
	@Full			bit
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @NodeIDs GuidTableType
	INSERT INTO @NodeIDs ([Value]) SELECT [Value] FROM @NodeIDsTemp
	
	IF @Full IS NULL OR @Full = 0 BEGIN
		SELECT NodeID AS NodeID,
			   UserID AS UserID,
			   CollaborationShare AS CollaborationShare,
			   [Status] AS [Status]
		FROM @NodeIDs AS IDs
			INNER JOIN [dbo].[CN_NodeCreators] AS ND
			ON ND.ApplicationID = @ApplicationID AND ND.NodeID = IDs.[Value] AND ND.Deleted = 0
	END
	ELSE BEGIN
		SELECT NC.NodeID,
			   NC.UserID,
			   UN.UserName,
			   UN.FirstName,
			   UN.LastName,
			   UN.AvatarName,
			   UN.UseAvatar,
			   UN.NationalID,
			   UN.PersonnelID,
			   NC.CollaborationShare,
			   NC.[Status]
		FROM @NodeIDs AS IDs
			INNER JOIN [dbo].[CN_NodeCreators] AS NC
			ON NC.ApplicationID = @ApplicationID AND NC.NodeID = IDs.[Value] AND NC.Deleted = 0
			LEFT JOIN [dbo].[Users_Normal] AS UN
			ON UN.ApplicationID = @ApplicationID AND UN.UserID = NC.UserID
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_GetCreatedNodeIDs]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_GetCreatedNodeIDs]
GO

CREATE PROCEDURE [dbo].[CN_P_GetCreatedNodeIDs]
	@ApplicationID	uniqueidentifier,
	@UserID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT NodeID AS ID
	FROM [dbo].[CN_Nodes]
	WHERE ApplicationID = @ApplicationID AND CreatorUserID = @UserID AND Deleted = 0
	
	UNION ALL
	
	SELECT NC.NodeID
	FROM [dbo].[CN_NodeCreators] AS NC
		INNER JOIN [dbo].[CN_Nodes] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.NodeID = NC.NodeID
	WHERE NC.ApplicationID = @ApplicationID AND NC.UserID = @UserID AND NC.Deleted = 0 AND 
		ND.CreatorUserID <> @UserID AND ND.Deleted = 0
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetCreatorNodes]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetCreatorNodes]
GO

CREATE PROCEDURE [dbo].[CN_GetCreatorNodes]
	@ApplicationID	uniqueidentifier,
	@UserID			uniqueidentifier,
	@NodeTypeID		uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeIDs KeyLessGuidTableType
	
	INSERT INTO @NodeIDs (Value)
	SELECT NC.NodeID
	FROM [dbo].[CN_NodeCreators] AS NC
		INNER JOIN [dbo].[CN_Nodes] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.NodeID = NC.NodeID
	WHERE NC.ApplicationID = @ApplicationID AND NC.UserID = @UserID AND 
		(@NodeTypeID IS NULL OR ND.NodeTypeID = @NodeTypeID) AND 
		NC.Deleted = 0 AND ND.Deleted = 0
	
	EXEC [dbo].[CN_P_GetNodesByIDs] @ApplicationID, @NodeIDs, NULL, NULL
END

GO


/*     Expert related procedures     */

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_AddExperts]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_AddExperts]
GO

CREATE PROCEDURE [dbo].[CN_P_AddExperts]
	@ApplicationID		uniqueidentifier,
    @NodeID 			uniqueidentifier,
    @UserIDsTemp		GuidTableType readonly,
    @_Result			int output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE @UserIDs GuidTableType
	INSERT INTO @UserIDs SELECT * FROM @UserIDsTemp
	
	DECLARE @ExistingIDs GuidTableType, @NotExistingIDs GuidTableType
	
	INSERT INTO @ExistingIDs
	SELECT Ref.Value
	FROM @UserIDs AS Ref
		INNER JOIN [dbo].[CN_Experts] AS Ex
		ON Ex.UserID = Ref.Value
	WHERE Ex.ApplicationID = @ApplicationID AND Ex.NodeID = @NodeID
	
	INSERT INTO @NotExistingIDs 
	SELECT Ref.Value
	FROM @UserIDs AS Ref
	EXCEPT(SELECT * FROM @ExistingIDs)
	
	IF (SELECT COUNT(*) FROM @ExistingIDs) > 0 BEGIN
		UPDATE [dbo].[CN_Experts]
			SET Approved = 1
		FROM @ExistingIDs AS Ref
			INNER JOIN [dbo].[CN_Experts] AS Ex
			ON Ex.[UserID] = Ref.Value
		WHERE Ex.ApplicationID = @ApplicationID AND Ex.[NodeID] = @NodeID
		
		IF @@ROWCOUNT <= 0 BEGIN
			SET @_Result = -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	IF (SELECT COUNT(*) FROM @NotExistingIDs) > 0 BEGIN
		INSERT INTO [dbo].[CN_Experts] (
			[ApplicationID],
			[NodeID],
			[UserID],
			[Approved],
			[ReferralsCount],
			[ConfirmsPercentage],
			[SocialApproved],
			[UniqueID]
		)
		SELECT @ApplicationID, @NodeID, Ref.Value, 1, 0, 0, 0, NEWID()
		FROM @NotExistingIDs AS Ref
		
		IF @@ROWCOUNT <= 0 BEGIN
			SET @_Result = -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
    
    SET @_Result = 1
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_AddExperts]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_AddExperts]
GO

CREATE PROCEDURE [dbo].[CN_AddExperts]
	@ApplicationID		uniqueidentifier,
    @NodeID 			uniqueidentifier,
    @strUserIDs			varchar(max),
    @delimiter			char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserIDs GuidTableType
	
	INSERT INTO @UserIDs
	SELECT DISTINCT Ref.Value FROM GFN_StrToGuidTable(@strUserIDs, @delimiter) AS Ref
	
	DECLARE @_Result int
	
	EXEC [dbo].[CN_P_AddExperts] @ApplicationID, @NodeID, @UserIDs, @_Result output
	
	SELECT @_Result
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_AddExpert]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_AddExpert]
GO

CREATE PROCEDURE [dbo].[CN_P_AddExpert]
	@ApplicationID		uniqueidentifier,
    @NodeID 			uniqueidentifier,
    @UserID				uniqueidentifier,
    @_Result			int output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserIDs GuidTableType
	INSERT INTO @UserIDs (Value) VALUES(@UserID)
	
	EXEC [dbo].[CN_P_AddExperts] @ApplicationID, @NodeID, @UserIDs, @_Result output
	
	SELECT @_Result
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_ArithmeticDeleteExperts]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_ArithmeticDeleteExperts]
GO

CREATE PROCEDURE [dbo].[CN_ArithmeticDeleteExperts]
	@ApplicationID	uniqueidentifier,
    @NodeID 		uniqueidentifier,
    @strUserIDs		varchar(max),
    @delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @UserIDs GuidTableType
	
	INSERT INTO @UserIDs
	SELECT DISTINCT Ref.Value FROM GFN_StrToGuidTable(@strUserIDs, @delimiter) AS Ref

    UPDATE [dbo].[CN_Experts]
        SET Approved = 0
    WHERE ApplicationID = @ApplicationID AND [NodeID] = @NodeID AND
		EXISTS(SELECT TOP(1) * FROM @UserIDs AS Ref WHERE [UserID] = Ref.Value)
    
    SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetExpertiseDomainsCount]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetExpertiseDomainsCount]
GO

CREATE PROCEDURE [dbo].[CN_GetExpertiseDomainsCount]
	@ApplicationID	uniqueidentifier,
	@UserID			uniqueidentifier,
	@NodeTypeID		uniqueidentifier,
	@NodeID			uniqueidentifier,
	@AdditionalID	varchar(50),
	@LowerDateLimit	datetime,
	@UpperDateLimit	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF @NodeID IS NOT NULL SET @NodeTypeID = NULL
	IF @NodeID IS NOT NULL OR @AdditionalID = N'' SET @AdditionalID = NULL
	
	SELECT	ND.NodeTypeID, 
			MAX(ND.TypeAdditionalID) AS NodeTypeAdditionalID,
			MAX(ND.TypeName) AS TypeName, 
			COUNT(ND.NodeID) AS NodesCount
	FROM [dbo].[CN_View_Experts] AS EX
		INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.NodeID = EX.NodeID
	WHERE EX.ApplicationID = @ApplicationID AND EX.UserID = @UserID AND 
		(@NodeID IS NULL OR ND.NodeID = @NodeID) AND
		(@NodeTypeID IS NULL OR ND.NodeTypeID = @NodeTypeID) AND 
		(@AdditionalID IS NULL OR ND.NodeAdditionalID = @AdditionalID) AND
		(@LowerDateLimit IS NULL OR ND.CreationDate>= @LowerDateLimit) AND
		(@UpperDateLimit IS NULL OR ND.CreationDate <= @UpperDateLimit) AND
		ND.Deleted = 0
	GROUP BY ND.NodeTypeID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetExpertiseDomains]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetExpertiseDomains]
GO

CREATE PROCEDURE [dbo].[CN_GetExpertiseDomains]
	@ApplicationID	uniqueidentifier,
	@UserID			uniqueidentifier,
	@strNodeTypeIDs	varchar(max),
	@delimiter		char,
	@NodeID			uniqueidentifier,
	@AdditionalID	varchar(50),
	@SearchText		nvarchar(1000),
	@LowerDateLimit	datetime,
	@UpperDateLimit	datetime,
	@LowerBoundary	int,
	@Count			int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeTypeIDs GuidTableType
	
	INSERT INTO @NodeTypeIDs (Value)
	SELECT DISTINCT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strNodeTypeIDs, @delimiter) AS Ref
	
	DECLARE @NTCount int = (SELECT COUNT(*) FROM @NodeTypeIDs)
	
	IF @NodeID IS NOT NULL SET @NTCount = 0
	IF @NodeID IS NOT NULL OR @AdditionalID = N'' SET @AdditionalID = NULL
	IF @Count IS NULL OR @Count <= 0 SET @Count = 10
	
	SET @SearchText = [dbo].[GFN_VerifyString](@SearchText)
	IF @SearchText IS NULL OR @SearchText = N'' SET @SearchText = NULL
	
	DECLARE @SelectedIDs KeyLessGuidTableType
	
	IF @SearchText IS NULL BEGIN
		INSERT INTO @SelectedIDs (Value)
		SELECT Ref.NodeID
		FROM (
				SELECT ROW_NUMBER() OVER (ORDER BY ND.CreationDate DESC, EX.NodeID DESC) AS RowNumber, ND.NodeID
				FROM [dbo].[CN_View_Experts] AS EX
					INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
					ON ND.ApplicationID = @ApplicationID AND ND.NodeID = EX.NodeID
				WHERE EX.ApplicationID = @ApplicationID AND EX.UserID = @UserID AND 
					(@NodeID IS NULL OR ND.NodeID = @NodeID) AND
					(@NTCount = 0 OR ND.NodeTypeID IN (SELECT NTIDs.Value FROM @NodeTypeIDs AS NTIDs)) AND 
					(@AdditionalID IS NULL OR ND.NodeAdditionalID = @AdditionalID) AND
					(@LowerDateLimit IS NULL OR ND.CreationDate>= @LowerDateLimit) AND
					(@UpperDateLimit IS NULL OR ND.CreationDate <= @UpperDateLimit) AND
					ND.Deleted = 0
			) AS Ref
		ORDER BY Ref.RowNumber ASC
	END
	ELSE BEGIN
		INSERT INTO @SelectedIDs (Value)
		SELECT Ref.NodeID
		FROM (
				SELECT ROW_NUMBER() OVER (ORDER BY SRCH.[Rank] DESC, SRCH.[Key] DESC) AS RowNumber, ND.NodeID
				FROM CONTAINSTABLE([dbo].[CN_Nodes], ([Name], [AdditionalID]), @SearchText) AS SRCH
					INNER JOIN [dbo].[CN_View_Experts] AS EX
					INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
					ON ND.ApplicationID = @ApplicationID AND ND.NodeID = EX.NodeID
					ON ND.NodeID = SRCH.[Key]
				WHERE EX.ApplicationID = @ApplicationID AND EX.UserID = @UserID AND 
					(@NodeID IS NULL OR ND.NodeID = @NodeID) AND
					(@NTCount = 0 OR ND.NodeTypeID IN (SELECT NTIDs.Value FROM @NodeTypeIDs AS NTIDs)) AND 
					(@AdditionalID IS NULL OR ND.NodeAdditionalID = @AdditionalID) AND
					(@LowerDateLimit IS NULL OR ND.CreationDate>= @LowerDateLimit) AND
					(@UpperDateLimit IS NULL OR ND.CreationDate <= @UpperDateLimit) AND
					ND.Deleted = 0
			) AS Ref
		ORDER BY Ref.RowNumber ASC
	END
	
	DECLARE @NodeIDs KeyLessGuidTableType

	INSERT INTO @NodeIDs (Value)
	SELECT TOP(@Count) S.Value 
	FROM @SelectedIDs AS S
	WHERE S.SequenceNumber >= ISNULL(@LowerBoundary, 0)
	
	EXEC [dbo].[CN_P_GetNodesByIDs] @ApplicationID, @NodeIDs, 0, NULL
	
	SELECT TOP(1) COUNT(S.Value) AS TotalCount FROM @SelectedIDs AS S
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_GetUsersExpertiseDomains]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_GetUsersExpertiseDomains]
GO

CREATE PROCEDURE [dbo].[CN_P_GetUsersExpertiseDomains]
	@ApplicationID	uniqueidentifier,
    @UserIDsTemp	GuidTableType ReadOnly,
    @NodeTypeID		uniqueidentifier,
    @Approved		bit,
    @SocialApproved bit,
    @All			bit
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserIDs GuidTableType
	INSERT INTO @UserIDs SELECT * FROM @UserIDsTemp
	
	SELECT EX.[NodeID] AS NodeID,
		   VN.[NodeAdditionalID] AS NodeAdditionalID,
		   VN.[NodeName] AS NodeName,
		   VN.[NodeTypeID] AS NodeTypeID,
		   VN.[TypeName] AS NodeType,
		   VN.AvatarName,
		   VN.UseAvatar,
		   EX.[UserID] AS ExpertUserID,
		   UN.[UserName] AS ExpertUserName,
		   UN.[FirstName] AS ExpertFirstName,
		   UN.[LastName] AS ExpertLastName,
		   UN.AvatarName AS ExpertAvatarName,
		   UN.UseAvatar AS ExpertUseAvatar,
		   EX.[Approved] AS Approved,
		   EX.[SocialApproved] AS SocialApproved,
		   EX.ReferralsCount AS ReferralsCount,
		   EX.ConfirmsPercentage AS ConfirmsPercentage
	FROM @UserIDs AS ExternalIDs
		INNER JOIN [dbo].[CN_Experts] AS EX
		ON EX.ApplicationID = @ApplicationID AND EX.[UserID] = ExternalIDs.Value
		INNER JOIN [dbo].[CN_View_Nodes_Normal] AS VN
		ON VN.ApplicationID = @ApplicationID AND VN.[NodeID] = EX.[NodeID]
		INNER JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND UN.[UserID] = EX.[UserID]
	WHERE (@NodeTypeID IS NULL OR VN.NodeTypeID = @NodeTypeID) AND 
		(
			(@All = 1 AND EX.SocialApproved IS NOT NULL) OR 
			(@Approved = 1 AND EX.Approved = 1) OR
			(@SocialApproved = 1 AND EX.SocialApproved = 1)
		) AND
		VN.Deleted = 0 AND UN.IsApproved = 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_GetUsersExpertiseDomainIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_GetUsersExpertiseDomainIDs]
GO

CREATE PROCEDURE [dbo].[CN_P_GetUsersExpertiseDomainIDs]
	@ApplicationID	uniqueidentifier,
    @UserIDsTemp	GuidTableType ReadOnly,
    @Approved		bit,
    @SocialApproved bit
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserIDs GuidTableType
	INSERT INTO @UserIDs SELECT * FROM @UserIDsTemp
	
	SELECT EX.[NodeID] AS ID
	FROM @UserIDs AS ExternalIDs
		INNER JOIN [dbo].[CN_Experts] AS EX
		ON EX.[UserID] = ExternalIDs.Value
		INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.[NodeID] = EX.[NodeID]
	WHERE EX.ApplicationID = @ApplicationID AND ((@Approved = 1 AND EX.Approved = 1) OR 
		(@SocialApproved = 1 AND EX.SocialApproved = 1)) AND
		ND.[Deleted] = 0
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetExperts]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetExperts]
GO

CREATE PROCEDURE [dbo].[CN_GetExperts]
	@ApplicationID	uniqueidentifier,
    @strNodeIDs		varchar(max),
	@delimiter		char,
	@SearchText		nvarchar(255),
	@Hierarchy		bit,
    @Count			int,
    @LowerBoundary	bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeIDs GuidTableType
	
	INSERT INTO @NodeIDs
	SELECT DISTINCT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strNodeIDs, @delimiter) AS Ref
	
	IF @Hierarchy = 1 BEGIN
		INSERT INTO @NodeIDs (Value)
		SELECT DISTINCT T.NodeID
		FROM [dbo].[CN_FN_GetNodesHierarchy](@ApplicationID, @NodeIDs) AS T
			LEFT JOIN @NodeIDs AS IDs
			ON IDs.Value = T.NodeID
		WHERE IDs.Value IS NULL
	END
	
	IF ISNULL(@Count, 0) <= 0 SET @Count = 1000000
	
	IF ISNULL(@SearchText, N'') = N'' BEGIN
		SELECT TOP(@Count)
			Ref.RowNumber AS [Order],
			(Ref.RowNumber + Ref.RevRowNumber - 1) AS TotalCount,
			Ref.NodeID,
			Ref.UserID AS ExpertUserID,
			ND.[NodeAdditionalID] AS NodeAdditionalID,
			ND.[NodeName] AS NodeName,
			ND.[NodeTypeID] AS NodeTypeID,
			ND.[TypeName] AS NodeType,
			ND.AvatarName,
			ND.UseAvatar,
			UN.[UserName] AS ExpertUserName,
			UN.[FirstName] AS ExpertFirstName,
			UN.[LastName] AS ExpertLastName,
			UN.AvatarName AS ExpertAvatarName,
			UN.UseAvatar AS ExpertUseAvatar
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY Ex.NodeID DESC, Ex.UserID DESC) AS RowNumber,
						ROW_NUMBER() OVER (ORDER BY Ex.NodeID ASC, Ex.UserID ASC) AS RevRowNumber,
						Ex.NodeID,
						Ex.UserID
				FROM @NodeIDs AS N
					INNER JOIN [dbo].[CN_View_Experts] AS Ex
					ON Ex.ApplicationID = @ApplicationID AND Ex.NodeID = N.Value
			) AS Ref
			INNER JOIN [dbo].[Users_Normal] AS UN
			ON UN.ApplicationID = @ApplicationID AND UN.UserID = Ref.UserID
			INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
			ON ND.ApplicationID = @ApplicationID AND ND.NodeID = Ref.NodeID
		WHERE Ref.RowNumber >= ISNULL(@LowerBoundary, 0)
		ORDER BY Ref.RowNumber ASC
	END
	ELSE BEGIN
		SELECT TOP(@Count)
			Ref.RowNumber AS [Order],
			(Ref.RowNumber + Ref.RevRowNumber - 1) AS TotalCount,
			Ref.NodeID,
			Ref.UserID AS ExpertUserID,
			ND.[NodeAdditionalID] AS NodeAdditionalID,
			ND.[NodeName] AS NodeName,
			ND.[NodeTypeID] AS NodeTypeID,
			ND.[TypeName] AS NodeType,
			ND.AvatarName,
			ND.UseAvatar,
			UN.[UserName] AS ExpertUserName,
			UN.[FirstName] AS ExpertFirstName,
			UN.[LastName] AS ExpertLastName,
			UN.AvatarName AS ExpertAvatarName,
			UN.UseAvatar AS ExpertUseAvatar
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY SRCH.[Rank] DESC, Ex.NodeID DESC, Ex.UserID DESC) AS RowNumber,
						ROW_NUMBER() OVER (ORDER BY SRCH.[Rank] ASC, Ex.NodeID ASC, Ex.UserID ASC) AS RevRowNumber,
						Ex.NodeID,
						Ex.UserID
				FROM @NodeIDs AS N
					INNER JOIN [dbo].[CN_View_Experts] AS Ex
					ON Ex.ApplicationID = @ApplicationID AND Ex.NodeID = N.Value
					INNER JOIN CONTAINSTABLE([dbo].[USR_View_Users], ([UserName], [FirstName], [LastName]), @SearchText) AS SRCH
					ON SRCH.[Key] = Ex.UserID
			) AS Ref
			INNER JOIN [dbo].[Users_Normal] AS UN
			ON UN.ApplicationID = @ApplicationID AND UN.UserID = Ref.UserID
			INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
			ON ND.ApplicationID = @ApplicationID AND ND.NodeID = Ref.NodeID
		WHERE Ref.RowNumber >= ISNULL(@LowerBoundary, 0)
		ORDER BY Ref.RowNumber ASC
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetUsersExpertiseDomains]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetUsersExpertiseDomains]
GO

CREATE PROCEDURE [dbo].[CN_GetUsersExpertiseDomains]
	@ApplicationID	uniqueidentifier,
    @strUserIDs		varchar(max),
    @delimiter		char,
    @NodeTypeID		uniqueidentifier,
    @Approved		bit,
    @SocialApproved bit,
    @All			bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserIDs GuidTableType
	
	INSERT INTO @UserIDs
	SELECT DISTINCT Ref.Value FROM GFN_StrToGuidTable(@strUserIDs, @delimiter) AS Ref
	
	EXEC [dbo].[CN_P_GetUsersExpertiseDomains] @ApplicationID, 
		@UserIDs, @NodeTypeID, @Approved, @SocialApproved, @All
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetUsersExpertiseDomainIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetUsersExpertiseDomainIDs]
GO

CREATE PROCEDURE [dbo].[CN_GetUsersExpertiseDomainIDs]
	@ApplicationID	uniqueidentifier,
    @strUserIDs		varchar(max),
    @delimiter		char,
    @Approved		bit,
    @SocialApproved bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @UserIDs GuidTableType
	
	INSERT INTO @UserIDs
	SELECT DISTINCT Ref.Value FROM GFN_StrToGuidTable(@strUserIDs, @delimiter) AS Ref
	
	EXEC [dbo].[CN_P_GetUsersExpertiseDomainIDs] @ApplicationID, 
		@UserIDs, @Approved, @SocialApproved
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_IsExpert]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_IsExpert]
GO

CREATE PROCEDURE [dbo].[CN_IsExpert]
	@ApplicationID	uniqueidentifier,
    @UserID			uniqueidentifier,
    @NodeID			uniqueidentifier,
    @Approved		bit,
    @SocialApproved bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT 1 
	WHERE EXISTS(
			SELECT * 
			FROM [dbo].[CN_Experts] AS EX
			WHERE EX.ApplicationID = @ApplicationID AND 
				((@Approved = 1 AND EX.Approved = 1) OR 
				(@SocialApproved = 1 AND EX.SocialApproved = 1)) AND
				EX.UserID = @UserID AND EX.NodeID = @NodeID
		)
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetExpertsCount]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetExpertsCount]
GO

CREATE PROCEDURE [dbo].[CN_GetExpertsCount]
	@ApplicationID	uniqueidentifier,
	@NodeID			uniqueidentifier,
	@DistinctUsers	bit,
	@Approved		bit,
	@SocialApproved bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF @DistinctUsers = 1 BEGIN
		SELECT COUNT(*) FROM
		(SELECT COUNT(*) AS CNT 
		FROM [dbo].[CN_Experts] AS EX
			INNER JOIN [dbo].[Users_Normal] AS UN
			ON UN.ApplicationID = @ApplicationID AND UN.[UserID] = EX.[UserID]
			INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
			ON ND.ApplicationID = @ApplicationID AND ND.[NodeID] = EX.[NodeID]
		WHERE EX.ApplicationID = @ApplicationID AND 
			(@NodeID IS NULL OR EX.[NodeID] = @NodeID) AND
			((@Approved = 1 AND EX.Approved = 1) OR 
			(@SocialApproved = 1 AND EX.SocialApproved = 1)) AND
			UN.IsApproved = 1 AND ND.[Deleted] = 0
		GROUP BY UN.[UserID]) AS Ref
	END
	ELSE BEGIN
		SELECT COUNT(*) 
		FROM [dbo].[CN_Experts] AS EX
			INNER JOIN [dbo].[Users_Normal] AS UN
			ON UN.ApplicationID = @ApplicationID AND UN.[UserID] = EX.[UserID]
			INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
			ON ND.ApplicationID = @ApplicationID AND ND.[NodeID] = EX.[NodeID]
		WHERE EX.ApplicationID = @ApplicationID AND 
			(@NodeID IS NULL OR EX.[NodeID] = @NodeID) AND
			((@Approved = 1 AND EX.Approved = 1) OR 
			(@SocialApproved = 1 AND EX.SocialApproved = 1)) AND
			UN.IsApproved = 1 AND ND.Deleted = 0
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_CalculateSocialExpertise]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_CalculateSocialExpertise]
GO

CREATE PROCEDURE [dbo].[CN_P_CalculateSocialExpertise]
	@ApplicationID							uniqueidentifier,
	@NodeID									uniqueidentifier,
	@UserID									uniqueidentifier,
	@DefaultMinAcceptableReferralsCount		int,
	@DefaultMinAcceptableConfirmsPercentage int,
	@_Result								int output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @ReferralsCount int, @ConfirmsPercentage float, @SocialApproved bit = 0
	
	SELECT @ReferralsCount = COUNT(*)
	FROM [dbo].[CN_ExpertiseReferrals]
	WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID AND 
		UserID = @UserID AND [Status] IS NOT NULL
	
	SELECT @ConfirmsPercentage = (
		CASE
			WHEN @ReferralsCount = 0 THEN 0 
			ELSE (CAST(COUNT(*) AS float) / CAST(@ReferralsCount AS float)) * 100 
		END
	)
	
	FROM [dbo].[CN_ExpertiseReferrals]
	WHERE ApplicationID = @ApplicationID AND 
		NodeID = @NodeID AND UserID = @UserID AND [Status] = 1
	
	IF @ReferralsCount >= @DefaultMinAcceptableReferralsCount AND
		@ConfirmsPercentage >= @DefaultMinAcceptableConfirmsPercentage
		SET @SocialApproved = 1
		
	UPDATE [dbo].[CN_Experts]
		SET ReferralsCount = @ReferralsCount,
			ConfirmsPercentage = @ConfirmsPercentage,
			SocialApproved = @SocialApproved
	WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID AND UserID = @UserID
	
	SET @_Result = @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_VoteExpertise]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_VoteExpertise]
GO

CREATE PROCEDURE [dbo].[CN_VoteExpertise]
	@ApplicationID							uniqueidentifier,
	@ReferrerUserID							uniqueidentifier,
	@NodeID									uniqueidentifier,
	@UserID									uniqueidentifier,
	@Status									bit,
	@SendDate								datetime,
	@DefaultMinAcceptableReferralsCount		int,
	@DefaultMinAcceptableConfirmsPercentage int
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
		
	IF EXISTS(
		SELECT TOP(1) * 
		FROM [dbo].[CN_ExpertiseReferrals]
		WHERE ApplicationID = @ApplicationID AND 
			ReferrerUserID = @ReferrerUserID AND NodeID = @NodeID AND UserID = @UserID
	) BEGIN
		UPDATE [dbo].[CN_ExpertiseReferrals]
			SET [Status] = @Status,
				SendDate = @SendDate
		WHERE ApplicationID = @ApplicationID AND 
			ReferrerUserID = @ReferrerUserID AND NodeID = @NodeID AND UserID = @UserID
	END
	ELSE BEGIN
		INSERT INTO [dbo].[CN_ExpertiseReferrals](
			ApplicationID,
			ReferrerUserID,
			NodeID,
			UserID,
			[Status],
			SendDate
		)
		VALUES(
			@ApplicationID,
			@ReferrerUserID,
			@NodeID,
			@UserID,
			@Status,
			@SendDate
		)
	END
	
	IF @@ROWCOUNT <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	DECLARE @_Result int
	
	EXEC [dbo].[CN_P_CalculateSocialExpertise] @ApplicationID, @NodeID, @UserID, 
		@DefaultMinAcceptableReferralsCount, @DefaultMinAcceptableConfirmsPercentage, 
		@_Result output
		
	IF @_Result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END	
	
	SELECT 1
COMMIT TRANSACTION

GO

/*
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_IAmExpert]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_IAmExpert]
GO

CREATE PROCEDURE [dbo].[CN_IAmExpert]
	@ApplicationID							uniqueidentifier,
	@UserID									uniqueidentifier,
	@ExpertiseDomain						nvarchar(255),
	@Now									datetime,
	@DefaultMinAcceptableReferralsCount		int,
	@DefaultMinAcceptableConfirmsPercentage int
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	SET @ExpertiseDomain = [dbo].[GFN_VerifyString](@ExpertiseDomain)
	
	DECLARE @NodeTypeID uniqueidentifier = [dbo].[CN_FN_GetExpertiseNodeTypeID](@ApplicationID)
	
	DECLARE @NodeID uniqueidentifier = (
		SELECT TOP(1) NodeID 
		FROM [dbo].[CN_Nodes] 
		WHERE ApplicationID = @ApplicationID AND 
			NodeTypeID = @NodeTypeID AND Name = @ExpertiseDomain
	)
	
	DECLARE @_Result int, @_ErrorMessage varchar(1000)
	
	IF @NodeID IS NULL BEGIN
		SET @NodeID = NEWID()
		
		EXEC [dbo].[CN_P_AddNode] @ApplicationID, @NodeID, NULL, @NodeTypeID, 
			NULL, NULL, NULL, @ExpertiseDomain, NULL, NULL, 0, @UserID, @Now, NULL, 
			NULL, NULL, @_Result output, @_ErrorMessage output
			
		IF @_Result <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	IF EXISTS(SELECT TOP(1) * FROM [dbo].[CN_Experts]
		WHERE NodeID = @NodeID AND UserID = @UserID) BEGIN
	
		EXEC [dbo].[CN_P_CalculateSocialExpertise] @ApplicationID, @NodeID, @UserID, 
			@DefaultMinAcceptableReferralsCount, @DefaultMinAcceptableConfirmsPercentage, 
			@_Result output
	END
	ELSE BEGIN
		INSERT INTO [dbo].[CN_Experts](
			ApplicationID,
			NodeID,
			UserID,
			Approved,
			ReferralsCount,
			ConfirmsPercentage,
			SocialApproved,
			UniqueID
		)
		VALUES(
			@ApplicationID,
			@NodeID,
			@UserID,
			0,
			0,
			0,
			0,
			NEWID()
		)
		
		SET @_Result = @@ROWCOUNT
	END
	
	IF @_Result <= 0 SELECT NULL
	ELSE SELECT @NodeID
COMMIT TRANSACTION

GO
*/


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_IAmNotExpert]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_IAmNotExpert]
GO

CREATE PROCEDURE [dbo].[CN_IAmNotExpert]
	@ApplicationID	uniqueidentifier,
	@UserID			uniqueidentifier,
	@NodeID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[CN_Experts]
		SET SocialApproved = NULL
	WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID AND UserID = @UserID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetReferralsCount]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetReferralsCount]
GO

CREATE PROCEDURE [dbo].[CN_GetReferralsCount]
	@ApplicationID	uniqueidentifier,
	@UserID			uniqueidentifier,
	@NodeID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(1) ReferralsCount
	FROM [dbo].[CN_Experts]
	WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID AND UserID = @UserID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetExpertiseSuggestions]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetExpertiseSuggestions]
GO

CREATE PROCEDURE [dbo].[CN_GetExpertiseSuggestions]
	@ApplicationID	uniqueidentifier,
	@UserID			uniqueidentifier,
	@Count			int,
	@LowerBoundary	int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF @Count IS NULL SET @Count = 10
	/*
	SELECT TOP(@Count)
		ND.NodeID AS NodeID,
		ND.NodeName AS NodeName,
		ND.TypeName AS NodeType,
		Ref.UserID AS ExpertUserID,
		UN.UserName AS ExpertUserName,
		UN.FirstName AS ExpertFirstName,
		UN.LastName AS ExpertLastName
	FROM
		(
			SELECT ROW_NUMBER() OVER(ORDER BY ER.ReferralsCount) AS ID,
				   ReferrerUserID, UserID, NodeID
			FROM [dbo].[CN_View_ExpertiseReferrals] AS ER
			WHERE ER.ApplicationID = @ApplicationID AND ReferrerUserID = @UserID
		) AS Ref
		INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.NodeID = Ref.NodeID
		INNER JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND UN.UserID = Ref.UserID
	WHERE @LowerBoundary IS NULL OR Ref.ID > @LowerBoundary
	*/
END

GO

/*     end of Expert related procedures     */


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_SuggestNodeRelations]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_SuggestNodeRelations]
GO

CREATE PROCEDURE [dbo].[CN_SuggestNodeRelations]
	@ApplicationID		uniqueidentifier,
	@UserID				uniqueidentifier,
	@NodeTypeID			uniqueidentifier,
	@RelatedNodeTypeID	uniqueidentifier,
	@Count				int,
	@Now				datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeIDs KeyLessGuidTableType
	
	INSERT INTO @NodeIDs (Value)
	SELECT TOP(@Count) Ref.NodeID
	FROM (
			SELECT ISNULL(EX.NodeID, R.NodeID) AS NodeID,
				((CASE
					WHEN EX.NodeID IS NOT NULL AND R.NodeID IS NOT NULL THEN 2
					ELSE 1
				END) * (
					(CASE 
						WHEN (EX.[Rank] IS NULL OR EX.[Rank] = 0) THEN 1 
						ELSE EX.[Rank] 
					END) + 
					ISNULL(R.[Rank], 0))) AS [Rank]
			FROM (
					SELECT EX.NodeID,
						((ISNULL(EX.ConfirmsPercentage, 0) / CAST(100 AS float)) * 
						 ISNULL(EX.ReferralsCount, 0)) AS [Rank]
					FROM [dbo].[CN_Experts] AS EX
						INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
						ON ND.ApplicationID = @ApplicationID AND ND.NodeID = EX.NodeID
						LEFT JOIN [dbo].[CN_NodeCreators] AS NC
						ON NC.ApplicationID = @ApplicationID AND 
							NC.NodeID = EX.NodeID AND NC.UserID = @UserID AND NC.Deleted = 0
					WHERE EX.ApplicationID = @ApplicationID AND EX.UserID = @UserID AND 
						(EX.Approved = 1 OR EX.SocialApproved = 1) AND
						(@RelatedNodeTypeID IS NULL OR ND.NodeTypeID = @RelatedNodeTypeID) AND
						NC.NodeID IS NULL AND ND.Deleted = 0 AND ND.TypeDeleted = 0
				) AS EX
				FULL OUTER JOIN (
					SELECT RN.NodeID, 
						(AVG(
							CASE
								WHEN DATEDIFF(DAY, KW.CreationDate, @Now) < 365
									THEN 365 - DATEDIFF(DAY, KW.CreationDate, @Now)
								ELSE 0
							END
						) / CAST(365 AS float)) * COUNT(RN.NodeID) AS [Rank]
					FROM [dbo].[KW_View_Knowledges] AS KW
						INNER JOIN [dbo].[CN_View_OutRelatedNodes] AS RN
						ON RN.ApplicationID = @ApplicationID AND RN.NodeID = KW.KnowledgeID
						INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
						ON ND.ApplicationID = @ApplicationID AND ND.NodeID = RN.NodeID
					WHERE KW.ApplicationID = @ApplicationID AND 
						KW.CreatorUserID = @UserID AND KW.Deleted = 0 AND 
						(@RelatedNodeTypeID IS NULL OR ND.NodeTypeID = @RelatedNodeTypeID) AND
						ND.Deleted = 0 AND ND.TypeDeleted = 0
					GROUP BY RN.NodeID
				) AS R
				ON EX.NodeID = R.NodeID
		) AS Ref
	WHERE Ref.[Rank] > 0
	ORDER BY Ref.[Rank] DESC
	
	IF (SELECT COUNT(*) FROM @NodeIDs) = 0 BEGIN
		INSERT INTO @NodeIDs (Value)
		SELECT TOP(@Count) NodeID
		FROM [dbo].[CN_Nodes]
		WHERE ApplicationID = @ApplicationID AND 
			(@RelatedNodeTypeID IS NULL OR NodeTypeID = @RelatedNodeTypeID) AND Deleted = 0
	END
	
	EXEC [dbo].[CN_P_GetNodesByIDs] @ApplicationID, @NodeIDs, NULL, NULL
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_SuggestNodeTypesForRelations]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_SuggestNodeTypesForRelations]
GO

CREATE PROCEDURE [dbo].[CN_SuggestNodeTypesForRelations]
	@ApplicationID	uniqueidentifier,
	@UserID			uniqueidentifier,
	@NodeTypeID		uniqueidentifier,
	@Count			int,
	@Now			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @NodeTypeIDs KeyLessGuidTableType
	
	INSERT INTO @NodeTypeIDs (Value)
	SELECT TOP(@Count) Ref.ID
	FROM (
			SELECT ND.NodeTypeID AS ID, SUM(Ref.[Rank]) AS [Rank]
			FROM (
					SELECT ISNULL(EX.NodeID, R.NodeID) AS NodeID,
						((CASE
							WHEN EX.NodeID IS NOT NULL AND R.NodeID IS NOT NULL THEN 2
							ELSE 1
						END) * (
							(CASE 
								WHEN (EX.[Rank] IS NULL OR EX.[Rank] = 0) THEN 1 
								ELSE EX.[Rank] 
							END) + 
							ISNULL(R.[Rank], 0))) AS [Rank]
					FROM (
							SELECT EX.NodeID,
								((ISNULL(EX.ConfirmsPercentage, 0) / CAST(100 AS float)) * 
								 ISNULL(EX.ReferralsCount, 0)) AS [Rank]
							FROM [dbo].[CN_Experts] AS EX
								LEFT JOIN [dbo].[CN_NodeCreators] AS NC
								ON NC.ApplicationID = @ApplicationID AND
									NC.NodeID = EX.NodeID AND NC.UserID = @UserID AND 
									NC.Deleted = 0
							WHERE EX.ApplicationID = @ApplicationID AND EX.UserID = @UserID AND 
								(EX.Approved = 1 OR EX.SocialApproved = 1) AND
								NC.NodeID IS NULL
						) AS EX
						FULL OUTER JOIN (
							SELECT RN.NodeID, 
								(AVG(
									CASE
										WHEN DATEDIFF(DAY, KW.CreationDate, @Now) < 365
											THEN 365 - DATEDIFF(DAY, KW.CreationDate, @Now)
										ELSE 0
									END
								) / CAST(365 AS float)) * COUNT(RN.NodeID) AS [Rank]
							FROM [dbo].[KW_View_Knowledges] AS KW
								INNER JOIN [dbo].[CN_View_OutRelatedNodes] AS RN
								ON RN.ApplicationID = @ApplicationID AND 
									RN.NodeID = KW.KnowledgeID
							WHERE KW.ApplicationID = @ApplicationID AND 
								KW.CreatorUserID = @UserID AND KW.Deleted = 0
							GROUP BY RN.NodeID
						) AS R
						ON EX.NodeID = R.NodeID
				) AS Ref
				INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
				ON ND.ApplicationID = @ApplicationID AND ND.NodeID = Ref.NodeID
			WHERE Ref.[Rank] > 0 AND ND.Deleted = 0 AND ND.TypeDeleted = 0
			GROUP BY ND.NodeTypeID
		) AS Ref
	ORDER BY Ref.[Rank] DESC
	
	IF (SELECT COUNT(*) FROM @NodeTypeIDs) = 0 BEGIN
		INSERT INTO @NodeTypeIDs (Value)
		SELECT TOP(10) NT.NodeTypeID
		FROM [dbo].[CN_NodeTypes] AS NT
			LEFT JOIN [dbo].[CN_Extensions] AS X
			ON X.ApplicationID = @ApplicationID AND X.Extension = N'Browser'
		WHERE NT.ApplicationID = @ApplicationID
		ORDER BY (CASE WHEN X.OwnerID IS NULL THEN 0 ELSE 1 END) DESC
	END
	
	EXEC [dbo].[CN_P_GetNodeTypesByIDs] @ApplicationID, @NodeTypeIDs
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_SuggestSimilarNodes]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_SuggestSimilarNodes]
GO

CREATE PROCEDURE [dbo].[CN_SuggestSimilarNodes]
	@ApplicationID	uniqueidentifier,
	@NodeID			uniqueidentifier,
	@Count			int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(ISNULL(@Count, 20)) Ref.*
	FROM (
			SELECT	IDs.NodeID, 
					CAST(((8 * SUM(IDs.Tags)) + (5 * SUM(IDs.Relations)) + 
						(4 * SUM(IDs.Experts)) + (1 * SUM(IDs.Favorites))) AS float) AS [Rank],
					CAST((CASE WHEN SUM(IDs.Tags) > 0 THEN 1 ELSE 0 END) AS bit) AS Tags,
					CAST((CASE WHEN SUM(IDs.Favorites) > 0 THEN 1 ELSE 0 END) AS bit) AS Favorites,
					CAST((CASE WHEN SUM(IDs.Relations) > 0 THEN 1 ELSE 0 END) AS bit) AS Relations,
					CAST((CASE WHEN SUM(IDs.Experts) > 0 THEN 1 ELSE 0 END) AS bit) AS Experts
			FROM (
					-- tagged together
					SELECT	Dst.TaggedID AS NodeID, 
							COUNT(Dst.ContextID) AS Tags,
							CAST(0 AS int) AS Favorites,
							CAST(0 AS int) AS Relations,
							CAST(0 AS int) AS Experts
					FROM [dbo].[RV_TaggedItems] AS Ref
						INNER JOIN [dbo].[RV_TaggedItems] AS Dst
						ON Dst.ApplicationID = @ApplicationID AND Dst.ContextID = Ref.ContextID
					WHERE Ref.ApplicationID = @ApplicationID AND 
						Ref.TaggedID = @NodeID AND Dst.TaggedType = N'Node'
					GROUP BY Dst.TaggedID
					-- end of tagged together

					UNION ALL

					-- favorites
					SELECT	Dst.NodeID, 
							0 AS Tags,
							COUNT(Dst.UserID) AS Favorites,
							0 AS Relations,
							0 AS Experts
					FROM [dbo].[CN_NodeLikes] AS Ref
						INNER JOIN [dbo].[CN_NodeLikes] AS Dst
						ON Dst.ApplicationID = @ApplicationID AND Dst.UserID = Ref.UserID
					WHERE Ref.ApplicationID = @ApplicationID AND 
						Ref.NodeID = @NodeID AND Ref.Deleted = 0 AND Dst.Deleted = 0
					GROUP BY Dst.NodeID
					-- end of favorites

					UNION ALL

					-- related nodes
					SELECT	Dst.RelatedNodeID AS NodeID, 
							0 AS Tags,
							0 AS Favorites,
							COUNT(Dst.NodeID) AS Relations,
							0 AS Experts
					FROM [dbo].[CN_View_OutRelatedNodes] AS Ref
						INNER JOIN [dbo].[CN_View_OutRelatedNodes] AS Dst
						ON Dst.ApplicationID = @ApplicationID AND Dst.NodeID = Ref.NodeID
					WHERE Ref.ApplicationID = @ApplicationID AND Ref.RelatedNodeID = @NodeID
					GROUP BY Dst.RelatedNodeID
					-- end of related nodes

					UNION ALL

					-- experts
					SELECT	Dst.NodeID,
							0 AS Tags,
							0 AS Favorites,
							0 AS Relations,
							COUNT(Dst.UserID) AS Experts
					FROM [dbo].[CN_View_Experts] AS Ref
						INNER JOIN [dbo].[CN_View_Experts] AS Dst
						ON Dst.ApplicationID = @ApplicationID AND Dst.UserID = Ref.UserID
					WHERE Ref.ApplicationID = @ApplicationID AND Ref.NodeID = @NodeID
					GROUP BY Dst.NodeID
					-- end of experts
				) AS IDs
			GROUP BY IDs.NodeID
		) AS Ref
		INNER JOIN [dbo].[CN_Nodes] AS ND
		ON ND.ApplicationID = @ApplicationID AND 
			ND.NodeID = Ref.NodeID AND ND.Deleted = 0
	WHERE Ref.NodeID <> @NodeID
	ORDER BY Ref.[Rank] DESC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_SuggestKnowledgableUsers]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_SuggestKnowledgableUsers]
GO

CREATE PROCEDURE [dbo].[CN_SuggestKnowledgableUsers]
	@ApplicationID	uniqueidentifier,
	@NodeID			uniqueidentifier,
	@Count			int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(ISNULL(@Count, 20)) Ref.*
	FROM (
			SELECT	IDs.UserID, 
					CAST(((8 * SUM(IDs.Expert)) + (8 * SUM(IDs.Contributor)) + 
						(4 * SUM(IDs.WikiEditor)) + (4 * SUM(IDs.Member)) + 
						(2 * SUM(IDs.ExpertOfRelatedNode)) + 
						(2 * SUM(IDs.ContributorOfRelatedNode)) + 
						(1 * SUM(IDs.MemberOfRelatedNode))) AS float) AS [Rank],
					CAST((CASE WHEN SUM(IDs.Expert) > 0 THEN 1 ELSE 0 END) AS bit) AS Expert,
					CAST((CASE WHEN SUM(IDs.Contributor) > 0 THEN 1 ELSE 0 END) AS bit) AS Contributor,
					CAST((CASE WHEN SUM(IDs.WikiEditor) > 0 THEN 1 ELSE 0 END) AS bit) AS WikiEditor,
					CAST((CASE WHEN SUM(IDs.Member) > 0 THEN 1 ELSE 0 END) AS bit) AS Member,
					CAST((CASE WHEN SUM(IDs.ExpertOfRelatedNode) > 0 THEN 1 ELSE 0 END) AS bit) AS ExpertOfRelatedNode,
					CAST((CASE WHEN SUM(IDs.ContributorOfRelatedNode) > 0 THEN 1 ELSE 0 END) AS bit) AS ContributorOfRelatedNode,
					CAST((CASE WHEN SUM(IDs.MemberOfRelatedNode) > 0 THEN 1 ELSE 0 END) AS bit) AS MemberOfRelatedNode
			FROM (
					-- experts
					SELECT	Dst.UserID, 
							CAST(1 AS int) AS Expert,
							CAST(0 AS int) AS Contributor,
							CAST(0 AS int) AS WikiEditor,
							CAST(0 AS int) AS Member,
							CAST(0 AS int) AS ExpertOfRelatedNode,
							CAST(0 AS int) AS ContributorOfRelatedNode,
							CAST(0 AS int) AS MemberOfRelatedNode
					FROM [dbo].[CN_View_Experts] AS Dst
					WHERE Dst.ApplicationID = @ApplicationID AND Dst.NodeID = @NodeID
					-- end of experts

					UNION ALL

					-- contributors
					SELECT	Dst.UserID, 
							0 AS Expert,
							1 AS Contributor,
							0 AS WikiEditor,
							0 AS Member,
							0 AS ExpertOfRelatedNode,
							0 AS ContributorOfRelatedNode,
							0 AS MemberOfRelatedNode
					FROM [dbo].[CN_NodeCreators] AS Dst
					WHERE Dst.ApplicationID = @ApplicationID AND 
						Dst.NodeID = @NodeID AND Dst.Deleted = 0
					-- end of contributors

					UNION ALL

					-- wiki editors
					SELECT	C.UserID, 
							0 AS Expert,
							0 AS Contributor,
							COUNT(DISTINCT P.ParagraphID) AS WikiEditor,
							0 AS Member,
							0 AS ExpertOfRelatedNode,
							0 AS ContributorOfRelatedNode,
							0 AS MemberOfRelatedNode
					FROM [dbo].[WK_Titles] AS T
						INNER JOIN [dbo].[WK_Paragraphs] AS P
						ON P.ApplicationID = @ApplicationID AND P.TitleID = T.TitleID
						INNER JOIN [dbo].[WK_Changes] AS C
						ON C.ApplicationID = @ApplicationID AND 
							C.ParagraphID = P.ParagraphID AND C.Applied = 1
					WHERE T.ApplicationID = @ApplicationID AND T.OwnerID = @NodeID
					GROUP BY C.UserID
					-- end of wiki editors
					
					UNION ALL
					
					-- experts
					SELECT	Dst.UserID, 
							0 AS Expert,
							0 AS Contributor,
							0 AS WikiEditor,
							1 AS Member,
							0 AS ExpertOfRelatedNode,
							0 AS ContributorOfRelatedNode,
							0 AS MemberOfRelatedNode
					FROM [dbo].[CN_View_NodeMembers] AS Dst
					WHERE Dst.ApplicationID = @ApplicationID AND 
						Dst.NodeID = @NodeID AND Dst.IsPending = 0
					-- end of experts

					UNION ALL

					-- experts of related nodes
					SELECT	Dst.UserID, 
							0 AS Expert,
							0 AS Contributor,
							0 AS WikiEditor,
							0 AS Member,
							COUNT(Dst.NodeID) AS ExpertOfRelatedNode,
							0 AS ContributorOfRelatedNode,
							0 AS MemberOfRelatedNode
					FROM [dbo].[CN_View_OutRelatedNodes] AS Ref
						INNER JOIN [dbo].[CN_View_Experts] AS Dst
						ON Dst.ApplicationID = @ApplicationID AND Dst.NodeID = Ref.RelatedNodeID
					WHERE Ref.ApplicationID = @ApplicationID AND Ref.NodeID = @NodeID
					GROUP BY Dst.UserID
					-- end of experts of related nodes

					UNION ALL

					-- contributors of related nodes
					SELECT	Dst.UserID, 
							0 AS Expert,
							0 AS Contributor,
							0 AS WikiEditor,
							0 AS Member,
							0 AS ExpertOfRelatedNode,
							COUNT(Dst.NodeID) AS ContributorOfRelatedNode,
							0 AS MemberOfRelatedNode
					FROM [dbo].[CN_View_OutRelatedNodes] AS Ref
						INNER JOIN [dbo].[CN_NodeCreators] AS Dst
						ON Dst.ApplicationID = @ApplicationID AND Dst.NodeID = Ref.RelatedNodeID
					WHERE Ref.ApplicationID = @ApplicationID AND Ref.NodeID = @NodeID
					GROUP BY Dst.UserID
					-- end of contributors of related nodes

					UNION ALL

					-- members of related nodes
					SELECT	Dst.UserID, 
							0 AS Expert,
							0 AS Contributor,
							0 AS WikiEditor,
							0 AS Member,
							0 AS ExpertOfRelatedNode,
							0 AS ContributorOfRelatedNode,
							COUNT(Dst.NodeID) AS MemberOfRelatedNode
					FROM [dbo].[CN_View_OutRelatedNodes] AS Ref
						INNER JOIN [dbo].[CN_View_NodeMembers] AS Dst
						ON Dst.ApplicationID = @ApplicationID AND Dst.NodeID = Ref.RelatedNodeID
					WHERE Ref.ApplicationID = @ApplicationID AND 
						Ref.NodeID = @NodeID AND Dst.IsPending = 0
					GROUP BY Dst.UserID
					-- end of members of related nodes
				) AS IDs
			GROUP BY IDs.UserID
		) AS Ref
		INNER JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND 
			UN.UserID = Ref.UserID AND UN.IsApproved = 1
	ORDER BY Ref.[Rank] DESC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetExistingNodeIDs]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetExistingNodeIDs]
GO

CREATE PROCEDURE [dbo].[CN_GetExistingNodeIDs]
	@ApplicationID	uniqueidentifier,
	@strNodeIDs		varchar(max),
	@delimiter		char,
	@Searchable		bit,
	@NoContent		bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT	ND.NodeID,
			ND.CreationDate,
			ND.CreatorUserID,
			UN.UserName AS CreatorUserName,
			UN.FirstName AS CreatorFirstName,
			UN.LastName AS CreatorLastName,
			UN.AvatarName AS CreatorAvatarName,
			UN.UseAvatar AS CreatorUseAvatar
	FROM [dbo].[GFN_StrToGuidTable](@strNodeIDs, @delimiter) AS IDs
		INNER JOIN [dbo].[CN_Nodes] AS ND
		ON ND.NodeID = IDs.Value
		LEFT JOIN [dbo].[CN_Services] AS S
		ON S.ApplicationID = @ApplicationID AND S.NodeTypeID = ND.NodeTypeID AND S.Deleted = 0
		LEFT JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND UN.UserID = ND.CreatorUserID
	WHERE ND.ApplicationID = @ApplicationID AND ND.Deleted = 0 AND 
		(@Searchable IS NULL OR ISNULL(ND.Searchable, 1) = @Searchable) AND
		(@NoContent IS NULL OR ISNULL(S.NoContent, 0) = @NoContent)
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetExistingNodeTypeIDs]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetExistingNodeTypeIDs]
GO

CREATE PROCEDURE [dbo].[CN_GetExistingNodeTypeIDs]
	@ApplicationID	uniqueidentifier,
	@strNodeTypeIDs	varchar(max),
	@delimiter		char,
	@NoContent		bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT NT.NodeTypeID AS ID
	FROM [dbo].[GFN_StrToGuidTable](@strNodeTypeIDs, @delimiter) AS IDs
		INNER JOIN [dbo].[CN_NodeTypes] AS NT
		ON NT.NodeTypeID = IDs.Value
		LEFT JOIN [dbo].[CN_Services] AS S
		ON S.ApplicationID = @ApplicationID AND S.NodeTypeID = NT.NodeTypeID AND S.Deleted = 0
	WHERE NT.ApplicationID = @ApplicationID AND NT.Deleted = 0 AND
		(@NoContent IS NULL OR ISNULL(S.NoContent, 0) = @NoContent)
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetNodeInfo]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetNodeInfo]
GO

CREATE PROCEDURE [dbo].[CN_GetNodeInfo]
	@ApplicationID		uniqueidentifier,
	@strNodeIDs			varchar(max),
    @delimiter			char,
    @CurrentUserID		uniqueidentifier,
    @Tags				bit,
    @Description		bit,
    @Creator			bit,
    @ContributorsCount	bit,
    @LikesCount			bit,
    @VisitsCount		bit,
    @ExpertsCount		bit,
    @MembersCount		bit,
    @ChildsCount		bit,
    @RelatedNodesCount	bit,
    @LikeStatus			bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeIDs GuidTableType
	
	INSERT INTO @NodeIDs
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strNodeIDs, @delimiter) AS Ref
	
	SELECT	N.Value AS NodeID,
			ND.NodeTypeID,
			(CASE WHEN @Tags = 1 THEN ND.Tags ELSE NULL END) AS Tags,
			(CASE WHEN @Description = 1 THEN ND.[Description] ELSE NULL END) AS [Description],
			UN.UserID AS CreatorUserID,
			UN.UserName AS CreatorUserName,
			UN.FirstName AS CreatorFirstName,
			UN.LastName AS CreatorLastName,
			UN.AvatarName AS CreatorAvatarName,
			UN.UseAvatar AS CreatorUseAvatar,
			UN.NationalID AS CreatorNationalID,
			UN.PersonnelID AS CreatorPersonnelID,
			NC.ContributorsCount,
			NL.LikesCount,
			IV.VisitsCount,
			EX.ExpertsCount,
			NM.MembersCount,
			CH.ChildsCount,
			RL.RelatedNodesCount,
			CAST((CASE WHEN NLikes.NodeID IS NULL THEN 0 ELSE 1 END) AS bit) AS LikeStatus
	FROM @NodeIDs AS N
		INNER JOIN [dbo].[CN_Nodes] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.NodeID = N.Value
		LEFT JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND @Creator = 1 AND UN.UserID = ND.CreatorUserID
		LEFT JOIN (
			SELECT NC.NodeID, COUNT(NC.UserID) AS ContributorsCount
			FROM @NodeIDs AS Ref
				INNER JOIN [dbo].[CN_NodeCreators] AS NC
				ON NC.NodeID = Ref.Value
			WHERE NC.ApplicationID = @ApplicationID AND NC.Deleted = 0
			GROUP BY NC.NodeID
		) AS NC
		ON @ContributorsCount = 1 AND NC.NodeID = N.Value
		LEFT JOIN (
			SELECT NL.NodeID, COUNT(NL.UserID) AS LikesCount
			FROM @NodeIDs AS Ref
				INNER JOIN [dbo].[CN_NodeLikes] AS NL
				ON NL.NodeID = Ref.Value
			WHERE NL.ApplicationID = @ApplicationID AND NL.Deleted = 0
			GROUP BY NL.NodeID
		) AS NL
		ON @LikesCount = 1 AND NL.NodeID = N.Value
		LEFT JOIN (
			SELECT IV.ItemID, COUNT(IV.UserID) AS VisitsCount
			FROM @NodeIDs AS Ref
				INNER JOIN [dbo].[USR_ItemVisits] AS IV
				ON IV.ApplicationID = @ApplicationID AND IV.ItemID = Ref.Value
			GROUP BY IV.ItemID
		) AS IV
		ON @VisitsCount = 1 AND IV.ItemID = N.Value
		LEFT JOIN (
			SELECT EX.NodeID, COUNT(EX.UserID) AS ExpertsCount
			FROM @NodeIDs AS Ref
				INNER JOIN [dbo].[CN_View_Experts] AS EX
				ON EX.ApplicationID = @ApplicationID AND EX.NodeID = Ref.Value
			GROUP BY EX.NodeID
		) AS EX
		ON @ExpertsCount = 1 AND EX.NodeID = N.Value
		LEFT JOIN (
			SELECT NM.NodeID, COUNT(NM.UserID) AS MembersCount
			FROM @NodeIDs AS Ref
				INNER JOIN [dbo].[CN_View_NodeMembers] AS NM
				ON NM.ApplicationID = @ApplicationID AND NM.NodeID = Ref.Value AND
					NM.IsPending = 0
			GROUP BY NM.NodeID
		) AS NM
		ON @MembersCount = 1 AND NM.NodeID = N.Value
		LEFT JOIN (
			SELECT CH.ParentNodeID AS NodeID, COUNT(CH.NodeID) AS ChildsCount
			FROM @NodeIDs AS Ref
				INNER JOIN [dbo].[CN_Nodes] AS CH
				ON CH.ParentNodeID = Ref.Value
			WHERE CH.ApplicationID = @ApplicationID AND CH.Deleted = 0
			GROUP BY CH.ParentNodeID
		) AS CH
		ON @ChildsCount = 1 AND CH.NodeID = N.Value
		LEFT JOIN (
			SELECT RL.NodeID, COUNT(DISTINCT RL.RelatedNodeID) AS RelatedNodesCount
			FROM (
					SELECT InR.NodeID, InR.RelatedNodeID, InR.PropertyID
					FROM @NodeIDs AS Ref
						INNER JOIN [dbo].[CN_View_InRelatedNodes] AS InR
						ON InR.ApplicationID = @ApplicationID AND InR.NodeID = Ref.Value
					
					UNION
					
					SELECT OuR.NodeID, Our.RelatedNodeID, OuR.PropertyID
					FROM @NodeIDs AS Ref
						INNER JOIN [dbo].[CN_View_OutRelatedNodes] AS OuR
						ON OuR.ApplicationID = @ApplicationID AND OuR.NodeID = Ref.Value
				) AS RL
			GROUP BY RL.NodeID
		) AS RL
		ON @RelatedNodesCount = 1 AND RL.NodeID = N.Value
		LEFT JOIN [dbo].[CN_NodeLikes] AS NLikes
		ON NLikes.ApplicationID = @ApplicationID AND 
			@CurrentUserID IS NOT NULL AND @LikeStatus = 1 AND 
			NLikes.NodeID = N.Value AND NLikes.UserID = @CurrentUserID AND NLikes.Deleted = 0
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_InitializeExtensions]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_InitializeExtensions]
GO

CREATE PROCEDURE [dbo].[CN_InitializeExtensions]
	@ApplicationID			uniqueidentifier,
	@OwnerID				uniqueidentifier,
	@strEnabledExtensions	varchar(max),
	@strDisabledExtensions	varchar(max),
	@delimiter				char,
	@CreatorUserID			uniqueidentifier,
	@CreationDate			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @SequenceNumber int = ISNULL(
			(
				SELECT MAX(SequenceNumber) 
				FROM [dbo].[CN_Extensions] 
				WHERE ApplicationID = @ApplicationID AND OwnerID = @OwnerID
			), 0
		)
	
	DECLARE @Extensions Table (ID int IDENTITY(1, 1) primary key clustered, 
		[Disabled] bit, Ext varchar(50))
	
	INSERT INTO @Extensions (Ext, [Disabled])
	SELECT Ref.Value, [Disabled]
	FROM (
			SELECT Ref.Value, CAST(0 AS bit) AS [Disabled]
			FROM [dbo].[GFN_StrToStringTable](@strEnabledExtensions, @delimiter) AS Ref
			
			UNION ALL
			
			SELECT Ref.Value, CAST(1 AS bit)
			FROM [dbo].[GFN_StrToStringTable](@strDisabledExtensions, @delimiter) AS Ref
		) AS Ref
	WHERE Ref.Value NOT IN (
			SELECT Ex.Extension
			FROM [dbo].[CN_Extensions] AS Ex
			WHERE Ex.ApplicationID = @ApplicationID AND Ex.OwnerID = @OwnerID
		)
	
	IF (SELECT COUNT(*) FROM @Extensions) > 0 BEGIN
		INSERT INTO [dbo].[CN_Extensions](
			ApplicationID,
			OwnerID,
			Extension,
			SequenceNumber,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		SELECT @ApplicationID,
			   @OwnerID, 
			   Ex.Ext,
			   Ex.ID + @SequenceNumber,
			   @CreatorUserID,
			   @CreationDate,
			   Ex.[Disabled]
		FROM @Extensions AS Ex
		
		SELECT @@ROWCOUNT
	END
	ELSE SELECT 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_EnableDisableExtension]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_EnableDisableExtension]
GO

CREATE PROCEDURE [dbo].[CN_EnableDisableExtension]
	@ApplicationID	uniqueidentifier,
	@OwnerID		uniqueidentifier,
	@Extension		varchar(50),
	@Disable		bit,
	@CreatorUserID	uniqueidentifier,
	@CreationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[CN_Extensions]
		SET Deleted = ISNULL(@Disable, 0),
			LastModifierUserID = @CreatorUserID,
			LastModificationDate = @CreationDate
	WHERE ApplicationID = @ApplicationID AND OwnerID = @OwnerID AND Extension = @Extension
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_SetExtensionTitle]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_SetExtensionTitle]
GO

CREATE PROCEDURE [dbo].[CN_SetExtensionTitle]
	@ApplicationID			uniqueidentifier,
	@OwnerID				uniqueidentifier,
	@Extension				varchar(50),
	@Title					nvarchar(100),
	@LastModifierUserID		uniqueidentifier,
	@LastModificationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[CN_Extensions]
		SET Title = [dbo].[GFN_VerifyString](@Title),
			LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate
	WHERE ApplicationID = @ApplicationID AND OwnerID = @OwnerID AND Extension = @Extension
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_MoveExtension]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_MoveExtension]
GO

CREATE PROCEDURE [dbo].[CN_MoveExtension]
	@ApplicationID	uniqueidentifier,
	@OwnerID		uniqueidentifier,
	@Extension		varchar(50),
	@MoveDown		bit
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE @SequenceNo int
	
	SELECT @SequenceNo = SequenceNumber
	FROM [dbo].[CN_Extensions]
	WHERE ApplicationID = @ApplicationID AND OwnerID = @OwnerID AND Extension = @Extension
		
	DECLARE @OtherExtension varchar(50)
	DECLARE @OtherSequenceNumber int
	
	IF @MoveDown = 1 BEGIN
		SELECT TOP(1) @OtherExtension = Extension, @OtherSequenceNumber = SequenceNumber
		FROM [dbo].[CN_Extensions]
		WHERE ApplicationID = @ApplicationID AND 
			OwnerID = @OwnerID AND SequenceNumber > @SequenceNo
		ORDER BY SequenceNumber
	END
	ELSE BEGIN
		SELECT TOP(1) @OtherExtension = Extension, @OtherSequenceNumber = SequenceNumber
		FROM [dbo].[CN_Extensions]
		WHERE ApplicationID = @ApplicationID AND 
			OwnerID = @OwnerID AND SequenceNumber < @SequenceNo
		ORDER BY SequenceNumber DESC
	END
	
	IF @OtherExtension IS NULL BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	UPDATE [dbo].[CN_Extensions]
		SET SequenceNumber = @OtherSequenceNumber
	WHERE ApplicationID = @ApplicationID AND OwnerID = @OwnerID AND Extension = @Extension
	
	IF @@ROWCOUNT <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	UPDATE [dbo].[CN_Extensions]
		SET SequenceNumber = @SequenceNo
	WHERE ApplicationID = @ApplicationID AND 
		OwnerID = @OwnerID AND Extension = @OtherExtension
	
	IF @@ROWCOUNT <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	SELECT 1
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_SaveExtensions]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_SaveExtensions]
GO

CREATE PROCEDURE [dbo].[CN_SaveExtensions]
	@ApplicationID	uniqueidentifier,
	@OwnerID		uniqueidentifier,
	@ExtensionsTemp	CNExtensionTableType readonly,
	@CurrentUserID	uniqueidentifier,
	@Now			datetime
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Extensions CNExtensionTableType
	INSERT INTO @Extensions SELECT * FROM @ExtensionsTemp
	
	
	DECLARE @TBL TABLE (Extension varchar(50), Title nvarchar(100), SequenceNumber int IDENTITY(1, 1), Deleted bit)
	
	INSERT INTO @TBL (Extension, Title, Deleted)
	SELECT X.Extension, X.Title, ISNULL(X.[Disabled], 0)
	FROM @Extensions AS X
	
	
	UPDATE X
	SET Title = T.Title,
		Deleted = CASE WHEN T.Extension IS NULL THEN 1 ELSE T.Deleted END,
		LastModifierUserID = @CurrentUserID,
		LastModificationDate = @Now
	FROM [dbo].[CN_Extensions] AS X
		LEFT JOIN @TBL AS T
		ON T.Extension = X.Extension
	WHERE X.ApplicationID = @ApplicationID AND X.OwnerID = @OwnerID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetExtensions]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetExtensions]
GO

CREATE PROCEDURE [dbo].[CN_GetExtensions]
	@ApplicationID	uniqueidentifier,
	@OwnerID		uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeTypeID uniqueidentifier = (
		SELECT TOP(1) NodeTypeID
		FROM [dbo].[CN_Nodes]
		WHERE ApplicationID = @ApplicationID AND NodeID = @OwnerID
	)
	
	IF @NodeTypeID IS NOT NULL SET @OwnerID = @NodeTypeID
	
	SELECT OwnerID,
		   Extension,
		   Title,
		   Deleted AS [Disabled]
	FROM [dbo].[CN_Extensions]
	WHERE ApplicationID = @ApplicationID AND OwnerID = @OwnerID
	ORDER BY SequenceNumber
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_HasExtension]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_HasExtension]
GO

CREATE PROCEDURE [dbo].[CN_HasExtension]
	@ApplicationID	uniqueidentifier,
	@OwnerID		uniqueidentifier,
	@Extension		varchar(50)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeTypeID uniqueidentifier = (
		SELECT TOP(1) NodeTypeID
		FROM [dbo].[CN_Nodes]
		WHERE ApplicationID = @ApplicationID AND NodeID = @OwnerID
	)
	
	IF @NodeTypeID IS NOT NULL SET @OwnerID = @NodeTypeID
	
	SELECT CAST(1 AS bit)
	FROM [dbo].[CN_Extensions]
	WHERE ApplicationID = @ApplicationID AND 
		OwnerID = @OwnerID AND Extension = @Extension AND Deleted = 0
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetNodeTypesWithExtension]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetNodeTypesWithExtension]
GO

CREATE PROCEDURE [dbo].[CN_GetNodeTypesWithExtension]
	@ApplicationID	uniqueidentifier,
	@strExtensions	varchar(max),
	@delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Extensions StringTableType
	
	INSERT INTO @Extensions (Value)
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToStringTable](@strExtensions, @delimiter) AS Ref
	
	DECLARE @NodeTypeIDs KeyLessGuidTableType
	
	INSERT INTO @NodeTypeIDs (Value)
	SELECT DISTINCT NT.NodeTypeID
	FROM @Extensions AS E
		INNER JOIN [dbo].[CN_Extensions] AS X
		ON X.ApplicationID = @ApplicationID AND X.Extension = E.Value AND X.Deleted = 0
		INNER JOIN [dbo].[CN_NodeTypes] AS NT
		ON NT.ApplicationID = @ApplicationID AND NT.NodeTypeID = X.OwnerID AND NT.Deleted = 0
		
	EXEC [dbo].[CN_P_GetNodeTypesByIDs] @ApplicationID, @NodeTypeIDs
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetIntellectualPropertiesCount]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetIntellectualPropertiesCount]
GO

CREATE PROCEDURE [dbo].[CN_GetIntellectualPropertiesCount]
	@ApplicationID	uniqueidentifier,
	@UserID			uniqueidentifier,
	@NodeTypeID		uniqueidentifier,
	@NodeID			uniqueidentifier,
	@AdditionalID	varchar(50),
	@CurrentUserID	uniqueidentifier,
	@IsDocument		bit,
	@LowerDateLimit	datetime,
	@UpperDateLimit	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF @NodeID IS NOT NULL SET @NodeTypeID = NULL
	IF @NodeID IS NOT NULL OR @AdditionalID = N'' SET @AdditionalID = NULL
	
	DECLARE @IsSystemAdmin bit = (SELECT [dbo].[GFN_IsSystemAdmin](@ApplicationID, @CurrentUserID))
	
	DECLARE @ServiceAdminIDs GuidTableType
	
	INSERT INTO @ServiceAdminIDs (Value)
	SELECT DISTINCT A.NodeTypeID
	FROM [dbo].[CN_ServiceAdmins] AS A
	WHERE A.ApplicationID = @ApplicationID AND A.UserID = @CurrentUserID AND A.Deleted = 0
	
	
	SELECT	X.NodeTypeID,
			MAX(X.NodeTypeAdditionalID) AS NodeTypeAdditionalID,
			MAX(X.TypeName) AS TypeName,
			COUNT(X.NodeID) AS NodesCount
	FROM (
			SELECT	ND.NodeID,
					CAST(MAX(CAST(ND.NodeTypeID AS varchar(50))) AS uniqueidentifier) AS NodeTypeID,
					MAX(ND.TypeAdditionalID) AS NodeTypeAdditionalID,
					MAX(ND.TypeName) AS TypeName,
					CAST(MAX(CAST(ND.Searchable AS int)) AS bit) AS Searchable,
					CAST(MAX(CAST(ND.HideCreators AS int)) AS bit) AS HideCreators,
					CAST(MAX(
						CASE 
							WHEN @CurrentUserID IS NOT NULL AND NC.UserID = @CurrentUserID THEN 1 
							ELSE 0 
						END
					) AS bit) AS CurUser,
					CAST(MAX(CASE WHEN NC.UserID = @UserID THEN 1 ELSE 0 END) AS bit) AS TheUser
			FROM [dbo].[CN_NodeCreators] AS NC
				INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
				ON ND.ApplicationID = @ApplicationID AND ND.NodeID = NC.NodeID
				LEFT JOIN [dbo].[CN_Services] AS S
				ON S.ApplicationID = @ApplicationID AND S.NodeTypeID = ND.NodeTypeID AND S.Deleted = 0
			WHERE NC.ApplicationID = @ApplicationID AND 
				(NC.UserID = @UserID OR (
					@CurrentUserID IS NOT NULL AND NC.UserID = @CurrentUserID
				)) AND 
				(@NodeID IS NULL OR ND.NodeID = @NodeID) AND
				(@NodeTypeID IS NULL OR ND.NodeTypeID = @NodeTypeID) AND 
				(@AdditionalID IS NULL OR ND.NodeAdditionalID = @AdditionalID) AND
				(@IsDocument IS NULL OR ISNULL(S.IsDocument, 0) = @IsDocument) AND
				(@LowerDateLimit IS NULL OR ND.CreationDate>= @LowerDateLimit) AND
				(@UpperDateLimit IS NULL OR ND.CreationDate <= @UpperDateLimit) AND
				NC.Deleted = 0 AND ND.Deleted = 0
			GROUP BY ND.NodeID
		) AS X
		LEFT JOIN @ServiceAdminIDs AS S
		ON S.Value = X.NodeTypeID
		LEFT JOIN [dbo].[CN_Services] AS SSS
		ON SSS.ApplicationID = @ApplicationID AND X.NodeTypeID = SSS.NodeTypeID AND SSS.Deleted = 0
	WHERE ISNULL(SSS.NoContent, 0) = 0 AND X.TheUser = 1 AND (@IsSystemAdmin = 1 OR S.Value IS NOT NULL OR 
		(X.Searchable = 1 AND X.HideCreators = 0) OR X.CurUser = 1)
	GROUP BY X.NodeTypeID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetIntellectualProperties]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetIntellectualProperties]
GO

CREATE PROCEDURE [dbo].[CN_GetIntellectualProperties]
	@ApplicationID	uniqueidentifier,
	@UserID			uniqueidentifier,
	@strNodeTypeIDs	varchar(max),
	@delimiter		char,
	@NodeID			uniqueidentifier,
	@AdditionalID	varchar(50),
	@CurrentUserID	uniqueidentifier,
	@SearchText		nvarchar(1000),
	@IsDocument		bit,
	@LowerDateLimit	datetime,
	@UpperDateLimit	datetime,
	@LowerBoundary	int,
	@Count			int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeTypeIDs GuidTableType
	
	INSERT INTO @NodeTypeIDs (Value)
	SELECT DISTINCT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strNodeTypeIDs, @delimiter) AS Ref
	
	DECLARE @NTCount int = (SELECT COUNT(*) FROM @NodeTypeIDs)
	
	IF @NodeID IS NOT NULL SET @NTCount = 0
	IF @NodeID IS NOT NULL OR @AdditionalID = N'' SET @AdditionalID = NULL
	IF @Count IS NULL OR @Count <= 0 SET @Count = 10
	
	SET @SearchText = [dbo].[GFN_VerifyString](@SearchText)
	IF @SearchText IS NULL OR @SearchText = N'' SET @SearchText = NULL
	
	DECLARE @TempIDs KeyLessGuidTableType
	DECLARE @NodeIDs KeyLessGuidTableType
	
	-- Admins
	DECLARE @IsSystemAdmin bit = (SELECT [dbo].[GFN_IsSystemAdmin](@ApplicationID, @CurrentUserID))
	
	DECLARE @ServiceAdminIDs GuidTableType
	
	INSERT INTO @ServiceAdminIDs (Value)
	SELECT DISTINCT A.NodeTypeID
	FROM [dbo].[CN_ServiceAdmins] AS A
	WHERE A.ApplicationID = @ApplicationID AND A.UserID = @CurrentUserID AND A.Deleted = 0
	-- end of Admins
	
	INSERT INTO @TempIDs(Value)
	SELECT X.NodeID
	FROM (
			SELECT	ND.NodeID,
					CAST(MAX(CAST(ND.NodeTypeID AS varchar(50))) AS uniqueidentifier) AS NodeTypeID,
					MAX(ND.CreationDate) AS CreationDate,
					CAST(MAX(CAST(ND.Searchable AS int)) AS bit) AS Searchable,
					CAST(MAX(CAST(ND.HideCreators AS int)) AS bit) AS HideCreators,
					CAST(MAX(
						CASE 
							WHEN @CurrentUserID IS NOT NULL AND NC.UserID = @CurrentUserID THEN 1 
							ELSE 0 
						END
					) AS bit) AS CurUser,
					CAST(MAX(CASE WHEN NC.UserID = @UserID THEN 1 ELSE 0 END) AS bit) AS TheUser
			FROM [dbo].[CN_NodeCreators] AS NC
				INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
				ON ND.ApplicationID = @ApplicationID AND ND.NodeID = NC.NodeID
				LEFT JOIN [dbo].[CN_Services] AS S
				ON S.ApplicationID = @ApplicationID AND S.NodeTypeID = ND.NodeTypeID AND S.Deleted = 0
			WHERE NC.ApplicationID = @ApplicationID AND 
				(NC.UserID = @UserID OR (
					@CurrentUserID IS NOT NULL AND NC.UserID = @CurrentUserID
				)) AND 
				(@NodeID IS NULL OR ND.NodeID = @NodeID) AND
				(@NTCount = 0 OR ND.NodeTypeID IN (SELECT NTIDs.Value FROM @NodeTypeIDs AS NTIDs)) AND 
				(@AdditionalID IS NULL OR ND.NodeAdditionalID = @AdditionalID) AND
				(@IsDocument IS NULL OR ISNULL(S.IsDocument, 0) = @IsDocument) AND
				(@LowerDateLimit IS NULL OR ND.CreationDate>= @LowerDateLimit) AND
				(@UpperDateLimit IS NULL OR ND.CreationDate <= @UpperDateLimit) AND
				NC.Deleted = 0 AND ND.Deleted = 0
			GROUP BY ND.NodeID
		) AS X
		LEFT JOIN @ServiceAdminIDs AS S
		ON S.Value = X.NodeTypeID
		LEFT JOIN [dbo].[CN_Services] AS SSS
		ON SSS.ApplicationID = @ApplicationID AND X.NodeTypeID = SSS.NodeTypeID AND SSS.Deleted = 0
	WHERE ISNULL(SSS.NoContent, 0) = 0 AND X.TheUser = 1 AND (@IsSystemAdmin = 1 OR S.Value IS NOT NULL OR 
		(X.Searchable = 1 AND X.HideCreators = 0) OR X.CurUser = 1)
	ORDER BY X.CreationDate DESC, X.NodeID DESC
	
	DECLARE @TotalCount bigint = 0
	
	IF @SearchText IS NULL BEGIN
		SET @TotalCount = (SELECT COUNT(*) FROM @TempIDs)
	
		INSERT INTO @NodeIDs (Value)
		SELECT TOP(@Count) Ref.Value
		FROM @TempIDs AS Ref
		WHERE Ref.SequenceNumber >= ISNULL(@LowerBoundary, 0)
		ORDER BY Ref.SequenceNumber ASC
	END
	ELSE BEGIN
		DECLARE @SelectedIDs KeyLessGuidTableType
	
		INSERT INTO @SelectedIDs (Value)
		SELECT Ref.Value
		FROM (
				SELECT ROW_NUMBER() OVER (ORDER BY SRCH.[Rank] DESC, SRCH.[Key] DESC) AS RowNumber, T.Value
				FROM CONTAINSTABLE([dbo].[CN_Nodes], ([Name], [AdditionalID]), @SearchText) AS SRCH
					INNER JOIN @TempIDs AS T
					ON T.Value = SRCH.[Key]
			) AS Ref
		ORDER BY Ref.RowNumber ASC
		
		SET @TotalCount = (SELECT COUNT(*) FROM @SelectedIDs)
		
		INSERT INTO @NodeIDs (Value)
		SELECT TOP(@Count) S.Value 
		FROM @SelectedIDs AS S
		WHERE S.SequenceNumber >= ISNULL(@LowerBoundary, 0)
	END
	
	EXEC [dbo].[CN_P_GetNodesByIDs] @ApplicationID, @NodeIds, NULL, NULL
	
	SELECT @TotalCount AS TotalCount
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetIntellectualPropertiesOfFriends]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetIntellectualPropertiesOfFriends]
GO

CREATE PROCEDURE [dbo].[CN_GetIntellectualPropertiesOfFriends]
	@ApplicationID	uniqueidentifier,
	@UserID			uniqueidentifier,
	@NodeTypeID		uniqueidentifier,
	@LowerBoundary	int,
	@Count			int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF @Count IS NULL OR @Count <= 0 SET @Count = 10
	
	DECLARE @NodeIDs KeyLessGuidTableType
	
	INSERT INTO @NodeIDs (Value)
	SELECT TOP(@Count) Ref.NodeID
	FROM (
			SELECT	ROW_NUMBER() OVER (ORDER BY ND.CreationDate DESC) AS RowNumber,
					ND.NodeID
			FROM (
					SELECT DISTINCT NC.NodeID
					FROM [dbo].[USR_View_Friends] AS F
						INNER JOIN [dbo].[CN_NodeCreators] AS NC
						ON NC.ApplicationID = @ApplicationID AND NC.UserID = F.FriendID
					WHERE F.ApplicationID = @ApplicationID AND 
						F.UserID = @UserID AND F.AreFriends = 1 AND NC.Deleted = 0
				) AS NID
				INNER JOIN [dbo].[CN_Nodes] AS ND
				ON ND.ApplicationID = @ApplicationID AND ND.NodeID = NID.NodeID
				LEFT JOIN [dbo].[CN_Services] AS S
				ON S.ApplicationID = @ApplicationID AND S.NodeTypeID = ND.NodeTypeID AND S.Deleted = 0
			WHERE (@NodeTypeID IS NULL OR ND.NodeTypeID = @NodeTypeID) AND ND.Deleted = 0 AND
				ND.Searchable = 1 AND ISNULL(ND.HideCreators, 0) = 0 AND ISNULL(S.NoContent, 0) = 0
		) AS Ref
	WHERE Ref.RowNumber >= ISNULL(@LowerBoundary, 0)
	ORDER BY Ref.RowNumber ASC
	
	EXEC [dbo].[CN_P_GetNodesByIDs] @ApplicationID, @NodeIds, NULL, NULL
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetDocumentTreeNodeItems]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetDocumentTreeNodeItems]
GO

CREATE PROCEDURE [dbo].[CN_GetDocumentTreeNodeItems]
	@ApplicationID	uniqueidentifier,
	@TreeNodeID		uniqueidentifier,
	@CurrentUserID	uniqueidentifier,
	@CheckPrivacy	bit,
	@Now			datetime,
	@DefaultPrivacy varchar(20),
	@Count			int,
	@LowerBoundary	int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @TempIDs KeyLessGuidTableType
	
	INSERT INTO @TempIDs (Value)
	SELECT DISTINCT T.NodeID
	FROM [dbo].[CN_Nodes] ND
		RIGHT JOIN (
			SELECT ND.NodeID
			FROM [dbo].[CN_Nodes] AS ND
			WHERE ND.ApplicationID = @ApplicationID AND ND.DocumentTreeNodeID = @TreeNodeID AND	
				ND.[Deleted] = 0 AND ISNULL(ND.Searchable, 1) = 1 AND
				(ISNULL(ND.[Status], N'') = N'' OR ND.[Status] = N'Accepted')
		) AS T
		ON ND.ApplicationID = @ApplicationID AND T.NodeID = ND.PreviousVersionID AND 
			ND.[Deleted] = 0 AND ISNULL(ND.Searchable, 1) = 1 AND
			(ISNULL(ND.[Status], N'') = N'' OR ND.[Status] = N'Accepted')
	WHERE ND.NodeID IS NULL
	
	DECLARE @IDs KeyLessGuidTableType
	
	IF @CheckPrivacy = 1 BEGIN
		DECLARE	@PermissionTypes StringPairTableType
		
		INSERT INTO @PermissionTypes (FirstValue, SecondValue)
		VALUES (N'View', @DefaultPrivacy)
	
		INSERT INTO @IDs (Value)
		SELECT Ref.ID
		FROM [dbo].[PRVC_FN_CheckAccess](@ApplicationID, @CurrentUserID, 
			@tempIDs, N'Node', @Now, @PermissionTypes) AS Ref
	END
	ELSE BEGIN
		INSERT INTO @IDs (Value)
		SELECT Ref.Value AS ID
		FROM @TempIDs AS Ref
	END
	
	DELETE @TempIDs
	
	INSERT INTO @TempIDs (Value)
	SELECT TOP(ISNULL(@Count, 1000)) X.Value
	FROM (
			SELECT	ROW_NUMBER() OVER(ORDER BY ID.SequenceNumber ASC) AS RowNumber,
					ID.Value
			FROM @IDs AS ID
		) AS X
	WHERE X.RowNumber >= ISNULL(@LowerBoundary, 0)
	ORDER BY X.RowNumber ASC
	
	EXEC [dbo].[CN_P_GetNodesByIDs] @ApplicationID, @TempIDs, NULL, NULL
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetDocumentTreeNodeContents]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetDocumentTreeNodeContents]
GO

CREATE PROCEDURE [dbo].[CN_GetDocumentTreeNodeContents]
	@ApplicationID	uniqueidentifier,
	@TreeNodeID		uniqueidentifier,
	@CurrentUserID	uniqueidentifier,
	@CheckPrivacy	bit,
	@Now			datetime,
	@DefaultPrivacy varchar(20),
	@Count			int,
	@LowerBoundary	int,
	@SearchText		nvarchar(500)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @TempIDs KeyLessGuidTableType
	
	DECLARE @TreeID uniqueidentifier = (
		SELECT TOP(1) TreeID
		FROM [dbo].[DCT_Trees]
		WHERE ApplicationID = @ApplicationID AND TreeID = @TreeNodeID
	)
	
	IF @TreeID IS NOT NULL SET @TreeNodeID = NULL
	
	IF ISNULL(@SearchText, N'') = N'' BEGIN
		INSERT INTO @TempIDs (Value)
		SELECT X.NodeID
		FROM (
				SELECT ND.NodeID, MAX(ISNULL(C.CreationDate, ND.CreationDate)) AS CreationDate
				FROM [dbo].[DCT_TreeNodes] AS T
					LEFT JOIN [dbo].[DCT_TreeNodeContents] AS C
					ON C.ApplicationID = @ApplicationID AND C.TreeNodeID = T.TreeNodeID AND C.Deleted = 0
					INNER JOIN [dbo].[CN_Nodes] AS ND
					ON ND.ApplicationID = @ApplicationID AND ND.Deleted = 0 AND 
						(
							(C.NodeID IS NOT NULL AND ND.NodeID = C.NodeID) OR 
							(ND.DocumentTreeNodeID IS NOT NULL AND ND.DocumentTreeNodeID = T.TreeNodeID)
						)
				WHERE T.ApplicationID = @ApplicationID AND
					(
						(@TreeID IS NOT NULL AND T.TreeID = @TreeID AND T.Deleted = 0) OR
						(@TreeNodeID IS NOT NULL AND T.TreeNodeID = @TreeNodeID)
					)
				GROUP BY ND.NodeID
			) AS X
		ORDER BY X.CreationDate DESC
	END
	ELSE BEGIN
		DECLARE @TNIDs GuidTableType
		
		IF @TreeID IS NULL AND @TreeNodeID IS NOT NULL BEGIN
			INSERT INTO @TNIDs (Value)
			VALUES (@TreeNodeID)
		
			INSERT INTO @TNIDs (Value)
			SELECT DISTINCT Ref.NodeID
			FROM [DCT_FN_GetChildNodesDeepHierarchy](@ApplicationID, @TNIDs) AS Ref
			WHERE Ref.NodeID <> @TreeNodeID
		END
	
	
		INSERT INTO @TempIDs (Value)
		SELECT X.NodeID
		FROM (
				SELECT A.NodeID, MAX(A.RowNumber) AS RowNumber
				FROM (
						SELECT	ROW_NUMBER() OVER (ORDER BY SRCH.[Rank] DESC, SRCH.[Key] ASC) AS RowNumber,
								SRCH.[Key] AS NodeID
						FROM CONTAINSTABLE([dbo].[CN_Nodes], (Name), @SearchText) AS SRCH
							INNER JOIN [dbo].[DCT_TreeNodes] AS T
							LEFT JOIN [dbo].[DCT_TreeNodeContents] AS C
							ON C.ApplicationID = @ApplicationID AND C.TreeNodeID = T.TreeNodeID AND C.Deleted = 0
							INNER JOIN [dbo].[CN_Nodes] AS ND
							ON ND.ApplicationID = @ApplicationID AND ND.Deleted = 0 AND 
								(
									(C.NodeID IS NOT NULL AND ND.NodeID = C.NodeID) OR 
									(ND.DocumentTreeNodeID IS NOT NULL AND ND.DocumentTreeNodeID = T.TreeNodeID)
								)
							ON ND.NodeID = SRCH.[Key]
						WHERE T.ApplicationID = @ApplicationID AND
							(
								(@TreeID IS NOT NULL AND T.TreeID = @TreeID AND T.Deleted = 0) OR
								(@TreeNodeID IS NOT NULL AND T.TreeNodeID IN (SELECT B.Value FROM @TNIDs AS B))
							)
					) AS A
				GROUP BY A.NodeID
			) AS X
		ORDER BY X.RowNumber ASC
	END
	
	DECLARE @IDs KeyLessGuidTableType
	
	IF @CheckPrivacy = 1 BEGIN
		DECLARE	@PermissionTypes StringPairTableType
		
		INSERT INTO @PermissionTypes (FirstValue, SecondValue)
		VALUES (N'View', @DefaultPrivacy)
	
		INSERT INTO @IDs (Value)
		SELECT Ref.ID
		FROM [dbo].[PRVC_FN_CheckAccess](@ApplicationID, @CurrentUserID, 
			@tempIDs, N'Node', @Now, @PermissionTypes) AS Ref
	END
	ELSE BEGIN
		INSERT INTO @IDs (Value)
		SELECT Ref.Value AS ID
		FROM @TempIDs AS Ref
	END
	
	DELETE @TempIDs
	
	INSERT INTO @TempIDs (Value)
	SELECT TOP(ISNULL(@Count, 1000)) X.Value
	FROM (
			SELECT	ROW_NUMBER() OVER(ORDER BY ID.SequenceNumber ASC) AS RowNumber,
					ID.Value
			FROM @IDs AS ID
		) AS X
	WHERE X.RowNumber >= ISNULL(@LowerBoundary, 0)
	ORDER BY X.RowNumber ASC
	
	EXEC [dbo].[CN_P_GetNodesByIDs] @ApplicationID, @TempIDs, NULL, NULL
	
	SELECT CAST(COUNT(ID.Value) AS bigint) AS TotalCount
	FROM @IDs AS ID
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_IsNodeType]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_IsNodeType]
GO

CREATE PROCEDURE [dbo].[CN_IsNodeType]
	@ApplicationID	uniqueidentifier,
	@strIDs			varchar(max),
	@delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT Ref.Value AS ID
	FROM [dbo].[GFN_StrToGuidTable](@strIDs, @delimiter) AS Ref
		INNER JOIN [dbo].[CN_NodeTypes] AS NT
		ON NT.ApplicationID = @ApplicationID AND NT.NodeTypeID = Ref.Value
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_IsNode]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_IsNode]
GO

CREATE PROCEDURE [dbo].[CN_IsNode]
	@ApplicationID	uniqueidentifier,
	@strIDs			varchar(max),
	@delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT Ref.Value AS ID
	FROM [dbo].[GFN_StrToGuidTable](@strIDs, @delimiter) AS Ref
		INNER JOIN [dbo].[CN_Nodes] AS NT
		ON NT.ApplicationID = @ApplicationID AND NT.NodeID = Ref.Value
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_Explore]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_Explore]
GO

CREATE PROCEDURE [dbo].[CN_Explore]
	@ApplicationID		uniqueidentifier,
	@BaseID				uniqueidentifier,
	@RelatedID			uniqueidentifier,
	@strBaseTypeIDs		varchar(max),
	@strRelatedTypeIDs	varchar(max),
	@delimiter			char,
	@SecondLevelNodeID	uniqueidentifier,
	@RegistrationArea	bit,
	@Tags				bit,
	@Relations			bit,
	@LowerBoundary		int,
	@Count				int,
	@OrderBy			varchar(100),
	@OrderByDesc		bit,
	@SearchText			nvarchar(1000),
	@CheckAccess		bit,
	@CurrentUserID		uniqueidentifier,
	@Now				datetime,
	@DefaultPrivacy		varchar(50)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @BaseTypeIDs GuidTableType, @RelatedTypeIDs GuidTableType
	
	INSERT INTO @BaseTypeIDs
	SELECT *
	FROM [dbo].[GFN_StrToGuidTable](@strBaseTypeIDs, @delimiter)
	
	INSERT INTO @RelatedTypeIDs
	SELECT *
	FROM [dbo].[GFN_StrToGuidTable](@strRelatedTypeIDs, @delimiter)
	
	IF @OrderBy = 'Type' SET @OrderBy = 'RelatedType'	
	ELSE IF @OrderBy = N'Date' SET @OrderBy = 'RelatedCreationDate'	
	ELSE SET @OrderBy = 'RelatedName'
	
	DECLARE @SortOrder varchar(10) = 'ASC', @RevSortOrder varchar(10) = 'DESC'
	IF @OrderByDesc = 1 BEGIN 
		SET @SortOrder = 'DESC'
		SET @RevSortOrder = 'ASC'
	END
	
	DECLARE @BaseIDs GuidTableType
	
	IF @BaseID IS NOT NULL BEGIN
		INSERT INTO @BaseIDs (Value)
		VALUES (@BaseID)
		
		IF ISNULL(@SearchText, N'') <> N'' BEGIN
			INSERT INTO @BaseIDs (Value)
			SELECT DISTINCT H.NodeID
			FROM @BaseIDs AS B
				RIGHT JOIN [dbo].[CN_FN_GetChildNodesDeepHierarchy](@ApplicationID, @BaseIDs) AS H
				ON H.NodeID = B.Value
			WHERE B.Value IS NULL AND H.NodeID <> @BaseID
		END
	END
	
	CREATE TABLE #Items (BaseID uniqueidentifier,
		BaseTypeID uniqueidentifier, BaseName nvarchar(2000), BaseType nvarchar(2000), 
		RelatedID uniqueidentifier, RelatedTypeID uniqueidentifier, RelatedName nvarchar(2000),
		RelatedType nvarchar(2000), RelatedCreationDate datetime,
		IsTag bit, IsRelation bit, IsRegistrationArea bit,
		PRIMARY KEY (BaseID, RelatedID)
	)

	INSERT INTO #Items
	SELECT	Ref.BaseID,
			CAST(MAX(CAST(Ref.BaseTypeID AS varchar(100))) AS uniqueidentifier),
			MAX(Ref.BaseName),
			MAX(Ref.BaseType),
			Ref.RelatedID,
			CAST(MAX(CAST(Ref.RelatedTypeID AS varchar(100))) AS uniqueidentifier),
			MAX(Ref.RelatedName),
			MAX(Ref.RelatedType),
			MAX(Ref.RelatedCreationDate),
			CAST(MAX(CAST(Ref.IsTag AS int)) AS bit),
			CAST(MAX(CAST(Ref.IsRelation AS int)) AS bit),
			CAST(MAX(CAST(Ref.IsRegistrationArea AS int)) AS bit)
	FROM [dbo].[CN_FN_Explore](@ApplicationID, @BaseIDs, @BaseTypeIDs, 
		@RelatedID, @RelatedTypeIDs, @RegistrationArea, @Tags, @Relations) AS Ref
	GROUP By Ref.BaseID, Ref.RelatedID
	
	IF @SecondLevelNodeID IS NOT NULL BEGIN
		DECLARE @BIDs GuidTableType
		DECLARE @BTIDs GuidTableType
		
		INSERT INTO @BIDs (Value) VALUES (@SecondLevelNodeID)
	
		DELETE I
		FROM #Items AS I
			LEFT JOIN (
				SELECT R.NodeID, R.RelatedNodeID
				FROM [dbo].[CN_FN_GetRelatedNodeIDs](@ApplicationID, 
					@BIDs, @BTIDs, @RelatedTypeIDs, @Relations, @Relations, @Tags, @Tags) AS R
			) AS X
			ON X.RelatedNodeID = I.RelatedID
		WHERE X.RelatedNodeID IS NULL
	END
	
	
	IF ISNULL(@CheckAccess, 0) = 1 BEGIN
		DECLARE @TempIDs KeyLessGuidTableType
		
		INSERT INTO @TempIDs (Value)
		SELECT RelatedID
		FROM #Items
		
		DECLARE	@PermissionTypes StringPairTableType
		
		INSERT INTO @PermissionTypes (FirstValue, SecondValue)
		VALUES (N'View', @DefaultPrivacy)
	
		DELETE I
		FROM #Items AS I
			LEFT JOIN [dbo].[PRVC_FN_CheckAccess](@ApplicationID, @CurrentUserID, 
				@TempIDs, N'Node', @Now, @PermissionTypes) AS A
			ON A.ID = I.RelatedID
		WHERE A.ID IS NULL
	END
	
	IF ISNULL(@SearchText, N'') = N'' BEGIN	
		DECLARE @ToBeExecuted varchar(2000) = 
			'SELECT TOP(' + CAST(ISNULL(@Count, 100) AS varchar(100)) + ') ' +
				'CAST((X.RowNumber + X.RevRowNumber - 1) AS bigint) AS TotalCount, ' +
				'X.BaseID, X.BaseTypeID, X.BaseName, X.BaseType, ' +
				'X.RelatedID, X.RelatedTypeID, X.RelatedName, X.RelatedType, ' +
				'X.RelatedCreationDate, X.IsTag, X.IsRelation, X.IsRegistrationArea ' +
			'FROM ( ' +
					'SELECT	ROW_NUMBER() OVER (ORDER BY I.' + @OrderBy + ' ' + 
								@SortOrder + ', I.RelatedID ASC) AS RowNumber, ' +
							'ROW_NUMBER() OVER (ORDER BY I.' + @OrderBy + ' ' + 
								@RevSortOrder + ', I.RelatedID DESC) AS RevRowNumber, ' +
							'I.* ' +
					'FROM #Items AS I ' +
				') AS X ' +
			'WHERE X.RowNumber >= ' + CAST(ISNULL(@LowerBoundary, 0) AS varchar(100)) + ' ' +
			'ORDER BY X.RowNumber ASC '
			
		EXEC (@ToBeExecuted)
	END
	ELSE BEGIN
		SELECT TOP(ISNULL(@Count, 100))
			CAST((X.RowNumber + X.RevRowNumber - 1) AS bigint) AS TotalCount,
			X.BaseID, X.BaseTypeID, X.BaseName, X.BaseType,
			X.RelatedID, X.RelatedTypeID, X.RelatedName, X.RelatedType,
			X.RelatedCreationDate, X.IsTag, X.IsRelation, X.IsRegistrationArea
		FROM (
				SELECT	ROW_NUMBER() OVER (ORDER BY SRCH.[Rank] DESC, SRCH.[Key] ASC) AS RowNumber,
						ROW_NUMBER() OVER (ORDER BY SRCH.[Rank] ASC, SRCH.[Key] DESC) AS RevRowNumber,
						Ref.*
				FROM CONTAINSTABLE([dbo].[CN_Nodes], ([Name], [AdditionalID]), @SearchText) AS SRCH
					INNER JOIN (
						SELECT	CAST(MAX(CAST(I.BaseID AS varchar(100))) AS uniqueidentifier) AS BaseID,
								CAST(MAX(CAST(I.BaseTypeID AS varchar(100))) AS uniqueidentifier) AS BaseTypeID,
								MAX(I.BaseName) AS BaseName,
								MAX(I.BaseType) AS BaseType,
								I.RelatedID,
								CAST(MAX(CAST(I.RelatedTypeID AS varchar(100))) AS uniqueidentifier) AS RelatedTypeID,
								MAX(I.RelatedName) AS RelatedName,
								MAX(I.RelatedType) AS RelatedType,
								MAX(I.RelatedCreationDate) AS RelatedCreationDate,
								CAST(MAX(CAST(I.IsTag AS int)) AS bit) AS IsTag,
								CAST(MAX(CAST(I.IsRelation AS int)) AS bit) AS IsRelation,
								CAST(MAX(CAST(I.IsRegistrationArea AS int)) AS bit) AS IsRegistrationArea
						FROM #Items AS I
						GROUP BY I.RelatedID
					) AS Ref
					ON Ref.RelatedID = SRCH.[Key]
			) AS X
		WHERE X.RowNumber >= ISNULL(@LowerBoundary, 0)
		ORDER BY X.RowNumber ASC
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_UpdateFormAndWikiTags]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_UpdateFormAndWikiTags]
GO

CREATE PROCEDURE [dbo].[CN_P_UpdateFormAndWikiTags]
	@ApplicationID	uniqueidentifier,
	@NodeIDsTemp	GuidTableType readonly,
	@CreatorUserID	uniqueidentifier,
	@Form			bit,
	@Wiki			bit,
	@_Result		int output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeIDs GuidTableType
	INSERT INTO @NodeIDs SELECT * FROM @NodeIDsTemp
	
	DELETE T
	FROM @NodeIDs AS IDs 
		INNER JOIN [dbo].[RV_TaggedItems] AS T
		ON T.ApplicationID = @ApplicationID AND T.ContextID = IDs.Value AND
			(
				(@Form = 1 AND T.TaggedType IN (N'Node_Form', N'User_Form')) OR 
				(@Wiki = 1 AND T.TaggedType IN (N'Node_Wiki', N'User_Wiki'))
			)

	;WITH hierarchy (ElementID, NodeID, [Level], [Type])
	AS
	(
		SELECT E.ElementID, N.Value AS NodeID, 0 AS [Level], E.[Type]
		FROM @NodeIDs AS N
			INNER JOIN [dbo].[FG_FormInstances] AS I
			ON I.ApplicationID = @ApplicationID AND I.OwnerID = N.Value AND I.Deleted = 0
			INNER JOIN [dbo].[FG_InstanceElements] AS E
			ON E.ApplicationID = @ApplicationID AND E.InstanceID = I.InstanceID AND E.Deleted = 0
		WHERE @Form = 1
		
		UNION ALL
		
		SELECT E.ElementID, HR.NodeID, [Level] + 1, E.[Type]
		FROM hierarchy AS HR
			INNER JOIN [dbo].[FG_FormInstances] AS I
			ON I.ApplicationID = @ApplicationID AND I.OwnerID = HR.ElementID AND I.Deleted = 0
			INNER JOIN [dbo].[FG_InstanceElements] AS E
			ON E.ApplicationID = @ApplicationID AND E.InstanceID = I.InstanceID AND E.Deleted = 0
		WHERE @Form = 1 AND E.ElementID <> HR.ElementID
	)


	INSERT INTO [dbo].[RV_TaggedItems] (
		ApplicationID, 
		ContextID, 
		ContextType, 
		TaggedID, 
		TaggedType, 
		UniqueID, 
		CreatorUserID
	)
	SELECT @ApplicationID, X.NodeID, N'Node', X.TaggedID, X.TaggedType, NEWID(), @CreatorUserID
	FROM (
			SELECT A.NodeID, A.TaggedID, MAX(A.TaggedType) AS TaggedType
			FROM (
					SELECT H.NodeID, T.TaggedID, T.TaggedType + N'_Form' AS TaggedType
					FROM hierarchy AS H
						INNER JOIN [dbo].[RV_TaggedItems] AS T
						ON T.ApplicationID = @ApplicationID AND T.ContextID = H.ElementID AND 
							T.TaggedType IN (N'Node', N'User')
					
					UNION

					SELECT H.NodeID, S.SelectedID AS TaggedID, H.[Type] + N'_Form' AS TaggedType
					FROM hierarchy AS H
						INNER JOIN [dbo].[FG_SelectedItems] AS S
						ON S.ApplicationID = @ApplicationID AND S.ElementID = H.ElementID AND S.Deleted = 0
					WHERE H.[Type] IN (N'Node', N'User')
					
					UNION
					
					SELECT T.ContextID AS NodeID, T.TaggedID, T.TaggedType + N'_Wiki' AS TaggedType
					FROM @NodeIDs AS IDs
						INNER JOIN [dbo].[CN_View_TagRelations_WikiContext] AS T
						ON T.ApplicationID = @ApplicationID AND T.ContextID = IDs.Value
					WHERE @Wiki = 1
				) AS A
			GROUP BY A.NodeID, A.TaggedID
		) AS X
		LEFT JOIN [dbo].[CN_Nodes] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.NodeID = X.TaggedID AND ND.Deleted = 0
		LEFT JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND UN.UserID = X.TaggedID AND UN.IsApproved = 1
		LEFT JOIN [dbo].[RV_TaggedItems] AS T
		ON T.ApplicationID = @ApplicationID AND T.ContextID = X.NodeID AND
			T.TaggedID = X.TaggedID AND T.CreatorUserID = @CreatorUserID
	WHERE T.ContextID IS NULL AND (ND.NodeID IS NOT NULL OR UN.UserID IS NOT NULL)
		
	SET @_Result = 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_UpdateFormAndWikiTags]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_UpdateFormAndWikiTags]
GO

CREATE PROCEDURE [dbo].[CN_UpdateFormAndWikiTags]
	@ApplicationID	uniqueidentifier,
	@strNodeIDs		varchar(max),
	@delimiter		char,
	@CreatorUserID	uniqueidentifier,
	@Count			int,
	@Form			bit,
	@Wiki			bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @NodeIDs GuidTableType
	
	INSERT INTO @NodeIDs (Value)
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strNodeIDs, @delimiter) AS Ref
	
	IF (SELECT COUNT(*) FROM @NodeIDs) = 0 BEGIN
		INSERT INTO @NodeIDs (Value)
		SELECT TOP(ISNULL(@Count, 200)) ND.NodeID
		FROM [dbo].[CN_Nodes] AS ND
		WHERE ND.ApplicationID = @ApplicationID AND ND.Deleted = 0
		ORDER BY ND.IndexLastUpdateDate ASC
	END
	
	IF @CreatorUserID IS NULL SET @CreatorUserID = (
		SELECT TOP(1) UserID
		FROM [dbo].[Users_Normal] AS UN
		WHERE UN.ApplicationID = @ApplicationID AND LOWER(UserName) = N'admin'
	)

	IF @CreatorUserID IS NULL SET @CreatorUserID = (
		SELECT TOP(1) App.CreatorUserID
		FROM [dbo].[aspnet_Applications] AS App
		WHERE App.ApplicationId = @ApplicationID
	)
	
	DECLARE @_Result int
	
	EXEC [dbo].[CN_P_UpdateFormAndWikiTags] @ApplicationID, @NodeIDs, @CreatorUserID, 
		@Form, @Wiki, @_Result output
	
	SELECT @_Result
END

GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_SetAvatar]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_SetAvatar]
GO

CREATE PROCEDURE [dbo].[CN_SetAvatar]
	@ApplicationID	uniqueidentifier,
    @ID		 		uniqueidentifier,
    @AvatarName		varchar(50)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[CN_Nodes]
	SET AvatarName = CASE WHEN ISNULL(@AvatarName, '') = '' THEN AvatarName ELSE @AvatarName END,
		UseAvatar = CASE WHEN ISNULL(@AvatarName, '') = '' THEN 0 ELSE 1 END
	WHERE ApplicationID = @ApplicationID AND NodeID = @ID

	DECLARE @Result int = @@ROWCOUNT

	IF @Result <= 0 BEGIN
		UPDATE [dbo].[CN_NodeTypes]
		SET AvatarName = CASE WHEN ISNULL(@AvatarName, '') = '' THEN AvatarName ELSE @AvatarName END,
			UseAvatar = CASE WHEN ISNULL(@AvatarName, '') = '' THEN 0 ELSE 1 END
		WHERE ApplicationID = @ApplicationID AND NodeTypeID = @ID

		SET @Result = @@ROWCOUNT
	END

	SELECT @Result
END

GO