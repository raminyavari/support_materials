USE [EKM_App]
GO

/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

DECLARE @UserID uniqueidentifier = (SELECT TOP(1) UserId FROM [dbo].[aspnet_Users]
	WHERE LoweredUserName = N'admin')

DECLARE @KnowledgeTypeID uniqueidentifier = (SELECT NodeTypeID FROM [dbo].[CN_NodeTypes] WHERE AdditionalID = N'5')

DECLARE @ExperienceTypeID uniqueidentifier = (SELECT TOP(1) [Guid]
	FROM [dbo].[TMP_KW_TempKnowledgeTypeIDs] WHERE IntID = 1)
DECLARE @SkillTypeID uniqueidentifier = (SELECT TOP(1) [Guid]
	FROM [dbo].[TMP_KW_TempKnowledgeTypeIDs] WHERE IntID = 2)
DECLARE @ContentTypeID uniqueidentifier = (SELECT TOP(1) [Guid]
	FROM [dbo].[TMP_KW_TempKnowledgeTypeIDs] WHERE IntID = 3)

INSERT INTO [dbo].[CN_NodeTypes](NodeTypeID, Name, Deleted, CreatorUserID, CreationDate, ParentID)
VALUES (@ExperienceTypeID, N'تجربه', 0, @UserID, GETDATE(), @KnowledgeTypeID)

INSERT INTO [dbo].[CN_NodeTypes](NodeTypeID, Name, Deleted, CreatorUserID, CreationDate, ParentID)
VALUES (@SkillTypeID, N'مهارت', 0, @UserID, GETDATE(), @KnowledgeTypeID)

INSERT INTO [dbo].[CN_NodeTypes](NodeTypeID, Name, Deleted, CreatorUserID, CreationDate, ParentID)
VALUES (@ContentTypeID, N'مستند', 0, @UserID, GETDATE(), @KnowledgeTypeID)

UPDATE ND
	SET NodeTypeID = @ExperienceTypeID
FROM [dbo].[CN_Nodes] AS ND
	INNER JOIN [dbo].[KW_Knowledges] AS KW
	ON ND.NodeID = KW.KnowledgeID
WHERE KW.KnowledgeTypeID = 1

UPDATE ND
	SET NodeTypeID = @SkillTypeID
FROM [dbo].[CN_Nodes] AS ND
	INNER JOIN [dbo].[KW_Knowledges] AS KW
	ON ND.NodeID = KW.KnowledgeID
WHERE KW.KnowledgeTypeID = 2

UPDATE ND
	SET NodeTypeID = @ContentTypeID
FROM [dbo].[CN_Nodes] AS ND
	INNER JOIN [dbo].[KW_Knowledges] AS KW
	ON ND.NodeID = KW.KnowledgeID
WHERE KW.KnowledgeTypeID = 3


INSERT INTO [dbo].[CN_Services](NodeTypeID, ServiceTitle, AdminType, SequenceNumber,
	EnableContribution, EditableForAdmin, EditableForCreator, EditableForOwners,
	EditableForExperts, EditableForMembers, MaxAcceptableAdminLevel, Deleted)
VALUES(@ExperienceTypeID, N'ثبت تجربه', N'AreaAdmin', 10, 0, 1, 1, 1, 0, 0, 2, 0)

INSERT INTO [dbo].[TMP_KW_KnowledgeTypes](KnowledgeTypeID, EvaluationType, 
	Evaluators, SearchableAfter, ScoreScale, MinAcceptableScore, 
	CreatorUserID, CreationDate, Deleted)
VALUES(@ExperienceTypeID, N'EN', N'SEN', N'Evaluation', 10, 5, @UserID, GETDATE(), 0)

INSERT INTO [dbo].[CN_Services](NodeTypeID, ServiceTitle, AdminType, SequenceNumber,
	EnableContribution, EditableForAdmin, EditableForCreator, EditableForOwners,
	EditableForExperts, EditableForMembers, MaxAcceptableAdminLevel, Deleted)
VALUES(@SkillTypeID, N'ثبت مهارت', N'AreaAdmin', 11, 0, 1, 1, 1, 0, 0, 2, 0)
	
INSERT INTO [dbo].[TMP_KW_KnowledgeTypes](KnowledgeTypeID, EvaluationType, 
	Evaluators, SearchableAfter, ScoreScale, MinAcceptableScore, 
	CreatorUserID, CreationDate, Deleted)
VALUES(@SkillTypeID, N'EN', N'SEN', N'Evaluation', 10, 5, @UserID, GETDATE(), 0)

