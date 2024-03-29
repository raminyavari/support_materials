USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_P_InitializeForms]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_P_InitializeForms]
GO

CREATE PROCEDURE [dbo].[KW_P_InitializeForms]
	@ApplicationID		uniqueidentifier,
	@AdminID			uniqueidentifier,
	@ExperienceTypeID	uniqueidentifier,
	@SkillTypeID		uniqueidentifier,
	@DocumentTypeID		uniqueidentifier,
	@_Result			int output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @FormID uniqueidentifier = NULL

	IF @ExperienceTypeID IS NOT NULL AND NOT EXISTS(
		SELECT TOP(1) * 
		FROM [dbo].[FG_FormOwners] AS FO 
		WHERE FO.ApplicationID = @ApplicationID AND OwnerID = @ExperienceTypeID
	) BEGIN
		SET @FormID = NEWID()

		INSERT [dbo].[FG_ExtendedForms] ([ApplicationID], [FormID], [Title], 
			[CreatorUserID], [CreationDate], [Deleted]) 
		VALUES (@ApplicationID, @FormID, N'فرم ثبت تجربه', @AdminID, 
			CAST(0x0000A49600C3C29A AS DateTime), 0)
		
		INSERT [dbo].[FG_ExtendedFormElements] ([ApplicationID], [ElementID], [FormID], 
			[Title], [SequenceNumber], [Type], [Info], [CreatorUserID], [CreationDate], 
			[Deleted], [Necessary]) 
		VALUES (@ApplicationID, NEWID(), @FormID, N'شرح تجربه', 7, N'Text', N'{}', 
			@AdminID, CAST(0x0000A49600C7EB49 AS DateTime), 0, 1)
		
		INSERT [dbo].[FG_ExtendedFormElements] ([ApplicationID], [ElementID], [FormID], 
			[Title], [SequenceNumber], [Type], [Info], [CreatorUserID], [CreationDate], 
			[Deleted], [Necessary]) 
		VALUES (@ApplicationID, NEWID(), @FormID, N'کاربرد تجربه', 9, N'Text', N'{}', 
			@AdminID, CAST(0x0000A49600C82B85 AS DateTime), 0, 1)

		INSERT INTO [dbo].[FG_FormOwners] (ApplicationID, OwnerID, FormID, 
			CreatorUserID, CreationDate, Deleted)
		VALUES (@ApplicationID, @ExperienceTypeID, @FormID, @AdminID, GETDATE(), 0)
	END


	IF @SkillTypeID IS NOT NULL AND NOT EXISTS(
		SELECT TOP(1) * 
		FROM [dbo].[FG_FormOwners] AS FO 
		WHERE ApplicationID = @ApplicationID AND OwnerID = @SkillTypeID
	) BEGIN
		SET @FormID = NEWID()

		INSERT [dbo].[FG_ExtendedForms] ([ApplicationID], [FormID], [Title], 
			[CreatorUserID], [CreationDate], [Deleted]) 
		VALUES (@ApplicationID, @FormID, N'فرم ثبت مهارت', @AdminID, 
			CAST(0x0000A49600C3C29A AS DateTime), 0)
		
		INSERT [dbo].[FG_ExtendedFormElements] ([ApplicationID], [ElementID], [FormID], 
			[Title], [SequenceNumber], [Type], [Info], [CreatorUserID], [CreationDate], 
			[Deleted], [Necessary]) 
		VALUES (@ApplicationID, NEWID(), @FormID, N'شرح مهارت', 7, N'Text', N'{}', 
			@AdminID, CAST(0x0000A49600C7EB49 AS DateTime), 0, 1)
		
		INSERT [dbo].[FG_ExtendedFormElements] ([ApplicationID], [ElementID], [FormID], 
			[Title], [SequenceNumber], [Type], [Info], [CreatorUserID], [CreationDate], 
			[Deleted], [Necessary]) 
		VALUES (@ApplicationID, NEWID(), @FormID, N'کاربرد مهارت', 9, N'Text', N'{}', 
			@AdminID, CAST(0x0000A49600C82B85 AS DateTime), 0, 1)

		INSERT INTO [dbo].[FG_FormOwners] (ApplicationID, OwnerID, FormID, 
			CreatorUserID, CreationDate, Deleted)
		VALUES (@ApplicationID, @SkillTypeID, @FormID, @AdminID, GETDATE(), 0)
	END


	IF @DocumentTypeID IS NOT NULL AND NOT EXISTS(
		SELECT TOP(1) * 
		FROM [dbo].[FG_FormOwners] AS FO 
		WHERE ApplicationID = @ApplicationID AND OwnerID = @DocumentTypeID
	) BEGIN
		SET @FormID = NEWID()

		INSERT [dbo].[FG_ExtendedForms] ([ApplicationID], [FormID], [Title], 
			[CreatorUserID], [CreationDate], [Deleted]) 
		VALUES (@ApplicationID, @FormID, N'فرم ثبت مستند', @AdminID, 
			CAST(0x0000A49600C3C29A AS DateTime), 0)
		
		INSERT [dbo].[FG_ExtendedFormElements] ([ApplicationID], [ElementID], [FormID], 
			[Title], [SequenceNumber], [Type], [Info], [CreatorUserID], [CreationDate], 
			[Deleted], [Necessary]) 
		VALUES (@ApplicationID, NEWID(), @FormID, N'شرح مستند', 7, N'Text', N'{}', 
			@AdminID, CAST(0x0000A49600C7EB49 AS DateTime), 0, 1)
		
		INSERT [dbo].[FG_ExtendedFormElements] ([ApplicationID], [ElementID], [FormID], 
			[Title], [SequenceNumber], [Type], [Info], [CreatorUserID], [CreationDate], 
			[Deleted], [Necessary]) 
		VALUES (@ApplicationID, NEWID(), @FormID, N'کاربرد مستند', 9, N'Text', N'{}', 
			@AdminID, CAST(0x0000A49600C82B85 AS DateTime), 0, 1)

		INSERT INTO [dbo].[FG_FormOwners] (ApplicationID, OwnerID, FormID, 
			CreatorUserID, CreationDate, Deleted)
		VALUES (@ApplicationID, @DocumentTypeID, @FormID, @AdminID, GETDATE(), 0)
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_P_InitializeKnowledgeTypes]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_P_InitializeKnowledgeTypes]
GO

CREATE PROCEDURE [dbo].[KW_P_InitializeKnowledgeTypes]
	@ApplicationID		uniqueidentifier,
	@AdminID			uniqueidentifier,
	@ExperienceTypeID	uniqueidentifier,
	@SkillTypeID		uniqueidentifier,
	@DocumentTypeID		uniqueidentifier,
	@_Result			int output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Now datetime = GETDATE()
	
	IF NOT EXISTS (
		SELECT TOP(1) *
		FROM [dbo].[KW_KnowledgeTypes]
		WHERE ApplicationID = @ApplicationID AND KnowledgeTypeID = @ExperienceTypeID
	) BEGIN
		INSERT INTO [dbo].[KW_KnowledgeTypes] (ApplicationID, KnowledgeTypeID,
			EvaluationType, Evaluators, SearchableAfter, ScoreScale, MinAcceptableScore,
			NodeSelectType, CreatorUserID, CreationDate, Deleted)
		VALUES (@ApplicationID, @ExperienceTypeID, N'EN', N'Experts',
			N'Evaluation', 10, 5, N'Free', @AdminID, @Now, 0)
	END
	
	IF NOT EXISTS (
		SELECT TOP(1) *
		FROM [dbo].[KW_KnowledgeTypes]
		WHERE ApplicationID = @ApplicationID AND KnowledgeTypeID = @SkillTypeID
	) BEGIN	
		INSERT INTO [dbo].[KW_KnowledgeTypes] (ApplicationID, KnowledgeTypeID,
			EvaluationType, Evaluators, SearchableAfter, ScoreScale, MinAcceptableScore,
			NodeSelectType, CreatorUserID, CreationDate, Deleted)
		VALUES (@ApplicationID, @SkillTypeID, N'EN', N'Experts',
			N'Evaluation', 10, 5, N'Free', @AdminID, @Now, 0)
	END
	
	IF NOT EXISTS (
		SELECT TOP(1) *
		FROM [dbo].[KW_KnowledgeTypes]
		WHERE ApplicationID = @ApplicationID AND KnowledgeTypeID = @DocumentTypeID
	) BEGIN	
		INSERT INTO [dbo].[KW_KnowledgeTypes] (ApplicationID, KnowledgeTypeID,
			EvaluationType, Evaluators, SearchableAfter, ScoreScale, MinAcceptableScore,
			NodeSelectType, CreatorUserID, CreationDate, Deleted)
		VALUES (@ApplicationID, @DocumentTypeID, N'EN', N'Experts',
			N'Evaluation', 10, 5, N'Free', @AdminID, @Now, 0)
	END
	
	SET @_Result = 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_P_InitializeQuestions]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_P_InitializeQuestions]
GO

CREATE PROCEDURE [dbo].[KW_P_InitializeQuestions]
	@ApplicationID		uniqueidentifier,
	@AdminID			uniqueidentifier,
	@ExperienceTypeID	uniqueidentifier,
	@SkillTypeID		uniqueidentifier,
	@DocumentTypeID		uniqueidentifier,
	@_Result			int output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) *
		FROM [dbo].[KW_Questions] 
		WHERE ApplicationID = @ApplicationID
	) BEGIN
		SET @_Result = 1
		RETURN
	END
	
	DECLARE @Now datetime = GETDATE()
	
	DECLARE @TBL Table (TypeID uniqueidentifier, SequenceNumber int,
		QuestionID uniqueidentifier, Title nvarchar(1000))
		
	INSERT INTO @TBL (TypeID, QuestionID, SequenceNumber, Title)
	VALUES (
		@ExperienceTypeID, NEWID(), 1,
		N'اگر این تجربه برای چه مدت در سازمان وجود نداشته باشد، به مشکل می خورید؟ به عبارتی هر چند وقت یکبار ممکن است به این تجربه نیاز داشته باشید؟'
	),
	(
		@ExperienceTypeID, NEWID(), 2,
		N'انتقال و آموزش این تجربه چگونه است؟ (ساده و کم هزینه=1، سخت و پر هزینه=10)'
	),
	(
		@ExperienceTypeID, NEWID(), 3,
		N'تا چه اندازه این تجربه برای اجرای فرایندها و فعالیت های روزمره سازمان مهم است؟'
	),
	(
		@ExperienceTypeID, NEWID(), 4,
		N'تجربه تا چه اندازه می تواند به تصمیم گیری های استراتژیک و جهت گیری سازمان کمک کند؟'
	),
	(
		@ExperienceTypeID, NEWID(), 5,
		N'سازمان اگر بخواهد این تجربه را از بیرون به خدمت بگیرد، سالیانه چقدر باید برای آن هزینه کند؟ (زیر یک میلیون تومان=10، بالای 100 میلیون تومان=10)'
	),
	(
		@ExperienceTypeID, NEWID(), 6,
		N'میزان اعتبار و به روز بودن این نوع تجربه را چگونه ارزیابی می کنید؟ تا چه حد در شرایط فعلی نیز قابل استفاده است؟ (خیلی زیاد=10، خیلی کم=1)'
	),
	(
		@SkillTypeID, NEWID(), 7,
		N'اگر این مهارت برای چه مدت در سازمان وجود نداشته باشد، به مشکل می خورید؟ به عبارتی هر چند وقت یکبار ممکن است به این مهارت نیاز پیدا شود؟'
	),
	(
		@SkillTypeID, NEWID(), 8,
		N'انتقال و آموزش این مهارت چگونه است؟ (ساده و کم هزینه=1، سخت و پر هزینه=10)'
	),
	(
		@SkillTypeID, NEWID(), 9,
		N'بنابر شواهد ارایه شده و با توجه به وضعیت فعلی سازمان، مهارت این فرد در چه سطحی است؟'
	),
	(
		@SkillTypeID, NEWID(), 10,
		N'تا چه اندازه این مهارت برای اجرای فرآیندها و فعالیت های روزمره سازمان مهم است؟'
	),
	(
		@SkillTypeID, NEWID(), 11,
		N'سازمان اگر بخواهد این مهارت را از بیرون به خدمت بگیرد، سالیانه چقدر باید برای آن هزینه کند؟ (زیر یک میلیون تومان=1، بالای 100 میلیون تومان=10)'
	),
	(
		@SkillTypeID, NEWID(), 12,
		N'مهارت تا چه اندازه می تواند به تصمیم گیری های استراتژیک و جهت گیری سازمان کمک کند؟'
	),
	(
		@SkillTypeID, NEWID(), 13,
		N'میزان اعتبار و به روز بودن این نوع مهارت را چگونه ارزیابی می کنید؟'
	),
	(
		@DocumentTypeID, NEWID(), 14,
		N'اگر این مستند برای چه مدت در سازمان وجود نداشته باشد، به مشکل می خورید؟ به عبارتی هر چند وقت یکبار ممکن است به این مستند نیاز پیدا شود؟'
	),
	(
		@DocumentTypeID, NEWID(), 15,
		N'این مستند تا چه اندازه می تواند به تصمیم گیری های استراتژیک و جهت گیری سازمان کمک کند؟'
	),
	(
		@DocumentTypeID, NEWID(), 16,
		N'تا چه اندازه این مستند برای اجرای فرآیندها و فعالیت های روزمره سازمان مهم است؟'
	),
	(
		@DocumentTypeID, NEWID(), 17,
		N'دانش های پیش نیاز درک و بکارگیری این سند تا چه حد درون آن گنجانده شده یا به آنها به خوبی ارجاع داده شده است؟'
	),
	(
		@DocumentTypeID, NEWID(), 18,
		N'سازمان اگر بخواهد این مستند را از بیرون بخرد، سالیانه چقدر باید برای آن هزینه کند؟ (زیر یک میلیون=1، بالای 100 میلیون=10)'
	),
	(
		@DocumentTypeID, NEWID(), 19,
		N'میزان ساخت یافتگی و قابلیت استفاده از دانش درون این مستند چقدر است؟'
	)
	
	
	INSERT INTO [dbo].[KW_Questions] (
		ApplicationID, QuestionID, Title, CreatorUserID, CreationDate, Deleted
	)
	SELECT @ApplicationID, T.QuestionID, T.Title, @AdminID, @Now, 0
	FROM @TBL AS T
	
	
	INSERT INTO [dbo].[KW_TypeQuestions] (
		ApplicationID, ID, KnowledgeTypeID, QuestionID, SequenceNumber, 
		CreatorUserID, CreationDate, Deleted
	)
	SELECT @ApplicationID, NEWID(), T.TypeID, T.QuestionID, T.SequenceNumber, 
		@AdminID, @Now, 0
	FROM @TBL AS T
	
	SET @_Result = 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_P_InitializeServices]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_P_InitializeServices]
GO

