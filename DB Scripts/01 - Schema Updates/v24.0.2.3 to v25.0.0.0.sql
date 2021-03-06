USE [EKM_App]
GO


ALTER TABLE [dbo].[CN_Services]
ADD [IsDocument] [bit] NULL,
	[IsKnowledge] [bit] NULL,
	[EditSuggestion] [bit] NULL
GO


UPDATE [dbo].[CN_Services]
	SET EditSuggestion = 1
GO


ALTER TABLE [dbo].[CN_Nodes]
ADD [DocumentTreeNodeID] [uniqueidentifier] NULL,
	[PreviousVersionID] [uniqueidentifier] NULL,
	[PublicationDate] [datetime] NULL,
	[Status] [varchar](20) NULL,
	[Score] [float] NULL
GO


UPDATE ND
	SET DocumentTreeNodeID = KW.TreeNodeID,
		PreviousVersionID = KW.PreviousVersionID,
		PublicationDate = KW.PublicationDate,
		[Status] = S.Name,
		Score = KW.Score,
		Searchable = CASE WHEN KW.StatusID = 6 THEN 1 ELSE 0 END
FROM [dbo].[KW_Knowledges] AS KW
	INNER JOIN [dbo].[CN_Nodes] AS ND
	ON ND.NodeID = KW.KnowledgeID
	LEFT JOIN [dbo].[KWF_Statuses] AS S
	ON KW.StatusID = S.StatusID
GO


/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS(select * FROM sys.views where name = 'KW_View_ContentFileExtensions')
DROP VIEW [dbo].[KW_View_ContentFileExtensions]
GO

IF EXISTS(select * FROM sys.views where name = 'KW_View_Knowledges')
DROP VIEW [dbo].[KW_View_Knowledges]
GO

CREATE VIEW [dbo].[KW_View_Knowledges] WITH SCHEMABINDING, ENCRYPTION
AS
SELECT     dbo.KW_Knowledges.KnowledgeID, dbo.KW_Knowledges.KnowledgeTypeID,
		   dbo.KW_KnowledgeTypes.Name AS KnowledgeType, 
		   dbo.CN_Nodes.AdditionalID AS AdditionalID,
		   dbo.KW_Knowledges.PreviousVersionID,
		   dbo.KW_Knowledges.ContentType, dbo.KW_Knowledges.IsDefault, 
           dbo.KW_Knowledges.ExtendedFormID, dbo.KW_Knowledges.TreeNodeID, 
           dbo.KW_Knowledges.ConfidentialityLevelID, dbo.KW_Knowledges.StatusID, 
           dbo.KW_Knowledges.PublicationDate, dbo.CN_Nodes.Name AS Title, 
           dbo.CN_Nodes.CreatorUserID, dbo.CN_Nodes.LastModifierUserID, 
           dbo.CN_Nodes.CreationDate, dbo.CN_Nodes.LastModificationDate, 
           dbo.KW_Knowledges.Score, dbo.KW_Knowledges.ScoresWeight,
           dbo.CN_Nodes.Privacy, dbo.CN_Nodes.Deleted
FROM       dbo.CN_Nodes INNER JOIN dbo.KW_Knowledges ON 
		   dbo.CN_Nodes.NodeID = dbo.KW_Knowledges.KnowledgeID INNER JOIN
		   dbo.KW_KnowledgeTypes ON 
		   dbo.KW_Knowledges.KnowledgeTypeID = dbo.KW_KnowledgeTypes.KnowledgeTypeID

GO


INSERT INTO [dbo].[CN_NodeCreators](NodeID, UserID, CollaborationShare, CreatorUserID,
	CreationDate, Deleted)
SELECT KW.KnowledgeID, KW.CreatorUserID, 100, KW.CreatorUserID, KW.CreationDate, 0
FROM [dbo].[KW_View_Knowledges] AS KW
WHERE NOT EXISTS(
		SELECT TOP(1) *
		FROM [dbo].[KW_CreatorUsers] AS CU
		WHERE CU.KnowledgeID = KW.KnowledgeID
	)
GO
	

INSERT INTO [dbo].[CN_NodeCreators](NodeID, UserID, CollaborationShare, CreatorUserID,
	CreationDate, Deleted)