INSERT INTO [dbo].[CN_Services](NodeTypeID, ServiceTitle, AdminType, SequenceNumber,
	EnableContribution, EditableForAdmin, EditableForCreator, EditableForOwners,
	EditableForExperts, EditableForMembers, MaxAcceptableAdminLevel, Deleted)
VALUES(@ContentTypeID, N'ثبت سند', N'AreaAdmin', 12, 1, 1, 1, 1, 0, 0, 2, 0)
	
INSERT INTO [dbo].[TMP_KW_KnowledgeTypes](KnowledgeTypeID, EvaluationType, 
	Evaluators, SearchableAfter, ScoreScale, MinAcceptableScore, 
	CreatorUserID, CreationDate, Deleted)
VALUES(@ContentTypeID, N'EN', N'SEN', N'Evaluation', 10, 5, @UserID, GETDATE(), 0)
	


INSERT INTO [dbo].[TMP_KW_Questions](QuestionID, Title, CreatorUserID, CreationDate, Deleted)
SELECT NEWID(), Ref.Question, @UserID, GETDATE(), 0
FROM (
		SELECT Question
		FROM [dbo].[NGeneralQuestions]
		
		UNION
		
		SELECT Question
		FROM [dbo].[NQuestions]
	) AS Ref


DECLARE @TQ Table(ID uniqueidentifier, KnowledgeTypeID uniqueidentifier,
	QuestionID uniqueidentifier, NodeID uniqueidentifier, SequenceNumber bigint IDENTITY(1,1),
	CreatorUserID uniqueidentifier, CreationDate datetime, Deleted bit)

INSERT INTO @TQ(ID, KnowledgeTypeID, QuestionID, NodeID, CreatorUserID, CreationDate, Deleted)
SELECT NEWID(), @ExperienceTypeID, Q.QuestionID, NULL, @UserID, GETDATE(), 0
FROM [dbo].[TMP_KW_Questions] AS Q
	INNER JOIN [dbo].[NGeneralQuestions] AS G
	ON Q.Title = G.Question
WHERE G.KnowledgeTypeID = 1

INSERT INTO @TQ(ID, KnowledgeTypeID, QuestionID, NodeID, CreatorUserID, CreationDate, Deleted)
SELECT NEWID(), @SkillTypeID, Q.QuestionID, NULL, @UserID, GETDATE(), 0
FROM [dbo].[TMP_KW_Questions] AS Q
	INNER JOIN [dbo].[NGeneralQuestions] AS G
	ON Q.Title = G.Question
WHERE G.KnowledgeTypeID = 2

INSERT INTO @TQ(ID, KnowledgeTypeID, QuestionID, NodeID, CreatorUserID, CreationDate, Deleted)
SELECT NEWID(), @ContentTypeID, Q.QuestionID, NULL, @UserID, GETDATE(), 0
FROM [dbo].[TMP_KW_Questions] AS Q
	INNER JOIN [dbo].[NGeneralQuestions] AS G
	ON Q.Title = G.Question
WHERE G.KnowledgeTypeID = 3

INSERT INTO @TQ(ID, KnowledgeTypeID, QuestionID, NodeID, CreatorUserID, CreationDate, Deleted)
SELECT NEWID(), @ExperienceTypeID, Q.QuestionID, G.NodeID, @UserID, GETDATE(), 0
FROM [dbo].[TMP_KW_Questions] AS Q
	INNER JOIN [dbo].[NQuestions] AS G
	ON Q.Title = G.Question
WHERE G.KnowledgeTypeID = 1

INSERT INTO @TQ(ID, KnowledgeTypeID, QuestionID, NodeID, CreatorUserID, CreationDate, Deleted)
SELECT NEWID(), @SkillTypeID, Q.QuestionID, G.NodeID, @UserID, GETDATE(), 0
FROM [dbo].[TMP_KW_Questions] AS Q
	INNER JOIN [dbo].[NQuestions] AS G
	ON Q.Title = G.Question
WHERE G.KnowledgeTypeID = 2

INSERT INTO @TQ(ID, KnowledgeTypeID, QuestionID, NodeID, CreatorUserID, CreationDate, Deleted)
SELECT NEWID(), @ContentTypeID, Q.QuestionID, G.NodeID, @UserID, GETDATE(), 0
FROM [dbo].[TMP_KW_Questions] AS Q
	INNER JOIN [dbo].[NQuestions] AS G
	ON Q.Title = G.Question
WHERE G.KnowledgeTypeID = 3

INSERT INTO [dbo].[TMP_KW_TypeQuestions](ID, KnowledgeTypeID, QuestionID, NodeID,
	SequenceNumber, CreatorUserID, CreationDate, Deleted)
SELECT *
FROM @TQ

GO