CREATE PROCEDURE [dbo].[KW_P_InitializeServices]
	@ApplicationID		uniqueidentifier,
	@ExperienceTypeID	uniqueidentifier,
	@SkillTypeID		uniqueidentifier,
	@DocumentTypeID		uniqueidentifier,
	@_Result			int output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) *
		FROM [dbo].[KW_KnowledgeTypes] AS KT
			INNER JOIN [dbo].[CN_Services] AS S
			ON S.ApplicationID = @ApplicationID AND S.NodeTypeID = KT.KnowledgeTypeID
		WHERE KT.ApplicationID = @ApplicationID
	) BEGIN
		SET @_Result = 1
		RETURN
	END
	
	INSERT INTO [dbo].[CN_Services] (ApplicationID, NodeTypeID, ServiceTitle,
		EnableContribution, AdminType, MaxAcceptableAdminLevel, EditableForAdmin,
		EditableForCreator, EditableForOwners, EditableForExperts, EditableForMembers,
		Deleted, IsDocument, IsKnowledge, EditSuggestion, IsTree, SequenceNumber)
	VALUES (@ApplicationID, @ExperienceTypeID, N'ثبت تجربه', 1, N'AreaAdmin',
		2, 1, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0)
		
	INSERT INTO [dbo].[CN_Services] (ApplicationID, NodeTypeID, ServiceTitle,
		EnableContribution, AdminType, MaxAcceptableAdminLevel, EditableForAdmin,
		EditableForCreator, EditableForOwners, EditableForExperts, EditableForMembers,
		Deleted, IsDocument, IsKnowledge, EditSuggestion, IsTree, SequenceNumber)
	VALUES (@ApplicationID, @SkillTypeID, N'ثبت مهارت', 0, N'AreaAdmin',
		2, 1, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0)
		
	INSERT INTO [dbo].[CN_Services] (ApplicationID, NodeTypeID, ServiceTitle,
		EnableContribution, AdminType, MaxAcceptableAdminLevel, EditableForAdmin,
		EditableForCreator, EditableForOwners, EditableForExperts, EditableForMembers,
		Deleted, IsDocument, IsKnowledge, EditSuggestion, IsTree, SequenceNumber)
	VALUES (@ApplicationID, @DocumentTypeID, N'ثبت مستند', 1, N'AreaAdmin',
		2, 1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0)
	
	SET @_Result = 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_Initialize]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_Initialize]
GO

CREATE PROCEDURE [dbo].[KW_Initialize]
	@ApplicationID		uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @ExperienceTypeID uniqueidentifier = (
		SELECT TOP(1) NodeTypeID
		FROM [dbo].[CN_NodeTypes]
		WHERE ApplicationID = @ApplicationID AND AdditionalID = '9'
	)
	
	DECLARE @SkillTypeID uniqueidentifier = (
		SELECT TOP(1) NodeTypeID
		FROM [dbo].[CN_NodeTypes]
		WHERE ApplicationID = @ApplicationID AND AdditionalID = '8'
	)
	
	DECLARE @DocumentTypeID uniqueidentifier = (
		SELECT TOP(1) NodeTypeID
		FROM [dbo].[CN_NodeTypes]
		WHERE ApplicationID = @ApplicationID AND AdditionalID = '10'
	)
	
	DECLARE @AdminID uniqueidentifier = (
		SELECT TOP(1) UserID 
		FROM [dbo].[Users_Normal] 
		WHERE ApplicationID = @ApplicationID AND UserName = N'admin'
	)
	
	
	DECLARE @_Result int
	
	EXEC [dbo].[KW_P_InitializeForms] @ApplicationID, @AdminID,
		@ExperienceTypeID, @SkillTypeID, @DocumentTypeID, @_Result output
	
	EXEC [dbo].[KW_P_InitializeKnowledgeTypes] @ApplicationID, @AdminID,
		@ExperienceTypeID, @SkillTypeID, @DocumentTypeID, @_Result output
	
	EXEC [dbo].[KW_P_InitializeQuestions] @ApplicationID, @AdminID,
		@ExperienceTypeID, @SkillTypeID, @DocumentTypeID, @_Result output
		
	EXEC [dbo].[KW_P_InitializeServices] @ApplicationID, 
		@ExperienceTypeID, @SkillTypeID, @DocumentTypeID, @_Result output
	
	SELECT 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_AddKnowledgeType]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_AddKnowledgeType]
GO

CREATE PROCEDURE [dbo].[KW_AddKnowledgeType]
	@ApplicationID		uniqueidentifier,
	@KnowledgeTypeID	uniqueidentifier,
	@CreatorUserID		uniqueidentifier,
	@CreationDate		datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF ISNULL((
		SELECT TOP(1) 1
		FROM [dbo].[CN_Services] AS S
		WHERE S.ApplicationID = @ApplicationID AND 
			S.NodeTypeID = @KnowledgeTypeID AND ISNULL(S.IsKnowledge, 0) = 1
	), 0) = 0 BEGIN
		SELECT -1
		RETURN
	END
	
	IF EXISTS(SELECT TOP(1) * FROM [dbo].[KW_KnowledgeTypes] 
		WHERE KnowledgeTypeID = @KnowledgeTypeID) BEGIN
		UPDATE [dbo].[KW_KnowledgeTypes]
			SET Deleted = 0,
				LastModifierUserID = @CreatorUserID,
				LastModificationDate = @CreationDate
		WHERE ApplicationID = @ApplicationID AND KnowledgeTypeID = @KnowledgeTypeID
	END
	ELSE BEGIN
		INSERT INTO [dbo].[KW_KnowledgeTypes](
			ApplicationID,
			KnowledgeTypeID,
			CreatorUserID,
			CreationDate,
			ConvertEvaluatorsToExperts,
			Deleted
		)
		VALUES(
			@ApplicationID,
			@KnowledgeTypeID,
			@CreatorUserID,
			@CreationDate,
			0,
			0
		)
	END
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_ArithmeticDeleteKnowledgeType]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_ArithmeticDeleteKnowledgeType]
GO

CREATE PROCEDURE [dbo].[KW_ArithmeticDeleteKnowledgeType]
	@ApplicationID				uniqueidentifier,
	@KnowledgeTypeID			uniqueidentifier,
	@LastModifierUserID			uniqueidentifier,
	@LastModificationDate		datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[KW_KnowledgeTypes]
		SET Deleted = 1,
			LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate
	WHERE ApplicationID = @ApplicationID AND KnowledgeTypeID = @KnowledgeTypeID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_P_GetKnowledgeTypesByIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_P_GetKnowledgeTypesByIDs]
GO

CREATE PROCEDURE [dbo].[KW_P_GetKnowledgeTypesByIDs]
	@ApplicationID			uniqueidentifier,
	@KnowledgeTypeIDsTemp	GuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @KnowledgeTypeIDs GuidTableType
	INSERT INTO @KnowledgeTypeIDs SELECT * FROM @KnowledgeTypeIDsTemp
	
	SELECT KT.KnowledgeTypeID,
		   NT.Name AS KnowledgeType,
		   KT.NodeSelectType,
		   KT.EvaluationType,
		   KT.Evaluators,
		   KT.PreEvaluateByOwner,
		   KT.ForceEvaluatorsDescribe,
		   KT.MinEvaluationsCount,
		   KT.SearchableAfter,
		   KT.ScoreScale,
		   KT.MinAcceptableScore,
		   KT.ConvertEvaluatorsToExperts,
		   KT.EvaluationsEditable,
		   KT.EvaluationsEditableForAdmin,
		   KT.EvaluationsRemovable,
		   KT.UnhideEvaluators,
		   KT.UnhideEvaluations,
		   KT.UnhideNodeCreators,
		   KT.EnableKnowledgeForwardingByEvaluators,
		   KT.TextOptions,
		   NT.AdditionalIDPattern
	FROM @KnowledgeTypeIDs AS Ref
		INNER JOIN [dbo].[KW_KnowledgeTypes] AS KT
		ON KT.ApplicationID = @ApplicationID AND KT.KnowledgeTypeID = Ref.Value
		INNER JOIN [dbo].[CN_NodeTypes] AS NT
		ON NT.ApplicationID = @ApplicationID AND NT.NodeTypeID = Ref.Value
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetKnowledgeTypes]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetKnowledgeTypes]
GO

CREATE PROCEDURE [dbo].[KW_GetKnowledgeTypes]
	@ApplicationID			uniqueidentifier,
	@strKnowledgeTypeIDs	varchar(max),
	@delimiter				char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @KnowledgeTypeIDs GuidTableType
	
	INSERT INTO @KnowledgeTypeIDs
	SELECT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strKnowledgeTypeIDs, @delimiter) AS Ref
	
	IF (SELECT COUNT(*) FROM @KnowledgeTypeIDs) = 1 BEGIN
		DECLARE @ID uniqueidentifier = (SELECT TOP(1) * FROM @KnowledgeTypeIDs)
		
		DELETE @KnowledgeTypeIDs
		
		INSERT INTO @KnowledgeTypeIDs (Value)
		SELECT ISNULL(
			(
				SELECT TOP(1) NodeTypeID 
				FROM [dbo].[CN_Nodes] 
				WHERE ApplicationID = @ApplicationID AND NodeID = @ID
			), @ID)
	END
	
	IF (SELECT COUNT(*) FROM @KnowledgeTypeIDs) = 0 BEGIN
		INSERT INTO @KnowledgeTypeIDs
		SELECT KnowledgeTypeID
		FROM [dbo].[KW_KnowledgeTypes]
		WHERE ApplicationID = @ApplicationID AND Deleted = 0
	END
	
	EXEC [dbo].[KW_P_GetKnowledgeTypesByIDs] @ApplicationID, @KnowledgeTypeIDs
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SetEvaluationType]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SetEvaluationType]
GO

CREATE PROCEDURE [dbo].[KW_SetEvaluationType]
	@ApplicationID		uniqueidentifier,
	@KnowledgeTypeID	uniqueidentifier,
	@EvaluationType		varchar(20)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[KW_KnowledgeTypes]
		SET EvaluationType = @EvaluationType
	WHERE ApplicationID = @ApplicationID AND KnowledgeTypeID = @KnowledgeTypeID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SetEvaluators]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SetEvaluators]
GO

CREATE PROCEDURE [dbo].[KW_SetEvaluators]
	@ApplicationID			uniqueidentifier,
	@KnowledgeTypeID		uniqueidentifier,
	@Evaluators				varchar(20),
	@MinEvaluationsCount	int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[KW_KnowledgeTypes]
		SET Evaluators = @Evaluators,
			MinEvaluationsCount = @MinEvaluationsCount
	WHERE ApplicationID = @ApplicationID AND KnowledgeTypeID = @KnowledgeTypeID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SetPreEvaluateByOwner]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SetPreEvaluateByOwner]
GO

CREATE PROCEDURE [dbo].[KW_SetPreEvaluateByOwner]
	@ApplicationID		uniqueidentifier,
	@KnowledgeTypeID	uniqueidentifier,
	@Value				bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[KW_KnowledgeTypes]
		SET PreEvaluateByOwner = @Value
	WHERE ApplicationID = @ApplicationID AND KnowledgeTypeID = @KnowledgeTypeID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SetForceEvaluatorsDescribe]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SetForceEvaluatorsDescribe]
GO

CREATE PROCEDURE [dbo].[KW_SetForceEvaluatorsDescribe]
	@ApplicationID		uniqueidentifier,
	@KnowledgeTypeID	uniqueidentifier,
	@Value				bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[KW_KnowledgeTypes]
		SET ForceEvaluatorsDescribe = @Value
	WHERE ApplicationID = @ApplicationID AND KnowledgeTypeID = @KnowledgeTypeID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SetNodeSelectType]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SetNodeSelectType]
GO

CREATE PROCEDURE [dbo].[KW_SetNodeSelectType]
	@ApplicationID		uniqueidentifier,
	@KnowledgeTypeID	uniqueidentifier,
	@NodeSelectType		varchar(20)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[KW_KnowledgeTypes]
		SET NodeSelectType = @NodeSelectType
	WHERE ApplicationID = @ApplicationID AND KnowledgeTypeID = @KnowledgeTypeID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SetSearchabilityType]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SetSearchabilityType]
GO

CREATE PROCEDURE [dbo].[KW_SetSearchabilityType]
	@ApplicationID		uniqueidentifier,
	@KnowledgeTypeID	uniqueidentifier,
	@SearchableAfter	varchar(20)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[KW_KnowledgeTypes]
		SET SearchableAfter = @SearchableAfter
	WHERE ApplicationID = @ApplicationID AND KnowledgeTypeID = @KnowledgeTypeID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SetScoreScale]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SetScoreScale]
GO

CREATE PROCEDURE [dbo].[KW_SetScoreScale]
	@ApplicationID		uniqueidentifier,
	@KnowledgeTypeID	uniqueidentifier,
	@ScoreScale			int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[KW_KnowledgeTypes]
		SET ScoreScale = @ScoreScale
	WHERE ApplicationID = @ApplicationID AND KnowledgeTypeID = @KnowledgeTypeID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SetMinAcceptableScore]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SetMinAcceptableScore]
GO

CREATE PROCEDURE [dbo].[KW_SetMinAcceptableScore]
	@ApplicationID		uniqueidentifier,
	@KnowledgeTypeID	uniqueidentifier,
	@MinAcceptableScore	float
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[KW_KnowledgeTypes]
		SET MinAcceptableScore = @MinAcceptableScore
	WHERE ApplicationID = @ApplicationID AND KnowledgeTypeID = @KnowledgeTypeID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SetEvaluationsEditable]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SetEvaluationsEditable]
GO

CREATE PROCEDURE [dbo].[KW_SetEvaluationsEditable]
	@ApplicationID		uniqueidentifier,
	@KnowledgeTypeID	uniqueidentifier,
	@Value				float
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[KW_KnowledgeTypes]
		SET EvaluationsEditable = @Value
	WHERE ApplicationID = @ApplicationID AND KnowledgeTypeID = @KnowledgeTypeID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SetEvaluationsEditableForAdmin]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SetEvaluationsEditableForAdmin]
GO

CREATE PROCEDURE [dbo].[KW_SetEvaluationsEditableForAdmin]
	@ApplicationID		uniqueidentifier,
	@KnowledgeTypeID	uniqueidentifier,
	@Value				bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[KW_KnowledgeTypes]
		SET EvaluationsEditableForAdmin = @Value
	WHERE ApplicationID = @ApplicationID AND KnowledgeTypeID = @KnowledgeTypeID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SetEvaluationsRemovable]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SetEvaluationsRemovable]
GO

CREATE PROCEDURE [dbo].[KW_SetEvaluationsRemovable]
	@ApplicationID		uniqueidentifier,
	@KnowledgeTypeID	uniqueidentifier,
	@Value				float
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[KW_KnowledgeTypes]
		SET EvaluationsRemovable = @Value
	WHERE ApplicationID = @ApplicationID AND KnowledgeTypeID = @KnowledgeTypeID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SetUnhideEvaluators]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SetUnhideEvaluators]
GO

CREATE PROCEDURE [dbo].[KW_SetUnhideEvaluators]
	@ApplicationID		uniqueidentifier,
	@KnowledgeTypeID	uniqueidentifier,
	@Value				float
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[KW_KnowledgeTypes]
		SET UnhideEvaluators = @Value
	WHERE ApplicationID = @ApplicationID AND KnowledgeTypeID = @KnowledgeTypeID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SetUnhideEvaluations]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SetUnhideEvaluations]