SELECT KW.KnowledgeID, CU.UserID, CU.CollaborationShare, 
	KW.CreatorUserID, KW.CreationDate, 0
FROM [dbo].[KW_View_Knowledges] AS KW
	INNER JOIN [dbo].[KW_CreatorUsers] AS CU
	ON CU.KnowledgeID = KW.KnowledgeID
GO

IF EXISTS(select * FROM sys.views where name = 'KW_View_Knowledges')
DROP VIEW [dbo].[KW_View_Knowledges]
GO


ALTER TABLE [dbo].[NTFN_Dashboards]
ADD [SubType] varchar(20) NULL
GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[NTFN_P_SendDashboards]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[NTFN_P_SendDashboards]
GO

IF EXISTS (SELECT * FROM sys.types WHERE is_table_type = 1 AND name = 'DashboardTableType')
DROP TYPE dbo.DashboardTableType
GO


CREATE TABLE [dbo].[MSG_Messages](
	[MessageID]				UNIQUEIDENTIFIER NOT NULL,
	[Title]					NVARCHAR(500) NULL,
	[MessageText]			NVARCHAR(MAX) NOT NULL,
	[SenderUserID]			UNIQUEIDENTIFIER NOT NULL,
	[SendDate]				DATETIME NOT NULL,
	[ForwardedFrom]			UNIQUEIDENTIFIER NULL,
	[HasAttachment]			BIT NOT NULL
	CONSTRAINT [PK_MSG_Messages] PRIMARY KEY CLUSTERED 
	(
		[MessageID] ASC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


ALTER TABLE [dbo].[MSG_Messages] WITH CHECK ADD CONSTRAINT [FK_MSG_Messages_MSG_Messages] FOREIGN KEY([ForwardedFrom])
REFERENCES [dbo].[MSG_Messages] ([MessageID])
GO

ALTER TABLE [dbo].[MSG_Messages] CHECK CONSTRAINT [FK_MSG_Messages_MSG_Messages]
GO


ALTER TABLE [dbo].[MSG_Messages] WITH CHECK ADD CONSTRAINT [FK_MSG_Messages_aspnet_Users] FOREIGN KEY([SenderUserID])
REFERENCES [dbo].[aspnet_Users] ([UserID])
GO

ALTER TABLE [dbo].[MSG_Messages] CHECK CONSTRAINT [FK_MSG_Messages_MSG_Messages]
GO



CREATE TABLE [dbo].[MSG_MessageDetails](
	[ID]					BIGINT IDENTITY(1,1) NOT NULL,
	[UserID]				UNIQUEIDENTIFIER  NOT NULL,
	[ThreadID]				UNIQUEIDENTIFIER  NOT NULL,
	[MessageID]				UNIQUEIDENTIFIER  NOT NULL,
	[Seen]					BIT NOT NULL,
	[ViewDate]				DATETIME NULL,
	[IsSender]				BIT NOT NULL,
	[IsGroup]				BIT NOT NULL,
	[Deleted]				BIT NOT NULL
	
	CONSTRAINT [PK_MSG_MessageDetails] PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[MSG_MessageDetails] WITH CHECK ADD CONSTRAINT [FK_MSG_MessageDetails_aspnet_Users] FOREIGN KEY([UserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[MSG_MessageDetails] CHECK CONSTRAINT [FK_MSG_MessageDetails_aspnet_Users]
GO


ALTER TABLE [dbo].[MSG_MessageDetails] WITH CHECK ADD CONSTRAINT [FK_MSG_MessageDetails_MSG_Messages] FOREIGN KEY([MessageID])
REFERENCES [dbo].[MSG_Messages] ([MessageID])
GO

ALTER TABLE [dbo].[MSG_MessageDetails] CHECK CONSTRAINT [FK_MSG_MessageDetails_MSG_Messages]
GO




INSERT [dbo].[MSG_Messages](
	MessageID,
	Title,
	MessageText,
	SenderUserID,
	SendDate,
	ForwardedFrom,
	HasAttachment
)
SELECT
	MSG.ID,
	MSG.[Subject],
	MSG.[FullText],
	MSG.[SenderUserID],
	MSG.DateSent,
	MSG.ParentId,
	CASE WHEN Ref.ID IS NULL THEN 0 ELSE 1 END
FROM [dbo].[Messages] AS MSG
	LEFT JOIN (
		SELECT MSG.ID
		FROM [dbo].[Messages] AS MSG
			INNER JOIN [dbo].[Attachments] AS AT
			ON AT.ObjectID = MSG.ID
		GROUP BY MSG.ID
	) AS Ref
	ON Ref.ID = MSG.ID
WHERE MSG.DateSent IS NOT NULL
GO



INSERT [dbo].[MSG_MessageDetails](
	UserID,
	ThreadID,
	MessageID,
	Seen,
	ViewDate,
	IsSender,
	IsGroup,
	Deleted
)
SELECT	Ref.UserID,
		Ref.ThreadID,
		Ref.MessageID,
		Ref.Seen,
		Ref.ViewDate,
		Ref.IsSender,
		Ref.IsGroup,
		Ref.Deleted
FROM (
		SELECT	U.ReceiverUserId AS UserID,
				M.SenderUserId AS ThreadID,
				M.ID AS MessageID,
				CASE
					WHEN U.DateFirstRead IS NULL THEN 0 ELSE 1
				END AS Seen,
				U.DateFirstRead AS ViewDate,
				0 AS IsSender,
				0 AS IsGroup,
				0 AS Deleted,
				M.DateSent AS SendDate
		FROM [dbo].[Messages] AS M
			INNER JOIN [dbo].[MessageUsers] AS U
			ON U.MessageId = M.ID
			
		UNION ALL
			
		SELECT	M.SenderUserId AS UserID,
				U.ReceiverUserId AS ThreadID,
				M.ID AS MessageID,
				1 AS Seen,
				NULL AS ViewDate,
				1 AS IsSender,
				0 AS IsGroup,
				0 AS Deleted,
				M.DateSent AS SendDate
		FROM [dbo].[Messages] AS M
			INNER JOIN [dbo].[MessageUsers] AS U
			ON U.MessageId = M.ID
	) AS Ref
WHERE Ref.MessageID IN (SELECT M.MessageID FROM [dbo].[MSG_Messages] AS M)
ORDER BY Ref.SendDate ASC, IsSender DESC

GO


DROP TABLE [dbo].[MessageUsers]
GO

DROP TABLE [dbo].[Messages]
GO


/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[TMP_KW_KnowledgeTypes](
	[KnowledgeTypeID] [uniqueidentifier] NOT NULL,
	[EvaluationType] [varchar](20) NULL,
	[Evaluators] [varchar](20) NULL,
	[MinEvaluationsCount] [int] NULL,
	[NodeSelectType] [varchar](20) NULL,
	[SearchableAfter] [varchar](20) NULL,
	[ScoreScale] [int] NULL,
	[MinAcceptableScore] [int] NULL,
	[CreatorUserID] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL
 CONSTRAINT [PK_TMP_KW_KnowledgeTypes] PRIMARY KEY CLUSTERED 
(
	[KnowledgeTypeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


ALTER TABLE [dbo].[TMP_KW_KnowledgeTypes]  WITH CHECK ADD  CONSTRAINT [FK_TMP_KW_KnowledgeTypes_CN_NodeTypes] FOREIGN KEY([KnowledgeTypeID])
REFERENCES [dbo].[CN_NodeTypes] ([NodeTypeID])
GO

ALTER TABLE [dbo].[TMP_KW_KnowledgeTypes] CHECK CONSTRAINT [FK_TMP_KW_KnowledgeTypes_CN_NodeTypes]
GO

ALTER TABLE [dbo].[TMP_KW_KnowledgeTypes]  WITH CHECK ADD  CONSTRAINT [FK_TMP_KW_KnowledgeTypes_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[TMP_KW_KnowledgeTypes] CHECK CONSTRAINT [FK_TMP_KW_KnowledgeTypes_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[TMP_KW_KnowledgeTypes]  WITH CHECK ADD  CONSTRAINT [FK_TMP_KW_KnowledgeTypes_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[TMP_KW_KnowledgeTypes] CHECK CONSTRAINT [FK_TMP_KW_KnowledgeTypes_aspnet_Users_Modifier]
GO


/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[TMP_KW_Questions](
	[QuestionID] [uniqueidentifier] NOT NULL,
	[Title] [nvarchar](2000) NOT NULL,
	[CreatorUserID] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL
 CONSTRAINT [PK_TMP_KW_Questions] PRIMARY KEY CLUSTERED 
(
	[QuestionID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


ALTER TABLE [dbo].[TMP_KW_Questions]  WITH CHECK ADD  CONSTRAINT [FK_TMP_KW_Questions_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[TMP_KW_Questions] CHECK CONSTRAINT [FK_TMP_KW_Questions_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[TMP_KW_Questions]  WITH CHECK ADD  CONSTRAINT [FK_TMP_KW_Questions_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[TMP_KW_Questions] CHECK CONSTRAINT [FK_TMP_KW_Questions_aspnet_Users_Modifier]
GO



/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[TMP_KW_TypeQuestions](
	[ID] [uniqueidentifier] NOT NULL,
	[KnowledgeTypeID] [uniqueidentifier] NOT NULL,
	[QuestionID] [uniqueidentifier] NOT NULL,
	[NodeID] [uniqueidentifier] NULL,
	[SequenceNumber] [bigint] NOT NULL,
	[CreatorUserID] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL
 CONSTRAINT [PK_TMP_KW_TypeQuestions] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


ALTER TABLE [dbo].[TMP_KW_TypeQuestions]  WITH CHECK ADD  CONSTRAINT [FK_TMP_KW_TypeQuestions_TMP_KW_KnowledgeTypes] FOREIGN KEY([KnowledgeTypeID])
REFERENCES [dbo].[TMP_KW_KnowledgeTypes] ([KnowledgeTypeID])
GO

ALTER TABLE [dbo].[TMP_KW_TypeQuestions] CHECK CONSTRAINT [FK_TMP_KW_TypeQuestions_TMP_KW_KnowledgeTypes]
GO

ALTER TABLE [dbo].[TMP_KW_TypeQuestions]  WITH CHECK ADD  CONSTRAINT [FK_TMP_KW_TypeQuestions_TMP_KW_Questions] FOREIGN KEY([QuestionID])
REFERENCES [dbo].[TMP_KW_Questions] ([QuestionID])
GO

ALTER TABLE [dbo].[TMP_KW_TypeQuestions] CHECK CONSTRAINT [FK_TMP_KW_TypeQuestions_TMP_KW_Questions]
GO

ALTER TABLE [dbo].[TMP_KW_TypeQuestions]  WITH CHECK ADD  CONSTRAINT [FK_TMP_KW_TypeQuestions_CN_Nodes] FOREIGN KEY([NodeID])
REFERENCES [dbo].[CN_Nodes] ([NodeID])
GO

ALTER TABLE [dbo].[TMP_KW_TypeQuestions] CHECK CONSTRAINT [FK_TMP_KW_TypeQuestions_CN_Nodes]
GO

ALTER TABLE [dbo].[TMP_KW_TypeQuestions]  WITH CHECK ADD  CONSTRAINT [FK_TMP_KW_TypeQuestions_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[TMP_KW_TypeQuestions] CHECK CONSTRAINT [FK_TMP_KW_TypeQuestions_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[TMP_KW_TypeQuestions]  WITH CHECK ADD  CONSTRAINT [FK_TMP_KW_TypeQuestions_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[TMP_KW_TypeQuestions] CHECK CONSTRAINT [FK_TMP_KW_TypeQuestions_aspnet_Users_Modifier]
GO


/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[TMP_KW_CandidateRelations](
	[ID] [uniqueidentifier] NOT NULL,
	[KnowledgeTypeID] [uniqueidentifier] NOT NULL,
	[NodeID] [uniqueidentifier] NULL,
	[NodeTypeID] [uniqueidentifier] NULL,
	[CreatorUserID] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL
 CONSTRAINT [PK_TMP_KW_CandidateRelations] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


ALTER TABLE [dbo].[TMP_KW_CandidateRelations]  WITH CHECK ADD  CONSTRAINT [FK_TMP_KW_CandidateRelations_TMP_KW_KnowledgeTypes] FOREIGN KEY([KnowledgeTypeID])
REFERENCES [dbo].[TMP_KW_KnowledgeTypes] ([KnowledgeTypeID])
GO

ALTER TABLE [dbo].[TMP_KW_CandidateRelations] CHECK CONSTRAINT [FK_TMP_KW_CandidateRelations_TMP_KW_KnowledgeTypes]
GO

ALTER TABLE [dbo].[TMP_KW_CandidateRelations]  WITH CHECK ADD  CONSTRAINT [FK_TMP_KW_CandidateRelations_CN_Nodes] FOREIGN KEY([NodeID])
REFERENCES [dbo].[CN_Nodes] ([NodeID])
GO

ALTER TABLE [dbo].[TMP_KW_CandidateRelations] CHECK CONSTRAINT [FK_TMP_KW_CandidateRelations_CN_Nodes]
GO

ALTER TABLE [dbo].[TMP_KW_CandidateRelations]  WITH CHECK ADD  CONSTRAINT [FK_TMP_KW_CandidateRelations_CN_NodeTypes] FOREIGN KEY([NodeTypeID])
REFERENCES [dbo].[CN_NodeTypes] ([NodeTypeID])
GO

ALTER TABLE [dbo].[TMP_KW_CandidateRelations] CHECK CONSTRAINT [FK_TMP_KW_CandidateRelations_CN_NodeTypes]
GO

ALTER TABLE [dbo].[TMP_KW_CandidateRelations]  WITH CHECK ADD  CONSTRAINT [FK_TMP_KW_CandidateRelations_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[TMP_KW_CandidateRelations] CHECK CONSTRAINT [FK_TMP_KW_CandidateRelations_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[TMP_KW_CandidateRelations]  WITH CHECK ADD  CONSTRAINT [FK_TMP_KW_CandidateRelations_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[TMP_KW_CandidateRelations] CHECK CONSTRAINT [FK_TMP_KW_CandidateRelations_aspnet_Users_Modifier]
GO


/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[TMP_KW_QuestionAnswers](
	[KnowledgeID] [uniqueidentifier] NOT NULL,
	[UserID] [uniqueidentifier] NOT NULL,
	[QuestionID] [uniqueidentifier] NOT NULL,
	[Title] [nvarchar](2000) NOT NULL,
	[Score] [float] NOT NULL,
	[ResponderUserID] [uniqueidentifier] NULL,
	[EvaluationDate] [datetime] NOT NULL,
	[Deleted] [bit] NOT NULL
 CONSTRAINT [PK_TMP_KW_QuestionAnswers] PRIMARY KEY CLUSTERED 
(
	[KnowledgeID] ASC,
	[UserID] ASC,
	[QuestionID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


ALTER TABLE [dbo].[TMP_KW_QuestionAnswers]  WITH CHECK ADD  CONSTRAINT [FK_TMP_KW_QuestionAnswers_CN_Nodes] FOREIGN KEY([KnowledgeID])
REFERENCES [dbo].[CN_Nodes] ([NodeID])
GO

ALTER TABLE [dbo].[TMP_KW_QuestionAnswers] CHECK CONSTRAINT [FK_TMP_KW_QuestionAnswers_CN_Nodes]
GO

ALTER TABLE [dbo].[TMP_KW_QuestionAnswers]  WITH CHECK ADD  CONSTRAINT [FK_TMP_KW_QuestionAnswers_TMP_KW_Questions] FOREIGN KEY([QuestionID])
REFERENCES [dbo].[TMP_KW_Questions] ([QuestionID])
GO

ALTER TABLE [dbo].[TMP_KW_QuestionAnswers] CHECK CONSTRAINT [FK_TMP_KW_QuestionAnswers_TMP_KW_Questions]
GO

ALTER TABLE [dbo].[TMP_KW_QuestionAnswers]  WITH CHECK ADD  CONSTRAINT [FK_TMP_KW_QuestionAnswers_aspnet_Users] FOREIGN KEY([UserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[TMP_KW_QuestionAnswers] CHECK CONSTRAINT [FK_TMP_KW_QuestionAnswers_aspnet_Users]
GO


/****** Object:  Table [dbo].[KWF_Paraphs]    Script Date: 02/05/2014 14:54:42 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[TMP_KW_History](
	[ID] [bigint] IDENTITY(1,1),
	[KnowledgeID] [uniqueidentifier] NOT NULL,
	[Action] [varchar](50) NOT NULL,
	[Description] [nvarchar](2000) NULL,
	[ActorUserID] [uniqueidentifier] NOT NULL,
	[ActionDate] [datetime] NOT NULL
 CONSTRAINT [PK_TMP_KW_History] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[TMP_KW_History]  WITH CHECK ADD  CONSTRAINT [FK_TMP_KW_History_CN_Nodes] FOREIGN KEY([KnowledgeID])
REFERENCES [dbo].[CN_Nodes] ([NodeID])
GO

ALTER TABLE [dbo].[TMP_KW_History] CHECK CONSTRAINT [FK_TMP_KW_History_CN_Nodes]
GO

ALTER TABLE [dbo].[TMP_KW_History]  WITH CHECK ADD  CONSTRAINT [FK_TMP_KW_History_aspnet_Users] FOREIGN KEY([ActorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[TMP_KW_History] CHECK CONSTRAINT [FK_TMP_KW_History_aspnet_Users]
GO



/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER TABLE [dbo].[CN_Nodes]
DROP COLUMN TSkill
GO

ALTER TABLE [dbo].[CN_Nodes]
DROP COLUMN TExperience
GO

ALTER TABLE [dbo].[CN_Nodes]
DROP COLUMN TContent
GO


/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[TMP_KW_TempKnowledgeTypeIDs](
	[IntID] [int] NOT NULL,
	[Guid] [uniqueidentifier] NOT NULL
 CONSTRAINT [PK_TMP_KW_TempKnowledgeTypeIDs] PRIMARY KEY CLUSTERED 
(
	[IntID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


INSERT INTO [dbo].[TMP_KW_TempKnowledgeTypeIDs]
SELECT KnowledgeTypeID, NEWID()
FROM [dbo].[KW_KnowledgeTypes]

GO



/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

DECLARE @UserID uniqueidentifier = (SELECT TOP(1) UserId FROM [dbo].[aspnet_Users]
	WHERE LoweredUserName = N'admin')

DECLARE @KnowledgeTypeID uniqueidentifier = [dbo].[CN_FN_GetKnowledgeNodeTypeID]()

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

/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

DECLARE @PropertyID uniqueidentifier = [dbo].[CN_FN_GetRelatedRelationTypeID]()


INSERT INTO [dbo].[CN_NodeRelations](SourceNodeID, DestinationNodeID, PropertyID, Deleted)
SELECT KnowledgeID, NodeID, @PropertyID, ISNULL(Deleted, 0)
FROM [dbo].[KW_RelatedNodes] AS RN
WHERE NOT EXISTS(
		SELECT TOP(1) *
		FROM [dbo].[CN_NodeRelations] AS NR
		WHERE NR.SourceNodeID = RN.KnowledgeID AND DestinationNodeID = RN.NodeID AND
			NR.PropertyID = @PropertyID
	)

GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* Confidentiality Related Procedures */

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SetUsersConfidentialityLevels]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SetUsersConfidentialityLevels]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_P_GetUsersConfidentialityLevels]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_P_GetUsersConfidentialityLevels]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetUsersConfidentialityLevels]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetUsersConfidentialityLevels]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetConfidentialityLevelUsers]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetConfidentialityLevelUsers]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_RemoveUsersConfidentialityLevels]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_RemoveUsersConfidentialityLevels]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetConfidentialityLevels]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetConfidentialityLevels]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_ChangeConfidentialityLevel]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_ChangeConfidentialityLevel]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_RemoveConfidentialityLevel]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_RemoveConfidentialityLevel]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_AddConfidentialityLevel]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_AddConfidentialityLevel]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_AddCard]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_AddCard]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_AddCards]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_AddCards]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_ArithmeticDeleteCards]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_ArithmeticDeleteCards]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_P_GetCardsByIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_P_GetCardsByIDs]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetCardsByIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetCardsByIDs]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetReceivedCards]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetReceivedCards]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetSentCards]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetSentCards]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_ArithmeticDeleteKnowledges]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_ArithmeticDeleteKnowledges]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SendKnowledgeToManager]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SendKnowledgeToManager]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SendBackForRevision]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SendBackForRevision]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SetKnowledgeStatus]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SetKnowledgeStatus]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_P_ClearWorkflow]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_P_ClearWorkflow]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SendKnowledgeToExperts]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SendKnowledgeToExperts]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_P_AutoAcceptRejectKnowledge]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_P_AutoAcceptRejectKnowledge]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_P_AutoSetRelatedNodeStatus]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_P_AutoSetRelatedNodeStatus]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_P_TerminateKnowledgeEvaluation]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_P_TerminateKnowledgeEvaluation]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SetExpertEvaluation]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SetExpertEvaluation]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_TerminateEvaluation]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_TerminateEvaluation]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SetEvaluatorEvaluation]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SetEvaluatorEvaluation]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_AddParaph]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_AddParaph]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_ModifyParaph]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_ModifyParaph]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_ArithmeticDeleteParaph]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_ArithmeticDeleteParaph]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetParaphs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetParaphs]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetCurrentExperts]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetCurrentExperts]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetCurrentEvaluators]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetCurrentEvaluators]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_RejectEvaluator]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_RejectEvaluator]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_RemoveEvaluator]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_RemoveEvaluator]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_P_AddKnowledgeRelatedItems]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_P_AddKnowledgeRelatedItems]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_AddKnowledge]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_AddKnowledge]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_ModifyKnowledge]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_ModifyKnowledge]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetKnowledgesCount]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetKnowledgesCount]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetNodesRelatedKnowledgesCount]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetNodesRelatedKnowledgesCount]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_P_GetKnowledgesByIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_P_GetKnowledgesByIDs]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetKnowledgesByIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetKnowledgesByIDs]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetKnowledges]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetKnowledges]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetLastKnowledges]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetLastKnowledges]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetPreviousVersions]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetPreviousVersions]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SearchKnowledges]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SearchKnowledges]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetPersonalKnowledges]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetPersonalKnowledges]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetTreeNodeKnowledges]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetTreeNodeKnowledges]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SetTreeNodeID]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SetTreeNodeID]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetDashboardsCount]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetDashboardsCount]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetDashboards]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetDashboards]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_IsKnowledgeCreator]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_IsKnowledgeCreator]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_IsKnowledgePersonal]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_IsKnowledgePersonal]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_ManagerDashboardExists]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_ManagerDashboardExists]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_EvaluatorDashboardExists]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_EvaluatorDashboardExists]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetContentType]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetContentType]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetRelatedKnowledges]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetRelatedKnowledges]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetRefrenceUserIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetRefrenceUserIDs]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetKnowledgeHolders]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetKnowledgeHolders]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetCompanies]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetCompanies]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetKnowledgeCreators]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetKnowledgeCreators]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetLearningMethods]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetLearningMethods]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetTripForms]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetTripForms]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_AddExperienceHolder]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_AddExperienceHolder]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_ArithmeticDeleteExperienceHolder]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_ArithmeticDeleteExperienceHolder]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_AddFeedBack]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_AddFeedBack]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_ModifyFeedBack]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_ModifyFeedBack]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_ArithmeticDeleteFeedBack]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_ArithmeticDeleteFeedBack]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_P_GetFeedBacksByIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_P_GetFeedBacksByIDs]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetFeedBacksByIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetFeedBacksByIDs]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetKnowledgeFeedBacks]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetKnowledgeFeedBacks]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetTripFormTreeNodeID]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetTripFormTreeNodeID]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetContentFileExtensions]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetContentFileExtensions]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetNodeRelatedKnowledgeIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetNodeRelatedKnowledgeIDs]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetNodeRelatedKnowledges]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetNodeRelatedKnowledges]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetRelatedKDIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetRelatedKDIDs]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetRelatedUserIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetRelatedUserIDs]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_SetFeedBack]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_SetFeedBack]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_ArithmeticDeleteFeedBack]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_ArithmeticDeleteFeedBack]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_P_AddKnowledgeManagers]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_P_AddKnowledgeManagers]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_AddKnowledgeManagers]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_AddKnowledgeManagers]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_ArithmeticDeleteKnowledgeManagers]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_ArithmeticDeleteKnowledgeManagers]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[KW_GetKnowledgeManagerIDs]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[KW_GetKnowledgeManagerIDs]
GO

/****** Object:  Table [dbo].[KKnowledges]    Script Date: 04/04/2012 12:34:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



UPDATE [dbo].[AppSetting]
	SET [Version] = 'v25.0.0.0' -- 13930511
GO