GO

CREATE PROCEDURE [dbo].[KW_SetUnhideEvaluations]
	@ApplicationID		uniqueidentifier,
	@KnowledgeTypeID	uniqueidentifier,
	@Value				float
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[KW_KnowledgeTypes]
		SET UnhideEvaluations = @Value
	WHERE ApplicationID = @ApplicationID AND KnowledgeTypeID = @KnowledgeTypeID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SetUnhideNodeCreators]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SetUnhideNodeCreators]
GO

CREATE PROCEDURE [dbo].[KW_SetUnhideNodeCreators]
	@ApplicationID		uniqueidentifier,
	@KnowledgeTypeID	uniqueidentifier,
	@Value				float
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[KW_KnowledgeTypes]
		SET UnhideNodeCreators = @Value
	WHERE ApplicationID = @ApplicationID AND KnowledgeTypeID = @KnowledgeTypeID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SetEnableKnowledgeForwardingByEvaluators]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SetEnableKnowledgeForwardingByEvaluators]
GO

CREATE PROCEDURE [dbo].[KW_SetEnableKnowledgeForwardingByEvaluators]
	@ApplicationID		uniqueidentifier,
	@KnowledgeTypeID	uniqueidentifier,
	@Value				bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[KW_KnowledgeTypes]
		SET EnableKnowledgeForwardingByEvaluators = @Value
	WHERE ApplicationID = @ApplicationID AND KnowledgeTypeID = @KnowledgeTypeID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SetTextOptions]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SetTextOptions]
GO

CREATE PROCEDURE [dbo].[KW_SetTextOptions]
	@ApplicationID		uniqueidentifier,
	@KnowledgeTypeID	uniqueidentifier,
	@Value				nvarchar(max)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[KW_KnowledgeTypes]
		SET TextOptions = @Value
	WHERE ApplicationID = @ApplicationID AND KnowledgeTypeID = @KnowledgeTypeID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SetConvertEvaluatorsToExperts]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SetConvertEvaluatorsToExperts]
GO

CREATE PROCEDURE [dbo].[KW_SetConvertEvaluatorsToExperts]
	@ApplicationID		uniqueidentifier,
	@KnowledgeTypeID	uniqueidentifier,
	@Value				bit
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[KW_KnowledgeTypes]
		SET ConvertEvaluatorsToExperts = ISNULL(@Value, 0)
	WHERE ApplicationID = @ApplicationID AND KnowledgeTypeID = @KnowledgeTypeID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SetCandidateRelations]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SetCandidateRelations]
GO

CREATE PROCEDURE [dbo].[KW_SetCandidateRelations]
	@ApplicationID		uniqueidentifier,
	@KnowledgeTypeID	uniqueidentifier,
	@strNodeTypeIDs		varchar(max),
	@strNodeIDs			varchar(max),
	@delimiter			char,
	@CreatorUserID		uniqueidentifier,
	@CreationDate		datetime
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE @IDs Table(NodeTypeID uniqueidentifier, NodeID uniqueidentifier)
	
	INSERT INTO @IDs (NodeTypeID)
	SELECT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strNodeTypeIDs, @delimiter) AS Ref
	
	INSERT INTO @IDs (NodeID)
	SELECT Ref.Value FROM [dbo].[GFN_StrToGuidTable](@strNodeIDs, @delimiter) AS Ref
	
	DECLARE @ExistingIDs Table(NodeTypeID uniqueidentifier, NodeID uniqueidentifier)
	
	INSERT INTO @ExistingIDs(NodeTypeID, NodeID)
	SELECT CR.NodeTypeID, CR.NodeID
	FROM @IDs AS Ref
		INNER JOIN [dbo].[KW_CandidateRelations] AS CR
		ON CR.NodeTypeID = Ref.NodeTypeID OR CR.NodeID = Ref.NodeID
	WHERE CR.ApplicationID = @ApplicationID AND CR.KnowledgeTypeID = @KnowledgeTypeID
	
	DECLARE @Count int = (SELECT COUNT(*) FROM @IDs)
	DECLARE @ExistingCount int = (SELECT COUNT(*) FROM @ExistingIDs)
	
	IF EXISTS(SELECT * FROM [dbo].[KW_CandidateRelations]
		WHERE KnowledgeTypeID = @KnowledgeTypeID) BEGIN
		
		UPDATE [dbo].[KW_CandidateRelations]
			SET LastModifierUserID = @CreatorUserID,
				LastModificationDate = @CreationDate,
				Deleted = 1
		WHERE ApplicationID = @ApplicationID AND KnowledgeTypeID = @KnowledgeTypeID
		
		IF @@ROWCOUNT <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	IF @ExistingCount > 0 BEGIN
		UPDATE CR
			SET LastModifierUserID = @CreatorUserID,
				LastModificationDate = @CreationDate,
				Deleted = 0
		FROM @ExistingIDs AS Ref
			INNER JOIN [dbo].[KW_CandidateRelations] AS CR
			ON CR.NodeTypeID = Ref.NodeTypeID OR CR.NodeID = Ref.NodeID
		WHERE CR.ApplicationID = @ApplicationID AND CR.KnowledgeTypeID = @KnowledgeTypeID
		
		IF @@ROWCOUNT <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	IF @Count > @ExistingCount BEGIN
		INSERT INTO [dbo].[KW_CandidateRelations](
			ApplicationID,
			ID,
			KnowledgeTypeID,
			NodeID,
			NodeTypeID,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		SELECT @ApplicationID, NEWID(), @KnowledgeTypeID, Ref.NodeID, Ref.NodeTypeID, 
			@CreatorUserID, @CreationDate, 0
		FROM (
				SELECT I.*
				FROM @IDs AS I
					LEFT JOIN @ExistingIDs AS E
					ON I.NodeID = E.NodeID OR I.NodeTypeID = E.NodeTypeID
				WHERE E.NodeID IS NULL AND E.NodeTypeID IS NULL
			) AS Ref
		
		IF @@ROWCOUNT <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	SELECT 1
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetCandidateNodeRelationIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetCandidateNodeRelationIDs]
GO

CREATE PROCEDURE [dbo].[KW_GetCandidateNodeRelationIDs]
	@ApplicationID					uniqueidentifier,
	@KnowledgeTypeIDOrKnowledgeID	uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @KnowledgeTypeIDOrKnowledgeID = ISNULL(
		(
			SELECT TOP(1) NodeTypeID
			FROM [dbo].[CN_Nodes]
			WHERE ApplicationID = @ApplicationID AND NodeID = @KnowledgeTypeIDOrKnowledgeID
		), @KnowledgeTypeIDOrKnowledgeID
	)
	
	SELECT NodeID AS ID
	FROM [dbo].[KW_CandidateRelations]
	WHERE ApplicationID = @ApplicationID AND 
		KnowledgeTypeID = @KnowledgeTypeIDOrKnowledgeID AND 
		NodeID IS NOT NULL AND Deleted = 0
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetCandidateNodeTypeRelationIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetCandidateNodeTypeRelationIDs]
GO

CREATE PROCEDURE [dbo].[KW_GetCandidateNodeTypeRelationIDs]
	@ApplicationID					uniqueidentifier,
	@KnowledgeTypeIDOrKnowledgeID	uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @KnowledgeTypeIDOrKnowledgeID = ISNULL(
		(
			SELECT TOP(1) NodeTypeID
			FROM [dbo].[CN_Nodes]
			WHERE ApplicationID = @ApplicationID AND NodeID = @KnowledgeTypeIDOrKnowledgeID
		), @KnowledgeTypeIDOrKnowledgeID
	)
	
	SELECT NodeTypeID AS ID
	FROM [dbo].[KW_CandidateRelations]
	WHERE ApplicationID = @ApplicationID AND 
		KnowledgeTypeID = @KnowledgeTypeIDOrKnowledgeID AND 
		NodeTypeID IS NOT NULL AND Deleted = 0
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_AddQuestion]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_AddQuestion]
GO

CREATE PROCEDURE [dbo].[KW_AddQuestion]
	@ApplicationID		uniqueidentifier,
	@ID					uniqueidentifier,
	@KnowledgeTypeID	uniqueidentifier,
	@NodeID				uniqueidentifier,
	@QuestionBody		nvarchar(2000),
	@CreatorUserID		uniqueidentifier,
	@CreationDate		datetime
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	IF @QuestionBody IS NOT NULL SET @QuestionBody = [dbo].[GFN_VerifyString](@QuestionBody)
	
	DECLARE @QuestionID uniqueidentifier = (
		SELECT QuestionID 
		FROM [dbo].[KW_Questions] 
		WHERE ApplicationID = @ApplicationID AND Title = @QuestionBody
	)
	
	IF @QuestionID IS NOT NULL AND EXISTS(
		SELECT TOP(1) *
		FROM [dbo].[KW_TypeQuestions]
		WHERE ApplicationID = @ApplicationID AND KnowledgeTypeID = @KnowledgeTypeID AND
			QuestionID = @QuestionID AND Deleted = 0
	) BEGIN
		SELECT -1, N'QuestionAlreadyExists'
		ROLLBACK TRANSACTION
		RETURN
	END
	
	IF @QuestionID IS NULL BEGIN
		SET @QuestionID = NEWID()
		
		INSERT INTO [dbo].[KW_Questions](
			ApplicationID,
			QuestionID,
			Title,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES(
			@ApplicationID,
			@QuestionID,
			@QuestionBody,
			@CreatorUserID,
			@CreationDate,
			0
		)
		
		IF @@ROWCOUNT <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	DECLARE @SequenceNumber int = (
		SELECT MAX(SequenceNumber) 
		FROM [dbo].[KW_TypeQuestions]
		WHERE ApplicationID = @ApplicationID AND KnowledgeTypeID = @KnowledgeTypeID
	)
	
	SET @SequenceNumber = ISNULL(@SequenceNumber, 0) + 1
	
	INSERT INTO [dbo].[KW_TypeQuestions](
		ApplicationID,
		ID,
		KnowledgeTypeID,
		QuestionID,
		NodeID,
		SequenceNumber,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	VALUES(
		@ApplicationID,
		@ID,
		@KnowledgeTypeID,
		@QuestionID,
		@NodeID,
		@SequenceNumber,
		@CreatorUserID,
		@CreationDate,
		0
	)
	
	IF @@ROWCOUNT <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	SELECT 1
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_ModifyQuestion]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_ModifyQuestion]
GO

CREATE PROCEDURE [dbo].[KW_ModifyQuestion]
	@ApplicationID			uniqueidentifier,
	@ID						uniqueidentifier,
	@QuestionBody			nvarchar(2000),
	@LastModifierUserID		uniqueidentifier,
	@LastModificationDate	datetime
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	IF @QuestionBody IS NOT NULL SET @QuestionBody = [dbo].[GFN_VerifyString](@QuestionBody)
	
	DECLARE @QuestionID uniqueidentifier = (
		SELECT TOP(1) QuestionID 
		FROM [dbo].[KW_Questions] 
		WHERE ApplicationID = @ApplicationID AND Title = @QuestionBody AND Deleted = 0
	)
	
	IF @QuestionID IS NULL BEGIN
		SET @QuestionID = NEWID()
		
		INSERT INTO [dbo].[KW_Questions](
			ApplicationID,
			QuestionID,
			Title,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES(
			@ApplicationID,
			@QuestionID,
			@QuestionBody,
			@LastModifierUserID,
			@LastModificationDate,
			0
		)
		
		IF @@ROWCOUNT <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	UPDATE [dbo].[KW_TypeQuestions]
		SET QuestionID = @QuestionID,
			LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate
	WHERE ApplicationID = @ApplicationID AND ID = @ID
	
	IF @@ROWCOUNT <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	SELECT 1
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SetQuestionsOrder]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SetQuestionsOrder]
GO

CREATE PROCEDURE [dbo].[KW_SetQuestionsOrder]
	@ApplicationID	uniqueidentifier,
	@strIDs			varchar(max),
	@delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @IDs TABLE (SequenceNo int identity(1, 1) primary key, ID uniqueidentifier)
	
	INSERT INTO @IDs (ID)
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strIDs, @delimiter) AS Ref
	
	DECLARE @KnowledgeTypeID uniqueidentifier = NULL, @NodeID uniqueidentifier = NULL
	
	SELECT @KnowledgeTypeID = KnowledgeTypeID, @NodeID = NodeID
	FROM [dbo].[KW_TypeQuestions]
	WHERE ApplicationID = @ApplicationID AND 
		ID = (SELECT TOP (1) Ref.ID FROM @IDs AS Ref)
	
	IF @KnowledgeTypeID IS NULL BEGIN
		SELECT -1
		RETURN
	END
	
	INSERT INTO @IDs (ID)
	SELECT TQ.ID
	FROM @IDs AS Ref
		RIGHT JOIN [dbo].[KW_TypeQuestions] AS TQ
		ON TQ.ID = Ref.ID
	WHERE TQ.ApplicationID = @ApplicationID AND TQ.KnowledgeTypeID = @KnowledgeTypeID AND 
		((@NodeID IS NULL AND TQ.NodeID IS NULL) OR TQ.NodeID = @NodeID) AND Ref.ID IS NULL
	ORDER BY TQ.SequenceNumber
	
	UPDATE TQ
		SET SequenceNumber = Ref.SequenceNo
	FROM @IDs AS Ref
		INNER JOIN [dbo].[KW_TypeQuestions] AS TQ
		ON TQ.ID = Ref.ID
	WHERE TQ.ApplicationID = @ApplicationID AND TQ.KnowledgeTypeID = @KnowledgeTypeID AND 
		((@NodeID IS NULL AND TQ.NodeID IS NULL) OR TQ.NodeID = @NodeID)
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SetQuestionWeight]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SetQuestionWeight]
GO

CREATE PROCEDURE [dbo].[KW_SetQuestionWeight]
	@ApplicationID	uniqueidentifier,
	@ID				uniqueidentifier,
	@Weight			float
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF @Weight <= 0 SET @Weight = NULL
	
	UPDATE [dbo].[KW_TypeQuestions]
		SET [Weight] = @Weight
	WHERE ApplicationID = @ApplicationID AND ID = @ID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_ArithmeticDeleteQuestion]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_ArithmeticDeleteQuestion]
GO

CREATE PROCEDURE [dbo].[KW_ArithmeticDeleteQuestion]
	@ApplicationID			uniqueidentifier,
	@ID						uniqueidentifier,
	@LastModifierUserID		uniqueidentifier,
	@LastModificationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[KW_TypeQuestions]
		SET LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate,
			Deleted = 1
	WHERE ApplicationID = @ApplicationID AND ID = @ID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_ArithmeticDeleteRelatedNodeQuestions]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_ArithmeticDeleteRelatedNodeQuestions]
GO

CREATE PROCEDURE [dbo].[KW_ArithmeticDeleteRelatedNodeQuestions]
	@ApplicationID			uniqueidentifier,
	@KnowledgeTypeID		uniqueidentifier,
	@NodeID					uniqueidentifier,
	@LastModifierUserID		uniqueidentifier,
	@LastModificationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[KW_TypeQuestions]
		SET LastModifierUserID = @LastModifierUserID,
			LastModificationDate = @LastModificationDate,
			Deleted = 1
	WHERE ApplicationID = @ApplicationID AND 
		KnowledgeTypeID = @KnowledgeTypeID AND NodeID = @NodeID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_AddAnswerOption]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_AddAnswerOption]
GO

CREATE PROCEDURE [dbo].[KW_AddAnswerOption]
	@ApplicationID			uniqueidentifier,
	@ID						uniqueidentifier,
	@TypeQuestionID			uniqueidentifier,
	@Title					nvarchar(2000),
	@Value					float,
	@CurrentUserID			uniqueidentifier,
	@Now					datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF @Value IS NULL OR @Value < 0 OR @Value > 10 OR EXISTS(
		SELECT TOP(1) ID
		FROM [dbo].[KW_AnswerOptions]
		WHERE ApplicationID = @ApplicationID AND TypeQuestionID = @TypeQuestionID AND 
			Deleted = 0 AND Value = @Value
	) BEGIN
		SELECT -1, N'AnswerOptionValueIsNotValid'
		RETURN
	END
	
	DECLARE @SeqNo int = ISNULL(
		(
			SELECT MAX(SequenceNumber)
			FROM [dbo].[KW_AnswerOptions]
			WHERE ApplicationID = @ApplicationID AND 
				TypeQuestionID = @TypeQuestionID AND Deleted = 0
		), 0) + 1
	
	INSERT INTO [dbo].[KW_AnswerOptions] (
		ApplicationID,
		ID,
		TypeQuestionID,
		Title,
		Value,
		SequenceNumber,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	VALUES (
		@ApplicationID,
		@ID,
		@TypeQuestionID,
		@Title,
		@Value,
		@SeqNo,
		@CurrentUserID,
		@Now,
		0
	)
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_ModifyAnswerOption]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_ModifyAnswerOption]
GO

CREATE PROCEDURE [dbo].[KW_ModifyAnswerOption]
	@ApplicationID			uniqueidentifier,
	@ID						uniqueidentifier,
	@Title					nvarchar(2000),
	@Value					float,
	@CurrentUserID			uniqueidentifier,
	@Now					datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @TypeQuestionID uniqueidentifier = (
		SELECT TOP(1) TypeQuestionID
		FROM [dbo].[KW_AnswerOptions]
		WHERE ApplicationID = @ApplicationID AND ID = @ID
	)
	
	IF @Value IS NULL OR @Value < 0 OR @Value > 10 OR EXISTS(
		SELECT TOP(1) ID
		FROM [dbo].[KW_AnswerOptions]
		WHERE ApplicationID = @ApplicationID AND TypeQuestionID = @TypeQuestionID AND 
			Deleted = 0 AND ID <> @ID AND Value = @Value
	) BEGIN
		SELECT -1, N'AnswerOptionValueIsNotValid'
		RETURN
	END
	
	UPDATE [dbo].[KW_AnswerOptions]
		SET Title = @Title,
			Value = @Value,
			LastModifierUserID = @CurrentUserID,
			LastModificationDate = @Now
	WHERE ApplicationID = @ApplicationID AND ID = @ID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SetAnswerOptionsOrder]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SetAnswerOptionsOrder]
GO

CREATE PROCEDURE [dbo].[KW_SetAnswerOptionsOrder]
	@ApplicationID	uniqueidentifier,
	@strIDs			varchar(max),
	@delimiter		char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @IDs TABLE (SequenceNo int identity(1, 1) primary key, ID uniqueidentifier)
	
	INSERT INTO @IDs (ID)
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strIDs, @delimiter) AS Ref
	
	DECLARE @QuestionID uniqueidentifier
	
	SELECT @QuestionID = TypeQuestionID
	FROM [dbo].[KW_AnswerOptions]
	WHERE ApplicationID = @ApplicationID AND 
		ID = (SELECT TOP (1) Ref.ID FROM @IDs AS Ref)
	
	IF @QuestionID IS NULL BEGIN
		SELECT -1
		RETURN
	END
	
	INSERT INTO @IDs (ID)
	SELECT AO.ID
	FROM @IDs AS Ref
		RIGHT JOIN [dbo].[KW_AnswerOptions] AS AO
		ON AO.ID = Ref.ID
	WHERE AO.ApplicationID = @ApplicationID AND AO.TypeQuestionID = @QuestionID AND Ref.ID IS NULL
	ORDER BY AO.SequenceNumber
	
	UPDATE AO
		SET SequenceNumber = Ref.SequenceNo
	FROM @IDs AS Ref
		INNER JOIN [dbo].[KW_AnswerOptions] AS AO
		ON AO.ID = Ref.ID
	WHERE AO.ApplicationID = @ApplicationID AND AO.TypeQuestionID = @QuestionID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_ArithmeticDeleteAnswerOption]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_ArithmeticDeleteAnswerOption]
GO

CREATE PROCEDURE [dbo].[KW_ArithmeticDeleteAnswerOption]
	@ApplicationID			uniqueidentifier,
	@ID						uniqueidentifier,
	@CurrentUserID			uniqueidentifier,
	@Now					datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[KW_AnswerOptions]
		SET LastModifierUserID = @CurrentUserID,
			LastModificationDate = @Now,
			Deleted = 1
	WHERE ApplicationID = @ApplicationID AND ID = @ID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetQuestions]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetQuestions]
GO

CREATE PROCEDURE [dbo].[KW_GetQuestions]
	@ApplicationID		uniqueidentifier,
	@KnowledgeTypeID	uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT	TQ.ID, 
			TQ.KnowledgeTypeID, 
			TQ.QuestionID, 
			Q.Title AS QuestionBody,
			ND.NodeID AS RelatedNodeID,
			ND.Name AS RelatedNodeName,
			TQ.[Weight]
	FROM [dbo].[KW_TypeQuestions] AS TQ
		INNER JOIN [dbo].[KW_Questions] AS Q
		ON Q.ApplicationID = @ApplicationID AND Q.QuestionID = TQ.QuestionID
		LEFT JOIN [dbo].[CN_Nodes] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.NodeID = TQ.NodeID
	WHERE TQ.ApplicationID = @ApplicationID AND TQ.KnowledgeTypeID = @KnowledgeTypeID AND 
		(ND.NodeID IS NULL OR ND.Deleted = 0) AND TQ.Deleted = 0
	ORDER BY TQ.SequenceNumber
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SearchQuestions]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SearchQuestions]
GO

CREATE PROCEDURE [dbo].[KW_SearchQuestions]
	@ApplicationID		uniqueidentifier,
	@SearchText			nvarchar(1000),
	@Count				int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @SearchText = [dbo].[GFN_VerifyString](@SearchText)
	
	DECLARE @_ST nvarchar(1000) = @SearchText
	IF @SearchText IS NULL OR @SearchText = N'' SET @_ST = NULL
	
	IF @Count IS NULL OR @Count <= 0 SET @Count = 1000000000
	
	IF @_ST IS NULL BEGIN
		SELECT TOP(@Count) Title AS Value
		FROM [dbo].[KW_Questions]
		WHERE ApplicationID = @ApplicationID AND Deleted = 0
	END
	ELSE BEGIN
		SELECT TOP(@Count) Title AS Value
		FROM CONTAINSTABLE([dbo].[KW_Questions], [Title], @_ST) AS SRCH
			INNER JOIN [dbo].[KW_Questions] AS Q
			ON Q.QuestionID = [SRCH].[Key]
		WHERE Q.ApplicationID = @ApplicationID AND Deleted = 0
		ORDER BY SRCH.[Rank] DESC
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetAnswerOptions]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetAnswerOptions]
GO

CREATE PROCEDURE [dbo].[KW_GetAnswerOptions]
	@ApplicationID		uniqueidentifier,
	@strTypeQuestionIDs	varchar(max),
	@delimiter			char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @TypeQuestionIDs GuidTableType
	
	INSERT INTO @TypeQuestionIDs (Value)
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strTypeQuestionIDs, @delimiter) AS Ref
	
	SELECT	AO.ID,
			AO.TypeQuestionID, 
			AO.Title,
			AO.Value
	FROM @TypeQuestionIDs AS IDs
		INNER JOIN [dbo].[KW_TypeQuestions] AS TQ
		ON TQ.ApplicationID = @ApplicationID AND TQ.ID = IDs.Value
		INNER JOIN [dbo].[KW_AnswerOptions] AS AO
		ON AO.ApplicationID = @ApplicationID AND AO.TypeQuestionID = TQ.ID
	WHERE TQ.Deleted = 0 AND AO.Deleted = 0
	ORDER BY AO.TypeQuestionID ASC, AO.SequenceNumber ASC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetFilledEvaluationForm]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetFilledEvaluationForm]
GO

CREATE PROCEDURE [dbo].[KW_GetFilledEvaluationForm]
	@ApplicationID		uniqueidentifier,
    @KnowledgeID		uniqueidentifier,
    @UserID				uniqueidentifier,
    @WFVersionID		int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @ScoreScale int = (
		SELECT TOP(1) ScoreScale
		FROM [dbo].[CN_Nodes] AS ND
			INNER JOIN [dbo].[KW_KnowledgeTypes] AS KT
			ON KT.ApplicationID = @ApplicationID AND KT.KnowledgeTypeID = ND.NodeTypeID
		WHERE ND.ApplicationID = @ApplicationID AND ND.NodeID = @KnowledgeID
	)
	
	DECLARE @Coeff float = CAST(ISNULL(@ScoreScale, 10) AS float) / 10.0
	
	DECLARE @LastWFVersionID int = [dbo].[KW_FN_GetWFVersionID](@ApplicationID, @KnowledgeID)
	
	IF @WFVersionID IS NULL OR @WFVersionID = @LastWFVersionID BEGIN
		SELECT	QA.QuestionID,
				QA.Title,
				O.Title AS TextValue,
				ISNULL(QA.AdminScore, QA.Score) * @Coeff AS Score,
				QA.EvaluationDate
		FROM [dbo].[KW_QuestionAnswers] AS QA
			INNER JOIN [dbo].[CN_Nodes] AS ND
			ON ND.ApplicationID = @ApplicationID AND ND.NodeID = QA.KnowledgeID
			LEFT JOIN [dbo].[KW_AnswerOptions] AS O
			ON O.ApplicationID = @ApplicationID AND O.ID = QA.SelectedOptionID
			LEFT JOIN [dbo].[KW_TypeQuestions] AS Q
			ON Q.ApplicationID = @ApplicationID AND 
				Q.KnowledgeTypeID = ND.NodeTypeID AND Q.QuestionID = QA.QuestionID
		WHERE QA.ApplicationID = @ApplicationID AND QA.KnowledgeID = @KnowledgeID AND 
			QA.UserID = @UserID AND QA.Deleted = 0
		ORDER BY Q.SequenceNumber ASC
	END
	ELSE BEGIN
		SELECT	QA.QuestionID,
				QA.Title,
				O.Title AS TextValue,
				ISNULL(QA.AdminScore, QA.Score) * @Coeff AS Score,
				QA.EvaluationDate
		FROM [dbo].[KW_QuestionAnswersHistory] AS QA
			INNER JOIN [dbo].[CN_Nodes] AS ND
			ON ND.ApplicationID = @ApplicationID AND ND.NodeID = QA.KnowledgeID
			LEFT JOIN [dbo].[KW_AnswerOptions] AS O
			ON O.ApplicationID = @ApplicationID AND O.ID = QA.SelectedOptionID
			LEFT JOIN [dbo].[KW_TypeQuestions] AS Q
			ON Q.ApplicationID = @ApplicationID AND 
				Q.KnowledgeTypeID = ND.NodeTypeID AND Q.QuestionID = QA.QuestionID
		WHERE QA.ApplicationID = @ApplicationID AND QA.KnowledgeID = @KnowledgeID AND 
			QA.UserID = @UserID AND QA.Deleted = 0 AND QA.WFVersionID = @WFVersionID
		ORDER BY Q.SequenceNumber ASC
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_P_CalculateKnowledgeScore]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_P_CalculateKnowledgeScore]
GO

CREATE PROCEDURE [dbo].[KW_P_CalculateKnowledgeScore]
	@ApplicationID		uniqueidentifier,
    @KnowledgeID		uniqueidentifier,
    @_Result			int output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @DateFrom datetime = (
		SELECT TOP(1) MIN(H.ActionDate)
		FROM [dbo].[KW_History] AS H
		WHERE H.ApplicationID = @ApplicationID AND
			H.KnowledgeID = @KnowledgeID AND H.[Action] = N'SendToAdmin'
	)
	
	DECLARE @Score float = 0
	
	IF EXISTS(
		SELECT TOP(1) *
		FROM [dbo].[KW_QuestionAnswers] AS QA
			LEFT JOIN [dbo].[CN_Nodes] AS ND
			INNER JOIN [dbo].[KW_TypeQuestions] AS TQ
			ON TQ.ApplicationID = @ApplicationID AND 
				TQ.KnowledgeTypeID = ND.NodeTypeID AND TQ.Deleted = 0
			ON ND.ApplicationID = @ApplicationID AND ND.NodeID = @KnowledgeID AND
				ND.NodeID = QA.KnowledgeID
		WHERE QA.ApplicationID = @ApplicationID AND QA.KnowledgeID = @KnowledgeID AND 
			QA.Deleted = 0 AND (TQ.[Weight] IS NULL OR TQ.[Weight] <= 0)
	) BEGIN
		SELECT TOP(1) @Score = (SUM(Ref.Score) / ISNULL(COUNT(Ref.UserID), 1))
		FROM (
				SELECT	QA.UserID, 
						SUM(ISNULL(ISNULL(QA.AdminScore, QA.Score), 0)) / ISNULL(COUNT(QA.QuestionID), 1) AS Score
				FROM [dbo].[KW_QuestionAnswers] AS QA
				WHERE QA.ApplicationID = @ApplicationID AND 
					QA.KnowledgeID = @KnowledgeID AND QA.Deleted = 0 AND
					(@DateFrom IS NULL OR QA.EvaluationDate > @DateFrom)
				GROUP BY QA.UserID
			) AS Ref
	END
	ELSE BEGIN
		SELECT TOP(1) @Score = (SUM(Ref.Score) / ISNULL(COUNT(Ref.UserID), 1))
		FROM (
				SELECT	QA.UserID,
						SUM((TQ.[Weight] * ISNULL(ISNULL(QA.AdminScore, QA.Score), 0))) / SUM(TQ.[Weight]) AS Score
				FROM [dbo].[KW_QuestionAnswers] AS QA
					INNER JOIN [dbo].[CN_Nodes] AS ND
					INNER JOIN [dbo].[KW_TypeQuestions] AS TQ
					ON TQ.ApplicationID = @ApplicationID AND 
						TQ.KnowledgeTypeID = ND.NodeTypeID AND TQ.Deleted = 0
					ON ND.ApplicationID = @ApplicationID AND ND.NodeID = @KnowledgeID AND
						ND.NodeID = QA.KnowledgeID
				WHERE QA.ApplicationID = @ApplicationID AND 
					QA.KnowledgeID = @KnowledgeID AND QA.Deleted = 0 AND
					(@DateFrom IS NULL OR QA.EvaluationDate > @DateFrom)
				GROUP BY QA.UserID
			) AS Ref
	END
	
	UPDATE [dbo].[CN_Nodes]
		SET Score = @Score
	WHERE ApplicationID = @ApplicationID AND NodeID = @KnowledgeID
	
	SET @_Result = @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetEvaluationsDone]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetEvaluationsDone]
GO

CREATE PROCEDURE [dbo].[KW_GetEvaluationsDone]
	@ApplicationID		uniqueidentifier,
    @KnowledgeID		uniqueidentifier,
    @WFVersionID		int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @DateFrom datetime = (
		SELECT TOP(1) MIN(H.ActionDate)
		FROM [dbo].[KW_History] AS H
		WHERE H.ApplicationID = @ApplicationID AND
			H.KnowledgeID = @KnowledgeID AND H.[Action] = N'SendToAdmin'
	)
	
	DECLARE @LastVersionID int = [dbo].[KW_FN_GetWFVersionID](@ApplicationID, @KnowledgeID)
	
	SELECT *
	FROM (
			SELECT	Ref.UserID,
					UN.UserName,
					UN.FirstName,
					UN.LastName,
					UN.AvatarName,
					UN.UseAvatar,
					Ref.Score,
					Ref.EvaluationDate,
					@LastVersionID AS WFVersionID
			FROM (
					SELECT A.UserID, (SUM(ISNULL(ISNULL(A.AdminScore, A.Score), 0)) / ISNULL(COUNT(A.UserID), 1)) AS Score,
						MAX(A.EvaluationDate) AS EvaluationDate
					FROM [dbo].[KW_QuestionAnswers] AS A
					WHERE A.ApplicationID = @ApplicationID AND 
						A.KnowledgeID = @KnowledgeID AND A.Deleted = 0 AND
						(@DateFrom IS NULL OR A.EvaluationDate > @DateFrom)
					GROUP BY A.UserID
				) AS Ref
				LEFT JOIN [dbo].[Users_Normal] AS UN
				ON UN.ApplicationID = @ApplicationID AND UN.UserID = Ref.UserID
			WHERE @WFVersionID IS NULL OR @LastVersionID = @WFVersionID
	
			UNION ALL
	
			SELECT	Ref.UserID,
					UN.UserName,
					UN.FirstName,
					UN.LastName,
					UN.AvatarName,
					UN.UseAvatar,
					Ref.Score,
					Ref.EvaluationDate,
					Ref.WFVersionID
			FROM (
					SELECT A.UserID, (SUM(ISNULL(ISNULL(A.AdminScore, A.Score), 0)) / ISNULL(COUNT(A.UserID), 1)) AS Score,
						MAX(A.EvaluationDate) AS EvaluationDate, A.WFVersionID
					FROM [dbo].[KW_QuestionAnswersHistory] AS A
					WHERE A.ApplicationID = @ApplicationID AND 
						A.KnowledgeID = @KnowledgeID AND A.Deleted = 0 AND
						(@DateFrom IS NULL OR A.EvaluationDate > @DateFrom) AND
						(@WFVersionID IS NULL OR A.WFVersionID = @WFVersionID)
					GROUP BY A.UserID, A.WFVersionID
				) AS Ref
				LEFT JOIN [dbo].[Users_Normal] AS UN
				ON UN.ApplicationID = @ApplicationID AND UN.UserID = Ref.UserID
		) AS X
	ORDER BY X.WFVersionID DESC, X.EvaluationDate DESC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_HasEvaluated]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_HasEvaluated]
GO

CREATE PROCEDURE [dbo].[KW_HasEvaluated]
	@ApplicationID	uniqueidentifier,
    @KnowledgeID	uniqueidentifier,
    @UserID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(1) CAST(1 AS bit)
	FROM [dbo].[KW_QuestionAnswers] AS A
	WHERE A.ApplicationID = @ApplicationID AND A.KnowledgeID = @KnowledgeID AND 
		A.UserID = @UserID AND A.Deleted = 0
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_P_AutoSetKnowledgeStatus]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_P_AutoSetKnowledgeStatus]
GO

CREATE PROCEDURE [dbo].[KW_P_AutoSetKnowledgeStatus]
	@ApplicationID				uniqueidentifier,
    @NodeID						uniqueidentifier,
    @Now						datetime,
    @_SearchabilityActivated	bit output,
    @_Accepted					bit output,
    @_Result					int output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @_SearchabilityActivated = 0
	SET @_Accepted = 0
	
	DECLARE @EvaluatorsCount int, @CurEvaluatorsCount int, @MinEvaluatorsCount int
	
	EXEC [dbo].[NTFN_P_GetDashboardsCount] @ApplicationID, NULL, @NodeID, NULL, 
		N'Knowledge', N'Evaluator', @EvaluatorsCount output
	
	SELECT TOP(1) @MinEvaluatorsCount = KT.MinEvaluationsCount
	FROM [dbo].[CN_Nodes] AS ND
		INNER JOIN [dbo].[KW_KnowledgeTypes] AS KT
		ON KT.ApplicationID = @ApplicationID AND KT.KnowledgeTypeID = ND.NodeTypeID
	WHERE ND.ApplicationID = @ApplicationID AND ND.NodeID = @NodeID
	
	SET @CurEvaluatorsCount = ISNULL(
		(
			SELECT TOP(1) COUNT(DISTINCT UserID)
			FROM [dbo].[KW_QuestionAnswers] AS QA
			WHERE QA.ApplicationID = @ApplicationID AND 
				QA.KnowledgeID = @NodeID AND QA.Deleted = 0
			GROUP BY QA.UserID
		), 0
	)
	
	IF @MinEvaluatorsCount IS NULL OR @MinEvaluatorsCount <= 0 OR 
		@MinEvaluatorsCount > (@EvaluatorsCount + @CurEvaluatorsCount) 
		SET @MinEvaluatorsCount = @EvaluatorsCount + @CurEvaluatorsCount
	
	IF @CurEvaluatorsCount >= @MinEvaluatorsCount BEGIN
		EXEC [dbo].[NTFN_P_ArithmeticDeleteDashboards] @ApplicationID, 
			NULL, @NodeID, NULL, N'Knowledge', NULL, @_Result output
			
		IF @_Result <= 0 RETURN
	
		DECLARE @St varchar(50), @Sc float
		
		SELECT TOP(1) @St = ND.[Status], @Sc = ND.Score
		FROM [dbo].[CN_Nodes] AS ND 
		WHERE ND.ApplicationID = @ApplicationID AND ND.NodeID = @NodeID
		
		DECLARE @Acceptable bit = (
			SELECT TOP(1) 
				CASE
					WHEN ISNULL(@Sc, 0) >= (
							(ISNULL(KT.MinAcceptableScore, 0) * 10) / 
							ISNULL(CASE WHEN KT.ScoreScale = 0 THEN 1 ELSE KT.ScoreScale END, 1)
						) THEN CAST(1 AS bit)
					ELSE CAST(0 AS bit)
				END
			FROM [dbo].[CN_Nodes] AS ND
				INNER JOIN [dbo].[KW_KnowledgeTypes] AS KT
				ON KT.ApplicationID = @ApplicationID AND KT.KnowledgeTypeID = ND.NodeTypeID
			WHERE ND.ApplicationID = @ApplicationID AND ND.NodeID = @NodeID
		)
		
		IF (@Acceptable = 1 AND @St <> N'Accepted') OR 
			(ISNULL(@Acceptable, 0) = 0 AND @St <> N'Rejected') BEGIN
			UPDATE [dbo].[CN_Nodes]
				SET [Status] = CASE WHEN @Acceptable = 1 THEN N'Accepted' ELSE N'Rejected' END,
					[PublicationDate] = @Now
			WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID
			
			IF @Acceptable = 1 SET @_Accepted = 1
		END
		
		DECLARE @IsSearchable bit = (
			SELECT TOP(1) ND.Searchable
			FROM [dbo].[CN_Nodes] AS ND 
			WHERE ND.ApplicationID = @ApplicationID AND ND.NodeID = @NodeID
		)
		
		IF ISNULL(@IsSearchable, 0) = 0 AND @_Accepted = 1 BEGIN
			UPDATE [dbo].[CN_Nodes]
				SET Searchable = 1
			WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID
			
			-- Set searchability of previous version
			/*
			DECLARE @PreviousVersionID uniqueidentifier = (
				SELECT TOP(1) PreviousVersionID
				FROM [dbo].[CN_Nodes]
				WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID
			)
			
			IF @PreviousVersionID IS NOT NULL BEGIN
				UPDATE [dbo].[CN_Nodes]
					SET [Searchable] = 0
				WHERE ApplicationID = @ApplicationID AND NodeID = @PreviousVersionID
			END
			*/
			-- end of Set searchability of previous version
			
			SET @_SearchabilityActivated = 1
		END
	END
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_P_AcceptRejectKnowledge]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_P_AcceptRejectKnowledge]
GO

CREATE PROCEDURE [dbo].[KW_P_AcceptRejectKnowledge]
	@ApplicationID	uniqueidentifier,
    @NodeID			uniqueidentifier,
    @Accept			bit,
    @_Result		int output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Searchable bit = CAST((CASE WHEN @Accept = 1 THEN 1 ELSE 0 END) AS bit)
	
	UPDATE [dbo].[CN_Nodes]
		SET [Status] = CASE WHEN @Accept = 1 THEN N'Accepted' ELSE N'Rejected' END,
			[Searchable] = @Searchable
	WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID
	
	IF @@ROWCOUNT <= 0 BEGIN
		SET @_Result = -1
		RETURN
	END
	
	IF @Searchable = 1 BEGIN
		DECLARE @PreviousVersionID uniqueidentifier = (
			SELECT TOP(1) PreviousVersionID
			FROM [dbo].[CN_Nodes]
			WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID
		)
		
		IF @PreviousVersionID IS NOT NULL BEGIN
			UPDATE [dbo].[CN_Nodes]
				SET [Searchable] = 0
			WHERE ApplicationID = @ApplicationID AND NodeID = @PreviousVersionID
		END
	END
	
	EXEC [dbo].[NTFN_P_ArithmeticDeleteDashboards] @ApplicationID, 
		NULL, @NodeID, NULL, N'Knowledge', NULL, @_Result output
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_AcceptRejectKnowledge]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_AcceptRejectKnowledge]
GO

CREATE PROCEDURE [dbo].[KW_AcceptRejectKnowledge]
	@ApplicationID	uniqueidentifier,
    @NodeID			uniqueidentifier,
    @CurrentUserID	uniqueidentifier,
    @Accept			bit,
    @TextOptions	nvarchar(1000),
    @Description	nvarchar(2000),
    @Now			datetime
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE @_Result int
	
	EXEC [dbo].[KW_P_AcceptRejectKnowledge] @ApplicationID, @NodeID, @Accept, @_Result output
	
	IF @_Result <= 0 BEGIN
		SELECT @_Result
		ROLLBACK TRANSACTION
		RETURN
	END
	
	-- Create history
	INSERT INTO [dbo].[KW_History](
		ApplicationID,
		KnowledgeID,
		[Action],
		TextOptions,
		[Description],
		ActorUserID,
		ActionDate,
		WFVersionID,
		UniqueID
	)
	VALUES(
		@ApplicationID,
		@NodeID,
		CASE WHEN ISNULL(@Accept, 0) = 1 THEN N'Accept' ELSE N'Reject' END,
		@TextOptions,
		@Description,
		@CurrentUserID,
		@Now,
		[dbo].[KW_FN_GetWFVersionID](@ApplicationID, @NodeID),
		NEWID()
	)
	
	IF @@ROWCOUNT <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of create history
	
	SELECT 1
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SendToAdmin]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SendToAdmin]
GO

CREATE PROCEDURE [dbo].[KW_SendToAdmin]
	@ApplicationID		uniqueidentifier,
    @NodeID				uniqueidentifier,
    @CurrentUserID		uniqueidentifier,
    @strAdminUserIDs	varchar(max),
    @delimiter			char,
    @Description		nvarchar(2000),
    @Now				datetime
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	/* Steps: */
	-- 1: Set knowledge status to 'SentToAdmin'
	-- 2: Create history
	-- 3: Send old evaluations to history
	-- 4: Remove all existing dashboards
	-- 5: Send new dashboards to admins
	
	-- Find AdminIDs
	DECLARE @AdminUserIDs GuidTableType
	
	INSERT INTO @AdminUserIDs
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strAdminUserIDs, @delimiter) AS Ref
	-- end of Find AdminIDs
	
	
	-- Check if is new workflow
	DECLARE @IsNewVersion bit = 0
	
	IF EXISTS(
		SELECT TOP(1) ND.NodeID
		FROM [dbo].[CN_Nodes] AS ND
		WHERE ND.ApplicationID = @ApplicationID AND ND.NodeID = @NodeID AND ND.[Status] = N'Rejected'
	) SET @IsNewVersion = 1
	
	DECLARE @WFVersionID int = [dbo].[KW_FN_GetWFVersionID](@ApplicationID, @NodeID)
	DECLARE @NewWFVersionID int = @WFVersionID + (CASE WHEN @IsNewVersion = 1 THEN 1 ELSE 0 END)
	-- end of Check if is new workflow
	
	
	-- Set new knowledge status
	UPDATE [dbo].[CN_Nodes]
		SET [Status] = N'SentToAdmin'
	WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID
	
	IF @@ROWCOUNT <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of set new knowledge status
	
	
	-- Create history
	INSERT INTO [dbo].[KW_History](
		ApplicationID,
		KnowledgeID,
		[Action],
		[Description],
		ActorUserID,
		ActionDate,
		WFVersionID,
		UniqueID
	)
	VALUES(
		@ApplicationID,
		@NodeID,
		N'SendToAdmin',
		@Description,
		@CurrentUserID,
		@Now,
		@NewWFVersionID,
		NEWID()
	)
	
	IF @@ROWCOUNT <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of create history
	
	-- send old evaluations to history
	
	DECLARE @VersionID uniqueidentifier = NEWID()
	
	INSERT INTO [dbo].[KW_QuestionAnswersHistory] (ApplicationID, VersionID, KnowledgeID, UserID, QuestionID,  Title, Score, 
		EvaluationDate, Deleted, SelectedOptionID, VersionDate, AdminScore, AdminSelectedOptionID, AdminID, WFVersionID)
	SELECT A.ApplicationID, @VersionID, A.KnowledgeID, A.UserID, A.QuestionID, A.Title, A.Score, 
		A.EvaluationDate, A.Deleted, A.SelectedOptionID, @Now, A.AdminScore, A.AdminSelectedOptionID, A.AdminID, @WFVersionID
	FROM [dbo].[KW_QuestionAnswers] AS A
	WHERE A.ApplicationID = @ApplicationID AND A.KnowledgeID = @NodeID
	
	DELETE [dbo].[KW_QuestionAnswers]
	WHERE ApplicationID = @ApplicationID AND KnowledgeID = @NodeID 
	
	-- end of send old evaluations to history
	
	DECLARE @_Result int
	
	-- Remove all existing dashboards
	EXEC [dbo].[NTFN_P_ArithmeticDeleteDashboards] @ApplicationID, 
		NULL, @NodeID, NULL, NULL, NULL, @_Result output
	
	IF @_Result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of remove all existing dashboards
	
	-- Send new dashboards
	DECLARE @Dashboards DashboardTableType
	
	INSERT INTO @Dashboards(UserID, NodeID, RefItemID, [Type], SubType, Removable, SendDate, Info)
	SELECT	Ref.Value, 
			@NodeID,
			@NodeID,
			N'Knowledge',
			N'Admin',
			0,
			@Now,
			N'{"WFVersionID":' + CAST(@NewWFVersionID AS nvarchar(50)) + N'}'
	FROM @AdminUserIDs AS Ref
	
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
	-- end of send new dashboards
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SendBackForRevision]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SendBackForRevision]
GO

CREATE PROCEDURE [dbo].[KW_SendBackForRevision]
	@ApplicationID		uniqueidentifier,
    @NodeID				uniqueidentifier,
    @CurrentUserID		uniqueidentifier,
    @TextOptions		nvarchar(1000),
    @Description		nvarchar(2000),
    @Now				datetime
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	/* Steps: */
	-- 1: Set knowledge status to 'SentBackForRevision'
	-- 2: Create history
	-- 3: Set current user's admin dashboard as done
	-- 4: Remove all existing dashboards
	-- 5: Send new dashboards to admins
	
	-- Set new knowledge status
	UPDATE [dbo].[CN_Nodes]
		SET [Status] = N'SentBackForRevision'
	WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID
	
	IF @@ROWCOUNT <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of set new knowledge status
	
	-- Create history
	INSERT INTO [dbo].[KW_History](
		ApplicationID,
		KnowledgeID,
		[Action],
		TextOptions,
		[Description],
		ActorUserID,
		ActionDate,
		WFVersionID,
		UniqueID
	)
	VALUES(
		@ApplicationID,
		@NodeID,
		N'SendBackForRevision',
		@TextOptions,
		@Description,
		@CurrentUserID,
		@Now,
		[dbo].[KW_FN_GetWFVersionID](@ApplicationID, @NodeID),
		NEWID()
	)
	
	IF @@ROWCOUNT <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of create history
	
	DECLARE @_Result int
	
	-- Set dashboards as done
	EXEC [dbo].[NTFN_P_SetDashboardsAsDone] @ApplicationID,
		@CurrentUserID, @NodeID, NULL, N'Knowledge', N'Admin', @Now, @_Result output
	
	IF @_Result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of set dashboards as done
	
	-- Remove all existing dashboards
	EXEC [dbo].[NTFN_P_ArithmeticDeleteDashboards] @ApplicationID, 
		NULL, @NodeID, NULL, NULL, NULL, @_Result output
	
	IF @_Result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of remove all existing dashboards
	
	-- Send new dashboards
	DECLARE @Dashboards DashboardTableType
	
	INSERT INTO @Dashboards(UserID, NodeID, RefItemID, [Type], SubType, Removable, SendDate)
	SELECT	ND.CreatorUserID,
			@NodeID,
			@NodeID,
			N'Knowledge',
			N'Revision',
			1,
			@Now
	FROM [dbo].[CN_Nodes] AS ND
	WHERE ND.ApplicationID = @ApplicationID AND ND.NodeID = @NodeID
	
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
	-- end of send new dashboards
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_P_NewEvaluators]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_P_NewEvaluators]
GO

CREATE PROCEDURE [dbo].[KW_P_NewEvaluators]
	@ApplicationID			uniqueidentifier,
    @NodeID					uniqueidentifier,
    @EvaluatorUserIDsTemp	GuidTableType readonly,
    @Now					datetime,
    @_Result				int output
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @EvaluatorUserIDs GuidTableType
	INSERT INTO @EvaluatorUserIDs SELECT * FROM @EvaluatorUserIDsTemp
	
	/* Steps: */
	-- 1: Send new dashboards to admins
	
	-- Send new dashboards
	DECLARE @Dashboards DashboardTableType
	
	INSERT INTO @Dashboards(UserID, NodeID, RefItemID, [Type], SubType, Removable, SendDate)
	SELECT	EV.Value,
			@NodeID,
			@NodeID,
			N'Knowledge',
			N'Evaluator',
			0,
			@Now
	FROM @EvaluatorUserIDs AS EV
	
	EXEC [dbo].[NTFN_P_SendDashboards] @ApplicationID, @Dashboards, @_Result output
	
	IF @_Result > 0 BEGIN
		SELECT * 
		FROM @Dashboards
	END
	-- end of send new dashboards
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_NewEvaluators]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_NewEvaluators]
GO

CREATE PROCEDURE [dbo].[KW_NewEvaluators]
	@ApplicationID			uniqueidentifier,
    @NodeID					uniqueidentifier,
    @strEvaluatorUserIDs	varchar(max),
    @delimiter				char,
    @Now					datetime
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	/* Steps: */
	-- 1: Send new dashboards to admins
	
	DECLARE @EvaluatorUserIDs GuidTableType
	
	INSERT INTO @EvaluatorUserIDs
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strEvaluatorUserIDs, @delimiter) AS Ref
	
	DECLARE @_Result int
	
	-- Send new dashboards
	EXEC [dbo].[KW_P_NewEvaluators] @ApplicationID, 
		@NodeID, @EvaluatorUserIDs, @Now, @_Result output
	
	IF @_Result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of send new dashboards
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SendToEvaluators]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SendToEvaluators]
GO

CREATE PROCEDURE [dbo].[KW_SendToEvaluators]
	@ApplicationID			uniqueidentifier,
    @NodeID					uniqueidentifier,
    @CurrentUserID			uniqueidentifier,
    @strEvaluatorUserIDs	varchar(max),
    @delimiter				char,
    @Description			nvarchar(2000),
    @Now					datetime
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	/* Steps: */
	-- 1: Set knowledge status to 'SentToEvaluators'
	-- 2: Create History
	-- 3: Set current user's admin dashboard as done
	-- 4: Remove all existing dashboards
	-- 5: Send new dashboards to admins
	
	DECLARE @EvaluatorUserIDs GuidTableType
	
	INSERT INTO @EvaluatorUserIDs
	SELECT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strEvaluatorUserIDs, @delimiter) AS Ref
	
	DECLARE @SearchableAfter varchar(50) = (
		SELECT KT.SearchableAfter
		FROM [dbo].[CN_Nodes] AS ND
			INNER JOIN [dbo].[KW_KnowledgeTypes] AS KT
			ON KT.ApplicationID = @ApplicationID AND KT.KnowledgeTypeID = ND.NodeTypeID
		WHERE ND.ApplicationID = @ApplicationID AND ND.NodeID = @NodeID
	)
	
	-- Set new knowledge status
	DECLARE @SearchabilityStatus bit = ISNULL((
		SELECT TOP(1) Searchable
		FROM [dbo].[CN_Nodes]
		WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID
	), 1)
	
	DECLARE @Searchable bit = CAST((
		CASE 
			WHEN @SearchableAfter = N'Confirmation' THEN 1 
			ELSE @SearchabilityStatus 
		END
	) AS bit)
	
	UPDATE [dbo].[CN_Nodes]
		SET [Status] = N'SentToEvaluators',
			Searchable = CASE WHEN @SearchableAfter = N'Confirmation' THEN 1 ELSE Searchable END
	WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID
	
	IF @@ROWCOUNT <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of set new knowledge status
	
	-- Set searchability of previous version
	IF @SearchabilityStatus = 0 AND @Searchable = 1 BEGIN
		DECLARE @PreviousVersionID uniqueidentifier = (
			SELECT TOP(1) PreviousVersionID
			FROM [dbo].[CN_Nodes]
			WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID
		)
		
		IF @PreviousVersionID IS NOT NULL BEGIN
			UPDATE [dbo].[CN_Nodes]
				SET [Searchable] = 0
			WHERE ApplicationID = @ApplicationID AND NodeID = @PreviousVersionID
		END
	END
	-- end of Set searchability of previous version
	
	-- Create history
	INSERT INTO [dbo].[KW_History](
		ApplicationID,
		KnowledgeID,
		[Action],
		[Description],
		ActorUserID,
		ActionDate,
		WFVersionID,
		UniqueID
	)
	VALUES(
		@ApplicationID,
		@NodeID,
		N'SendToEvaluators',
		@Description,
		@CurrentUserID,
		@Now,
		[dbo].[KW_FN_GetWFVersionID](@ApplicationID, @NodeID),
		NEWID()
	)
	
	IF @@ROWCOUNT <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of create history
	
	DECLARE @_Result int
	
	-- Set dashboards as done
	EXEC [dbo].[NTFN_P_SetDashboardsAsDone] @ApplicationID,
		@CurrentUserID, @NodeID, NULL, N'Knowledge', N'Admin', @Now, @_Result output
	
	IF @_Result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of set dashboards as done
	
	-- Remove all existing dashboards
	EXEC [dbo].[NTFN_P_ArithmeticDeleteDashboards] @ApplicationID, 
		NULL, @NodeID, NULL, NULL, NULL, @_Result output
	
	IF @_Result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of remove all existing dashboards
	
	-- Send new dashboards
	EXEC [dbo].[KW_P_NewEvaluators] @ApplicationID, 
		@NodeID, @EvaluatorUserIDs, @Now, @_Result output
	
	IF @_Result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of send new dashboards
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SendKnowledgeComment]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SendKnowledgeComment]
GO

CREATE PROCEDURE [dbo].[KW_SendKnowledgeComment]
	@ApplicationID		uniqueidentifier,
    @NodeID				uniqueidentifier,
    @UserID				uniqueidentifier,
    @ReplyToHistoryID	bigint,
    @strAudienceUserIDs	varchar(max),
    @delimiter			char,
    @Description		nvarchar(2000),
    @Now				datetime
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE @AudienceUserIDs GuidTableType
	
	INSERT INTO @AudienceUserIDs (Value)
	SELECT DISTINCT Ref.Value
	FROM [dbo].[GFN_StrToGuidTable](@strAudienceUserIDs, @delimiter) AS Ref
	
	-- Create history
	INSERT INTO [dbo].[KW_History](
		ApplicationID,
		KnowledgeID,
		[Action],
		ActorUserID,
		ActionDate,
		[Description],
		ReplyToHistoryID,
		WFVersionID,
		UniqueID
	)
	VALUES(
		@ApplicationID,
		@NodeID,
		N'Comment',
		@UserID,
		@Now,
		[dbo].[GFN_VerifyString](@Description),
		@ReplyToHistoryID,
		[dbo].[KW_FN_GetWFVersionID](@ApplicationID, @NodeID),
		NEWID()
	)
	
	IF @@ROWCOUNT <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of create history
	
	DECLARE @_Result int = 0
	
	DECLARE @Dashboards DashboardTableType
	
	-- Send new dashboards
	
	DECLARE @CreatorUserID uniqueidentifier = (
		SELECT TOP(1) ND.CreatorUserID
		FROM [dbo].[CN_Nodes] AS ND
		WHERE ND.ApplicationID = @ApplicationID AND ND.NodeID = @NodeID
	)
	
	DECLARE @UserName nvarchar(1000), @FirstName nvarchar(1000), @LastName nvarchar(1000)
	
	SELECT TOP(1) @UserName = UserName, @FirstName = FirstName, @LastName = LastName
	FROM [dbo].[Users_Normal]
	WHERE ApplicationID = @ApplicationID AND UserID = @UserID
	
	INSERT INTO @Dashboards(UserID, NodeID, RefItemID, [Type], SubType, Removable, SendDate, Info)
	SELECT	A.Value,
			@NodeID,
			@NodeID,
			N'Knowledge',
			N'KnowledgeComment',
			1,
			@Now,
			N'{"UserID":"' + CAST(@UserID AS nvarchar(50)) + N'"' +
				N',"UserName":"' + [dbo].[GFN_Base64Encode](@UserName) + N'"' +
				N',"FirstName":"' + [dbo].[GFN_Base64Encode](@FirstName) + N'"' +
				N',"LastName":"' + [dbo].[GFN_Base64Encode](@LastName) + N'"' +
			N'}'
	FROM @AudienceUserIDs AS A
	
	EXEC [dbo].[NTFN_P_SendDashboards] @ApplicationID, @Dashboards, @_Result output
	
	IF @_Result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	-- end of send new dashboards
	
	SELECT * 
	FROM @Dashboards
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SaveEvaluationForm]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SaveEvaluationForm]
GO

CREATE PROCEDURE [dbo].[KW_SaveEvaluationForm]
	@ApplicationID		uniqueidentifier,
    @NodeID				uniqueidentifier,
    @UserID				uniqueidentifier,
    @CurrentUserID		uniqueidentifier,
    @AnswersTemp		GuidFloatTableType readonly,
    @Score				float,
    @EvaluationDate		datetime,
    @AdminUserIDsTemp	GuidTableType readonly,
    @TextOptions		nvarchar(1000),
    @Description		nvarchar(2000)
WITH ENCRYPTION, RECOMPILE
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE @Answers GuidFloatTableType
	INSERT INTO @Answers SELECT * FROM @AnswersTemp
	
	DECLARE @AdminUserIDs GuidTableType
	INSERT INTO @AdminUserIDs SELECT * FROM @AdminUserIDsTemp
	
	DECLARE @Ans Table(QuestionID uniqueidentifier primary key clustered,
		Score float, [Exists] bit)
		
	INSERT INTO @Ans (QuestionID, Score, [Exists])
	SELECT Ref.FirstValue, Ref.SecondValue, CASE WHEN QA.KnowledgeID IS NULL THEN 0 ELSE 1 END
	FROM @Answers AS Ref
		LEFT JOIN [dbo].[KW_QuestionAnswers] AS QA
		ON QA.ApplicationID = @ApplicationID AND QA.KnowledgeID = @NodeID AND 
			QA.UserID = @UserID AND QA.QuestionID = Ref.FirstValue
			
	DECLARE @Count int = (SELECT COUNT(*) FROM @Ans)
	DECLARE @ExistingCount int = (SELECT COUNT(*) FROM @Ans WHERE [Exists] = 1)
	
	DECLARE @Devoluted bit = 0
	
	IF @CurrentUserID IS NOT NULL AND @UserID IS NOT NULL AND @CurrentUserID <> @UserID SET @Devoluted = 1
	
	IF @ExistingCount > 0 BEGIN
		UPDATE QA
			SET Title = Q.Title,
				Score = CASE WHEN @Devoluted = 1 THEN QA.Score ELSE Ref.Score END,
				--SelectedOptionID = CASE WHEN @Devoluted = 1 THEN QA.SelectedOptionID ELSE Ref.SelectedOptionID END,
				AdminID = CASE WHEN @Devoluted = 1 THEN @CurrentUserID ELSE NULL END,
				AdminScore = CASE WHEN @Devoluted = 1 THEN Ref.Score ELSE QA.AdminScore END,
				EvaluationDate = @EvaluationDate,
				Deleted = 0
		FROM @Ans AS Ref
			INNER JOIN [dbo].[KW_QuestionAnswers] AS QA
			ON QA.QuestionID = Ref.QuestionID
			INNER JOIN [dbo].[KW_Questions] AS Q
			ON Q.ApplicationID = @ApplicationID AND Q.QuestionID = Ref.QuestionID
		WHERE QA.ApplicationID = @ApplicationID AND Ref.[Exists] = 1 AND 
			QA.KnowledgeID = @NodeID AND QA.UserID = @UserID
			
		IF @@ROWCOUNT <= 0 BEGIN
			SELECT -1, N'SavingEvaluationFormFailed'
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	IF @Count > @ExistingCount BEGIN
		INSERT INTO [dbo].[KW_QuestionAnswers](
			ApplicationID,
			KnowledgeID,
			UserID,
			QuestionID,
			Title,
			Score,
			AdminID,
			AdminScore,
			EvaluationDate,
			Deleted
		)
		SELECT	@ApplicationID,
				@NodeID, 
				@UserID, 
				Ref.QuestionID, 
				Q.Title, 
				Ref.Score,
				CASE WHEN @Devoluted = 1 THEN @CurrentUserID ELSE NULL END,
				CASE WHEN @Devoluted = 1 THEN Ref.Score ELSE NULL END,
				@EvaluationDate,
				0
		FROM @Ans AS Ref
			INNER JOIN [dbo].[KW_Questions] AS Q
			ON Q.QuestionID = Ref.QuestionID
		WHERE Q.ApplicationID = @ApplicationID AND ISNULL(Ref.[Exists], 0) = 0
		
		IF @@ROWCOUNT <= 0 BEGIN
			SELECT -1, N'SavingEvaluationFormFailed'
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	-- Create history
	INSERT INTO [dbo].[KW_History](
		ApplicationID,
		KnowledgeID,
		[Action],
		ActorUserID,
		ActionDate,
		DeputyUserID,
		TextOptions,
		[Description],
		WFVersionID,
		UniqueID
	)
	VALUES(
		@ApplicationID,
		@NodeID,
		N'Evaluation',
		@UserID,
		@EvaluationDate,
		CASE WHEN @Devoluted = 1 THEN @CurrentUserID ELSE NULL END,
		@TextOptions,
		[dbo].[GFN_VerifyString](@Description),
		[dbo].[KW_FN_GetWFVersionID](@ApplicationID, @NodeID),
		NEWID()
	)
	
	IF @@ROWCOUNT <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of create history
	
	DECLARE @_Result int = 0
	
	EXEC [dbo].[KW_P_CalculateKnowledgeScore] @ApplicationID, @NodeID, @_Result output
	
	IF @_Result <= 0 BEGIN
		SELECT -1, N'ScoreCalculationFailed'
		ROLLBACK TRANSACTION
		RETURN
	END
	
	-- Set dashboard as done
	DECLARE @Uid uniqueidentifier = ISNULL(@UserID, @CurrentUserID)
	
	DECLARE @UserName nvarchar(1000), @FirstName nvarchar(1000), @LastName nvarchar(1000)
	
	SELECT TOP(1) @UserName = UserName, @FirstName = FirstName, @LastName = LastName
	FROM [dbo].[Users_Normal]
	WHERE ApplicationID = @ApplicationID AND UserID = @Uid
	
	EXEC [dbo].[NTFN_P_SetDashboardsAsDone] @ApplicationID, @Uid, @NodeID, NULL, 
		N'Knowledge', N'Evaluator', @EvaluationDate, @_Result output
	
	IF @_Result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of set dashboard as done
	
	
	DECLARE @_SearchabilityActivated bit, @_Accepted bit
	
	EXEC [dbo].[KW_P_AutoSetKnowledgeStatus] @ApplicationID, @NodeID, @EvaluationDate, 
		@_SearchabilityActivated output, @_Accepted output, @_Result output
	
	IF @_Result <= 0 BEGIN
		SELECT -1, N'DeterminingKnowledgeStatusFailed'
		ROLLBACK TRANSACTION
		RETURN
	END
	
	DECLARE @Dashboards DashboardTableType
	
	--EXEC [dbo].[NTFN_P_DashboardExists] NULL, @NodeID, N'Knowledge', 
	--	NULL, NULL, 0, NULL, NULL, @_Result output
	
	-- Send new dashboards
	--IF @_Result > 0 BEGIN
	INSERT INTO @Dashboards(UserID, NodeID, RefItemID, [Type], SubType, Removable, SendDate, Info)
	SELECT	A.Value,
			@NodeID,
			@NodeID,
			N'Knowledge',
			N'EvaluationDone',
			1,
			@EvaluationDate,
			N'{"UserID":"' + CAST(@Uid AS nvarchar(50)) + N'"' +
				N',"UserName":"' + [dbo].[GFN_Base64Encode](@UserName) + N'"' +
				N',"FirstName":"' + [dbo].[GFN_Base64Encode](@FirstName) + N'"' +
				N',"LastName":"' + [dbo].[GFN_Base64Encode](@LastName) + N'"' +
			N'}'
	FROM @AdminUserIDs AS A
	
	EXEC [dbo].[NTFN_P_SendDashboards] @ApplicationID, @Dashboards, @_Result output
	
	IF @_Result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	--END
	-- end of send new dashboards
	
	SELECT * 
	FROM @Dashboards
	
	DECLARE @Status varchar(100) = (
		SELECT TOP(1) ND.[Status]
		FROM [dbo].[CN_Nodes] AS ND 
		WHERE ND.ApplicationID = @ApplicationID AND ND.NodeID = @NodeID
	)
	
	SELECT CAST(1 AS int) AS Result, 
		@_Accepted AS Accepted, @_SearchabilityActivated AS SearchabilityActivated, @Status AS [Status]
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_RemoveEvaluator]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_RemoveEvaluator]
GO

CREATE PROCEDURE [dbo].[KW_RemoveEvaluator]
	@ApplicationID	uniqueidentifier,
    @NodeID			uniqueidentifier,
    @UserID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @_Result int
	
	EXEC [dbo].[NTFN_P_ArithmeticDeleteDashboards] @ApplicationID, 
		@UserID, @NodeID, NULL, N'Knowledge', N'Evaluator', @_Result output
		
	UPDATE [dbo].[KW_QuestionAnswers]
		SET Deleted = 1
	WHERE ApplicationID = @ApplicationID AND KnowledgeID = @NodeID AND UserID = @UserID
	
	SELECT @_Result + @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_RefuseEvaluation]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_RefuseEvaluation]
GO

CREATE PROCEDURE [dbo].[KW_RefuseEvaluation]
	@ApplicationID		uniqueidentifier,
    @NodeID				uniqueidentifier,
    @UserID				uniqueidentifier,
    @Now				datetime,
    @strAdminUserIDs	varchar(max),
    @delimiter			char,
    @Description		nvarchar(2000)
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	-- Create history
	INSERT INTO [dbo].[KW_History](
		ApplicationID,
		KnowledgeID,
		[Action],
		ActorUserID,
		ActionDate,
		[Description],
		WFVersionID,
		UniqueID
	)
	VALUES(
		@ApplicationID,
		@NodeID,
		N'RefuseEvaluation',
		@UserID,
		@Now,
		@Description,
		[dbo].[KW_FN_GetWFVersionID](@ApplicationID, @NodeID),
		NEWID()
	)
	
	IF @@ROWCOUNT <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of create history
	
	
	DECLARE @_Result int
	
	
	-- Remove old dashboards
	EXEC [dbo].[NTFN_P_ArithmeticDeleteDashboards] @ApplicationID, 
		@UserID, @NodeID, NULL, N'Knowledge', N'Evaluator', @_Result output
		
	IF @_Result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of remove old dashboards
	
	
	-- Send new dashboards
	DECLARE @AdminUserIDs GuidTableType
	INSERT INTO @AdminUserIDs 
	SELECT Ref.Value 
	FROM [dbo].[GFN_StrToGuidTable](@strAdminUserIDs, @delimiter) AS Ref
	
	DECLARE @UserName nvarchar(1000), @FirstName nvarchar(1000), @LastName nvarchar(1000)
	SELECT @UserName = UserName, @FirstName = FirstName, @LastName = LastName
	FROM [dbo].[Users_Normal]
	WHERE ApplicationID = @ApplicationID AND UserID = @UserID
	
	DECLARE @Dashboards DashboardTableType
	
	INSERT INTO @Dashboards(UserID, NodeID, RefItemID, [Type], SubType, Removable, SendDate, Info)
	SELECT	A.Value,
			@NodeID,
			@NodeID,
			N'Knowledge',
			N'EvaluationRefused',
			1,
			@Now,
			N'{"UserID":"' + CAST(@UserID AS nvarchar(50)) + N'"' +
				N',"UserName":"' + [dbo].[GFN_Base64Encode](@UserName) + N'"' +
				N',"FirstName":"' + [dbo].[GFN_Base64Encode](@FirstName) + N'"' +
				N',"LastName":"' + [dbo].[GFN_Base64Encode](@LastName) + N'"' +
			N'}'
	FROM @AdminUserIDs AS A
	
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
	-- end of send new dashboards
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_TerminateEvaluation]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_TerminateEvaluation]
GO

CREATE PROCEDURE [dbo].[KW_TerminateEvaluation]
	@ApplicationID	uniqueidentifier,
    @NodeID			uniqueidentifier,
    @CurrentUserID	uniqueidentifier,
    @Description	nvarchar(2000),
    @Now			datetime
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	DECLARE @_Result int
	
	EXEC [dbo].[NTFN_P_ArithmeticDeleteDashboards] @ApplicationID, 
		NULL, @NodeID, NULL, N'Knowledge', NULL, @_Result output
		
	IF @_Result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	DECLARE @_Accepted bit, @_SearchabilityActivated bit
	
	EXEC [dbo].[KW_P_AutoSetKnowledgeStatus] @ApplicationID, @NodeID, @Now, 
		@_SearchabilityActivated output, @_Accepted output, @_Result output 
		
	IF @_Result <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	
	-- Create history
	INSERT INTO [dbo].[KW_History](
		ApplicationID,
		KnowledgeID,
		[Action],
		[Description],
		ActorUserID,
		ActionDate,
		WFVersionID,
		UniqueID
	)
	VALUES(
		@ApplicationID,
		@NodeID,
		N'TerminateEvaluation',
		@Description,
		@CurrentUserID,
		@Now,
		[dbo].[KW_FN_GetWFVersionID](@ApplicationID, @NodeID),
		NEWID()
	)
	
	IF @@ROWCOUNT <= 0 BEGIN
		SELECT -1
		ROLLBACK TRANSACTION
		RETURN
	END
	-- end of create history
	
	SELECT CAST(1 AS int) AS Result, @_Accepted AS Accepted, 
		@_SearchabilityActivated AS SearchabilityActivated
COMMIT TRANSACTION

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetLastHistoryVersionID]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetLastHistoryVersionID]
GO

CREATE PROCEDURE [dbo].[KW_GetLastHistoryVersionID]
	@ApplicationID	uniqueidentifier,
    @KnowledgeID	uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(1) [dbo].[KW_FN_GetWFVersionID](@ApplicationID, @KnowledgeID) AS Value
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_EditHistoryDescription]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_EditHistoryDescription]
GO

CREATE PROCEDURE [dbo].[KW_EditHistoryDescription]
	@ApplicationID	uniqueidentifier,
    @ID				bigint,
    @Description	nvarchar(2000)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[KW_History]
		SET [Description] = [dbo].[GFN_VerifyString](@Description)
	WHERE ApplicationID = @ApplicationID AND ID = @ID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetHistory]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetHistory]
GO

CREATE PROCEDURE [dbo].[KW_GetHistory]
	@ApplicationID	uniqueidentifier,
    @KnowledgeID	uniqueidentifier,
    @UserID			uniqueidentifier,
    @Action			varchar(50),
    @WFVersionID	int
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT	H.ID,
			H.KnowledgeID,
			H.[Action],
			H.TextOptions,
			H.[Description],
			H.ActorUserID,
			UN.UserName AS ActorUserName,
			UN.FirstName AS ActorFirstName,
			UN.LastName AS ActorLastName,
			UN.AvatarName AS ActorAvatarName,
			UN.UseAvatar AS ActorUseAvatar,
			H.DeputyUserID,
			DN.UserName AS DeputyUserName,
			DN.FirstName AS DeputyFirstName,
			DN.LastName AS DeputyLastName,
			DN.AvatarName AS DeputyAvatarName,
			DN.UseAvatar AS DeputyUseAvatar,
			H.ActionDate,
			H.ReplyToHistoryID,
			H.WFVersionID,
			CAST((CASE WHEN ND.CreatorUserID = H.ActorUserID THEN 1 ELSE 0 END) AS bit) AS IsCreator,
			CAST((
				SELECT TOP(1) 1
				FROM [dbo].[CN_NodeCreators] AS NC
				WHERE NC.ApplicationID = @ApplicationID AND NC.NodeID = H.KnowledgeID AND 
					NC.UserID = H.[ActorUserID] AND NC.Deleted = 0
			) AS bit) AS IsContributor
	FROM [dbo].[KW_History] AS H
		INNER JOIN [dbo].[CN_Nodes] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.NodeID = H.KnowledgeID
		LEFT JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND UN.UserID = H.ActorUserID
		LEFT JOIN [dbo].[Users_Normal] AS DN
		ON DN.ApplicationID = @ApplicationID AND DN.UserID = H.DeputyUserID
	WHERE H.ApplicationID = @ApplicationID AND H.KnowledgeID = @KnowledgeID AND
		(@UserID IS NULL OR H.ActorUserID = @UserID) AND
		(@Action IS NULL OR H.[Action] = @Action) AND
		(@WFVersionID IS NULL OR H.WFVersionID = @WFVersionID)
	ORDER BY H.ID DESC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetHistoryByID]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetHistoryByID]
GO

CREATE PROCEDURE [dbo].[KW_GetHistoryByID]
	@ApplicationID	uniqueidentifier,
    @ID				bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT	H.ID,
			H.KnowledgeID,
			H.[Action],
			H.TextOptions,
			H.[Description],
			H.ActorUserID,
			UN.UserName AS ActorUserName,
			UN.FirstName AS ActorFirstName,
			UN.LastName AS ActorLastName,
			UN.AvatarName AS ActorAvatarName,
			UN.UseAvatar AS ActorUseAvatar,
			H.DeputyUserID,
			DN.UserName AS DeputyUserName,
			DN.FirstName AS DeputyFirstName,
			DN.LastName AS DeputyLastName,
			DN.AvatarName AS DeputyAvatarName,
			DN.UseAvatar AS DeputyUseAvatar,
			H.ActionDate,
			H.ReplyToHistoryID,
			H.WFVersionID,
			CAST((CASE WHEN ND.CreatorUserID = H.ActorUserID THEN 1 ELSE 0 END) AS bit) AS IsCreator,
			CAST((
				SELECT TOP(1) 1
				FROM [dbo].[CN_NodeCreators] AS NC
				WHERE NC.ApplicationID = @ApplicationID AND NC.NodeID = H.KnowledgeID AND 
					NC.UserID = H.[ActorUserID] AND NC.Deleted = 0
			) AS bit) AS IsContributor
	FROM [dbo].[KW_History] AS H
		INNER JOIN [dbo].[CN_Nodes] AS ND
		ON ND.ApplicationID = @ApplicationID AND ND.NodeID = H.KnowledgeID
		LEFT JOIN [dbo].[Users_Normal] AS UN
		ON UN.ApplicationID = @ApplicationID AND UN.UserID = H.ActorUserID
		LEFT JOIN [dbo].[Users_Normal] AS DN
		ON DN.ApplicationID = @ApplicationID AND DN.UserID = H.DeputyUserID
	WHERE H.ApplicationID = @ApplicationID AND H.ID = @ID
END

GO


/* Knowledge Feedbacks */

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_AddFeedBack]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_AddFeedBack]
GO

CREATE PROCEDURE [dbo].[KW_AddFeedBack]
	@ApplicationID	uniqueidentifier,
	@KnowledgeID	uniqueidentifier,
	@UserID			uniqueidentifier,
	@FeedBackTypeID	int,
	@SendDate		datetime,
	@Value			float,
	@Description	nvarchar(2000)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @Description = [dbo].[GFN_VerifyString](@Description)
	
	IF @Value IS NULL SET @Value = 0

	INSERT INTO [dbo].[KW_FeedBacks](
		ApplicationID,
		KnowledgeID,
		UserID,
		FeedBackTypeID,
		SendDate,
		Value,
		[Description],
		Deleted
	)
	VALUES(
		@ApplicationID,
		@KnowledgeID,
		@UserID,
		@FeedBackTypeID,
		@SendDate,
		@Value,
		@Description,
		0
	)
	
	SELECT @@IDENTITY
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_ModifyFeedBack]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_ModifyFeedBack]
GO

CREATE PROCEDURE [dbo].[KW_ModifyFeedBack]
	@ApplicationID	uniqueidentifier,
	@FeedBackID		bigint,
	@Value			float,
	@Description	nvarchar(2000)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @Description = [dbo].[GFN_VerifyString](@Description)
	
	UPDATE [dbo].[KW_FeedBacks]
		SET Value = @Value,
			[Description] = @Description
	WHERE ApplicationID = @ApplicationID AND FeedBackID = @FeedBackID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_ArithmeticDeleteFeedBack]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_ArithmeticDeleteFeedBack]
GO

CREATE PROCEDURE [dbo].[KW_ArithmeticDeleteFeedBack]
	@ApplicationID	uniqueidentifier,
	@FeedBackID		bigint
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	UPDATE [dbo].[KW_FeedBacks]
		SET Deleted = 1
	WHERE ApplicationID = @ApplicationID AND FeedBackID = @FeedBackID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_P_GetFeedBacksByIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_P_GetFeedBacksByIDs]
GO

CREATE PROCEDURE [dbo].[KW_P_GetFeedBacksByIDs]
	@ApplicationID		uniqueidentifier,
	@FeedBackIDsTemp	BigIntTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @FeedBackIDs BigIntTableType
	INSERT INTO @FeedBackIDs SELECT * FROM @FeedBackIDsTemp
	
	SELECT FB.FeedBackID,
		   FB.KnowledgeID,
		   FB.FeedBackTypeID,
		   FB.SendDate,
		   FB.Value,
		   FB.[Description],
		   USR.UserID,
		   USR.UserName,
		   USR.FirstName,
		   USR.LastName,
		   USR.AvatarName,
		   USR.UseAvatar
	FROM @FeedBackIDs AS ExternalIDs  
		INNER JOIN [dbo].[KW_FeedBacks] AS FB
		ON FB.ApplicationID = @ApplicationID AND FB.FeedBackID = ExternalIDs.Value
		INNER JOIN [dbo].[Users_Normal] AS USR
		ON USR.ApplicationID = @ApplicationID AND USR.UserID = FB.UserID
	ORDER BY FB.SendDate DESC
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetFeedBacksByIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetFeedBacksByIDs]
GO

CREATE PROCEDURE [dbo].[KW_GetFeedBacksByIDs]
	@ApplicationID		uniqueidentifier,
	@strFeedBackIDs		varchar(max),
	@delimiter			char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @FeedBackIDs BigIntTableType
	
	INSERT INTO @FeedBackIDs
	SELECT DISTINCT Ref.Value FROM GFN_StrToBigIntTable(@strFeedBackIDs, @delimiter) AS Ref

	EXEC [dbo].[KW_P_GetFeedBacksByIDs] @ApplicationID, @FeedBackIDs
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetKnowledgeFeedBacks]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetKnowledgeFeedBacks]
GO

CREATE PROCEDURE [dbo].[KW_GetKnowledgeFeedBacks]
	@ApplicationID				uniqueidentifier,
	@KnowledgeID				uniqueidentifier,
	@UserID						uniqueidentifier,
	@FeedBackTypeID				int,
	@SendDateLowerThreshold		datetime,
	@SendDateUpperThreshold		datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @FeedBackIDs BigIntTableType
	
	INSERT INTO @FeedBackIDs
	SELECT FB.FeedBackID
	FROM [dbo].[KW_FeedBacks] AS FB
		INNER JOIN [dbo].[Users_Normal] AS USR
		ON USR.ApplicationID = @ApplicationID AND USR.UserID = FB.UserID
	WHERE FB.ApplicationID = @ApplicationID AND FB.KnowledgeID = @KnowledgeID AND 
		(@UserID IS NULL OR FB.UserID = @UserID) AND FB.Deleted = 0 AND
		(@FeedBackTypeID IS NULL OR FB.FeedBackTypeID = @FeedBackTypeID) AND
		(@SendDateLowerThreshold IS NULL OR FB.SendDate >= @SendDateLowerThreshold) AND
		(@SendDateUpperThreshold IS NULL OR FB.SendDate <= @SendDateUpperThreshold)

	EXEC [dbo].[KW_P_GetFeedBacksByIDs] @ApplicationID, @FeedBackIDs
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetFeedBackStatus]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetFeedBackStatus]
GO

CREATE PROCEDURE [dbo].[KW_GetFeedBackStatus]
	@ApplicationID	uniqueidentifier,
	@KnowledgeID	uniqueidentifier,
	@UserID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SELECT TOP(1)
		SUM(CASE WHEN FB.FeedBackTypeID = 1 THEN FB.Value ELSE 0 END) AS TotalFinancialFeedBacks,
		SUM(CASE WHEN FB.FeedBackTypeID = 2 THEN FB.Value ELSE 0 END) AS TotalTemporalFeedBacks,
		SUM(CASE WHEN FB.UserID = @UserID AND FB.FeedBackTypeID = 1 THEN FB.Value ELSE 0 END) AS FinancialFeedBackStatus,
		SUM(CASE WHEN FB.UserID = @UserID AND FB.FeedBackTypeID = 2 THEN FB.Value ELSE 0 END) AS TemporalFeedBackStatus
	FROM [dbo].[KW_FeedBacks] AS FB
	WHERE FB.ApplicationID = @ApplicationID AND 
		FB.KnowledgeID = @KnowledgeID AND FB.Deleted = 0
END

GO

/* end of Knowledge Feedbacks */


/* Necessary Items */

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetNecessaryItems]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetNecessaryItems]
GO

CREATE PROCEDURE [dbo].[KW_GetNecessaryItems]
	@ApplicationID			uniqueidentifier,
	@NodeTypeIDOrNodeID		uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET @NodeTypeIDOrNodeID = ISNULL((
		SELECT TOP(1) NodeTypeID
		FROM [dbo].[CN_Nodes]
		WHERE ApplicationID = @ApplicationID AND NodeID = @NodeTypeIDOrNodeID
	), @NodeTypeIDOrNodeID)
	
	SELECT NI.ItemName
	FROM [dbo].[KW_NecessaryItems] AS NI
	WHERE NI.ApplicationID = @ApplicationID AND 
		NI.NodeTypeID = @NodeTypeIDOrNodeID AND NI.Deleted = 0
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_ActivateNecessaryItem]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_ActivateNecessaryItem]
GO

CREATE PROCEDURE [dbo].[KW_ActivateNecessaryItem]
	@ApplicationID	uniqueidentifier,
	@NodeTypeID		uniqueidentifier,
	@ItemName		varchar(50),
	@CurrentUserID	uniqueidentifier,
	@Now			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) *
		FROM [dbo].[KW_NecessaryItems]
		WHERE ApplicationID = @ApplicationID AND 
			NodeTypeID = @NodeTypeID AND ItemName = @ItemName
	) BEGIN
		UPDATE [dbo].[KW_NecessaryItems]
			SET LastModifierUserID = @CurrentUserID,
				LastModificationDate = @Now,
				Deleted = 0
		WHERE ApplicationID = @ApplicationID AND 
			NodeTypeID = @NodeTypeID AND ItemName = @ItemName
	END
	ELSE BEGIN
		INSERT INTO [dbo].[KW_NecessaryItems] (
			ApplicationID,
			NodeTypeID,
			ItemName,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES (
			@ApplicationID,
			@NodeTypeID,
			@ItemName,
			@CurrentUserID,
			@Now,
			0
		)
	END
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_DeactiveNecessaryItem]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_DeactiveNecessaryItem]
GO

CREATE PROCEDURE [dbo].[KW_DeactiveNecessaryItem]
	@ApplicationID	uniqueidentifier,
	@NodeTypeID		uniqueidentifier,
	@ItemName		varchar(50),
	@CurrentUserID	uniqueidentifier,
	@Now			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[KW_NecessaryItems]
		SET LastModifierUserID = @CurrentUserID,
			LastModificationDate = @Now,
			Deleted = 1
	WHERE ApplicationID = @ApplicationID AND 
		NodeTypeID = @NodeTypeID AND ItemName = @ItemName
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_CheckNecessaryItems]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_CheckNecessaryItems]
GO

CREATE PROCEDURE [dbo].[KW_CheckNecessaryItems]
	@ApplicationID	uniqueidentifier,
	@NodeID			uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	-- meta data for NecessaryFieldsOfForm
	DECLARE @NodeTypeID uniqueidentifier = (
		SELECT TOP(1) NodeTypeID
		FROM [dbo].[CN_Nodes]
		WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID
	)
	
	DECLARE @ElementLimits TABLE (ElementID uniqueidentifier, Necessary bit)

	INSERT INTO @ElementLimits (ElementID, Necessary)
	SELECT EL.ElementID, ISNULL(EL.Necessary, 0)
	FROM [dbo].[FG_ElementLimits] AS EL
	WHERE EL.ApplicationID = @ApplicationID AND 
		EL.OwnerID = @NodeTypeID AND EL.Deleted = 0
		
	DECLARE @HasFormLimit bit =
		CASE WHEN (SELECT COUNT(*) FROM @ElementLimits) > 0 THEN 1 ELSE 0 END
		
	DELETE @ElementLimits
	WHERE Necessary = 0
	-- end of meta data for NecessaryFieldsOfForm
	
	DECLARE @Items StringTableType
	
	;WITH X AS (
		SELECT TOP(1) *
		FROM [dbo].[CN_Nodes]
		WHERE ApplicationID = @ApplicationID AND NodeID = @NodeID
	)
	INSERT INTO @Items (Value)
	SELECT X.ItemName
	FROM (
			SELECT TOP(1) N'Abstract' AS ItemName
			FROM X
			WHERE ISNULL(X.[Description], N'') <> N''
			
			UNION
			
			SELECT TOP(1) N'Keywords'
			FROM X
			WHERE ISNULL(X.Tags, N'') <> N''
			
			UNION
			
			SELECT TOP(1) N'Wiki'
			FROM X
				INNER JOIN [dbo].[WK_Titles] AS T
				ON T.ApplicationID = @ApplicationID AND T.OwnerID = X.NodeID AND T.Deleted = 0
				INNER JOIN [dbo].[WK_Paragraphs] AS P
				ON P.ApplicationID = @ApplicationID AND P.TitleID = T.TitleID AND P.Deleted = 0 AND
					(P.[Status] = N'Accepted' OR P.[Status] = N'CitationNeeded')
					
			UNION
			
			SELECT TOP(1) N'RelatedNodes'
			FROM X
				LEFT JOIN [dbo].[CN_View_OutRelatedNodes] AS NR
				ON NR.ApplicationID = @ApplicationID AND 
					NR.NodeID = X.NodeID AND NR.RelatedNodeID <> X.NodeID
				LEFT JOIN [dbo].[CN_View_InRelatedNodes] AS NRIN
				ON NRIN.ApplicationID = @ApplicationID AND
					NRIN.NodeID = X.NodeID AND NRIN.RelatedNodeID <> X.NodeID
			WHERE NR.NodeID IS NOT NULL OR NRIN.NodeID IS NOT NULL
				
			UNION
			
			SELECT TOP(1) N'Attachments'
			FROM X
				INNER JOIN [dbo].[DCT_Files] AS ATT
				ON ATT.ApplicationID = @ApplicationID AND ATT.OwnerID = X.NodeID AND ATT.Deleted = 0
			
			UNION

			SELECT TOP(1) N'DocumentTree'
			FROM X
			WHERE X.DocumentTreeNodeID IS NOT NULL
			
			UNION
			
			SELECT TOP(1) N'NecessaryFieldsOfForm'
			WHERE NOT EXISTS (
					SELECT TOP(1) 1
					FROM X INNER JOIN 
						[dbo].[FG_FormOwners] AS O
						ON O.ApplicationID = @ApplicationID AND 
							O.OwnerID = X.NodeTypeID AND O.Deleted = 0
						INNER JOIN [dbo].[FG_FormInstances] AS I
						ON I.ApplicationID = @ApplicationID AND 
							I.FormID = O.FormID AND I.OwnerID = @NodeID AND 
							I.Deleted = 0
						INNER JOIN [dbo].[FG_ExtendedFormElements] AS FE
						ON FE.ApplicationID = @ApplicationID AND 
							FE.FormID = O.FormID AND FE.Deleted = 0 AND
							(@HasFormLimit = 1 OR FE.Necessary = 1)
						LEFT JOIN [dbo].[FG_InstanceElements] AS E
						ON E.ApplicationID = @ApplicationID AND 
							E.InstanceID = I.InstanceID AND 
							E.RefElementID = FE.ElementID AND E.Deleted = 0
					WHERE (
							ISNULL(@HasFormLimit, 0) = 0 OR 
							FE.ElementID IN (SELECT ElementID FROM @ElementLimits)
						) AND
						ISNULL([dbo].[FG_FN_ToString](
							@ApplicationID,
							E.ElementID,
							E.[Type],
							E.TextValue, 
							E.FloatValue,
							E.BitValue, 
							E.DateValue
						), N'') = N''
				)
		) AS X
		
	SELECT I.Value AS ItemName
	FROM @Items AS I
END

GO

/* end of Necessary Items */