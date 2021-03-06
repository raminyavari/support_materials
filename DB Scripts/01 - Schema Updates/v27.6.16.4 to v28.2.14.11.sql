USE [EKM_App]
GO


/****** Object:  Table [dbo].[QA_WorkFlows]    Script Date: 11/29/2016 08:54:16 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[QA_WorkFlows](
	[WorkFlowID] [uniqueidentifier] NOT NULL,
	[Name] [nvarchar](200) NOT NULL,
	[Description] [nvarchar](2000) NULL,
	[SequenceNumber] [int] NOT NULL,
	[InitialCheckNeeded] [bit] NOT NULL,
	[FinalConfirmationNeeded] [bit] NOT NULL,
	[ActionDeadline] [int] NULL,
	[AnswerBy] [varchar](50) NULL,
	[PublishAfter] [varchar](50) NULL,
	[RemovableAfterConfirmation] [bit] NOT NULL,
	[NodeSelectType] [varchar](50) NULL,
	[DisableComments] [bit] NOT NULL,
	[DisableQuestionLikes] [bit] NOT NULL,
	[DisableAnswerLikes] [bit] NOT NULL,
	[DisableCommentLikes] [bit] NOT NULL,
	[DisableBestAnswer] [bit] NOT NULL,
	[CreatorUserID] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL,
	[ApplicationID] [uniqueidentifier] NULL
 CONSTRAINT [PK_QA_WorkFlows] PRIMARY KEY CLUSTERED 
(
	[WorkFlowID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


ALTER TABLE [dbo].[QA_WorkFlows]  WITH CHECK ADD  CONSTRAINT [FK_QA_WorkFlows_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[QA_WorkFlows] CHECK CONSTRAINT [FK_QA_WorkFlows_aspnet_Applications]
GO

ALTER TABLE [dbo].[QA_WorkFlows]  WITH CHECK ADD  CONSTRAINT [FK_QA_WorkFlows_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[QA_WorkFlows] CHECK CONSTRAINT [FK_QA_WorkFlows_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[QA_WorkFlows]  WITH CHECK ADD  CONSTRAINT [FK_QA_WorkFlows_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[QA_WorkFlows] CHECK CONSTRAINT [FK_QA_WorkFlows_aspnet_Users_Modifier]
GO



/****** Object:  Table [dbo].[QA_Admins]    Script Date: 11/29/2016 08:54:16 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[QA_Admins](
	[UserID] [uniqueidentifier] NOT NULL,
	[WorkFlowID] [uniqueidentifier] NULL,
	[CreatorUserID] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL,
	[ApplicationID] [uniqueidentifier] NULL
 CONSTRAINT [PK_QA_Admins] PRIMARY KEY CLUSTERED 
(
	[UserID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[QA_Admins]  WITH CHECK ADD  CONSTRAINT [FK_QA_Admins_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[QA_Admins] CHECK CONSTRAINT [FK_QA_Admins_aspnet_Applications]
GO

ALTER TABLE [dbo].[QA_Admins]  WITH CHECK ADD  CONSTRAINT [FK_QA_Admins_aspnet_Users] FOREIGN KEY([UserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[QA_Admins] CHECK CONSTRAINT [FK_QA_Admins_aspnet_Users]
GO

ALTER TABLE [dbo].[QA_Admins]  WITH CHECK ADD  CONSTRAINT [FK_QA_Admins_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[QA_Admins] CHECK CONSTRAINT [FK_QA_Admins_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[QA_Admins]  WITH CHECK ADD  CONSTRAINT [FK_QA_Admins_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[QA_Admins] CHECK CONSTRAINT [FK_QA_Admins_aspnet_Users_Modifier]
GO

ALTER TABLE [dbo].[QA_Admins]  WITH CHECK ADD  CONSTRAINT [FK_QA_Admins_QA_WorkFlows] FOREIGN KEY([WorkFlowID])
REFERENCES [dbo].[QA_WorkFlows] ([WorkFlowID])
GO

ALTER TABLE [dbo].[QA_Admins] CHECK CONSTRAINT [FK_QA_Admins_QA_WorkFlows]
GO



/****** Object:  Table [dbo].[QA_Comments]    Script Date: 11/29/2016 08:54:16 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[QA_Comments](
	[CommentID] [uniqueidentifier] NOT NULL,
	[OwnerID] [uniqueidentifier] NOT NULL,
	[ReplyToCommentID] [uniqueidentifier] NULL,
	[BodyText] [nvarchar](max) NOT NULL,
	[SenderUserID] [uniqueidentifier] NOT NULL,
	[SendDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL,
	[ApplicationID] [uniqueidentifier] NULL
 CONSTRAINT [PK_QA_Comments] PRIMARY KEY CLUSTERED 
(
	[CommentID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[QA_Comments]  WITH CHECK ADD  CONSTRAINT [FK_QA_Comments_QA_Comments] FOREIGN KEY([ReplyToCommentID])
REFERENCES [dbo].[QA_Comments] ([CommentID])
GO

ALTER TABLE [dbo].[QA_Comments] CHECK CONSTRAINT [FK_QA_Comments_QA_Comments]
GO

ALTER TABLE [dbo].[QA_Comments]  WITH CHECK ADD  CONSTRAINT [FK_QA_Comments_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[QA_Comments] CHECK CONSTRAINT [FK_QA_Comments_aspnet_Applications]
GO

ALTER TABLE [dbo].[QA_Comments]  WITH CHECK ADD  CONSTRAINT [FK_QA_Comments_aspnet_Users_Sender] FOREIGN KEY([SenderUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[QA_Comments] CHECK CONSTRAINT [FK_QA_Comments_aspnet_Users_Sender]
GO

ALTER TABLE [dbo].[QA_Comments]  WITH CHECK ADD  CONSTRAINT [FK_QA_Comments_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[QA_Comments] CHECK CONSTRAINT [FK_QA_Comments_aspnet_Users_Modifier]
GO





ALTER TABLE [dbo].[QA_Answers]
DROP COLUMN [Status]
GO

ALTER TABLE [dbo].[QA_Answers]
DROP COLUMN [AcceptionDate]
GO

ALTER TABLE [dbo].[QA_Answers]
DROP COLUMN [Rate]
GO

ALTER TABLE [dbo].[QA_Answers]
DROP CONSTRAINT [FK_QA_Answers_CN_Nodes]
GO

ALTER TABLE [dbo].[QA_Answers]
DROP COLUMN [NodeID]
GO


ALTER TABLE [dbo].[QA_Questions]
DROP COLUMN [VisitsCount]
GO

ALTER TABLE [dbo].[QA_Questions]
ADD [BestAnswerID] [uniqueidentifier] NULL
GO

ALTER TABLE [dbo].[QA_Questions]
ADD [WorkFlowID] [uniqueidentifier] NULL
GO

ALTER TABLE [dbo].[QA_Questions]  WITH CHECK ADD  CONSTRAINT [FK_QA_Questions_QA_Answers] FOREIGN KEY([BestAnswerID])
REFERENCES [dbo].[QA_Answers] ([AnswerID])
GO

ALTER TABLE [dbo].[QA_Questions] CHECK CONSTRAINT [FK_QA_Questions_QA_Answers]
GO

ALTER TABLE [dbo].[QA_Questions]  WITH CHECK ADD  CONSTRAINT [FK_QA_Questions_QA_WorkFlows] FOREIGN KEY([WorkFlowID])
REFERENCES [dbo].[QA_WorkFlows] ([WorkFlowID])
GO

ALTER TABLE [dbo].[QA_Questions] CHECK CONSTRAINT [FK_QA_Questions_QA_WorkFlows]
GO


/****** Object:  Table [dbo].[RV_Followers]    Script Date: 11/29/2016 09:33:03 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[RV_Followers](
	[UserID] [uniqueidentifier] NOT NULL,
	[FollowedID] [uniqueidentifier] NOT NULL,
	[ActionDate] [datetime] NOT NULL,
	[ApplicationID] [uniqueidentifier] NULL,
 CONSTRAINT [PK_RV_Followers] PRIMARY KEY CLUSTERED 
(
	[UserID] ASC,
	[FollowedID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[RV_Followers]  WITH CHECK ADD  CONSTRAINT [FK_RV_Followers_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[RV_Followers] CHECK CONSTRAINT [FK_RV_Followers_aspnet_Applications]
GO

ALTER TABLE [dbo].[RV_Followers]  WITH CHECK ADD  CONSTRAINT [FK_RV_Followers_aspnet_Users] FOREIGN KEY([UserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[RV_Followers] CHECK CONSTRAINT [FK_RV_Followers_aspnet_Users]
GO





/****** Object:  Table [dbo].[RV_Likes]    Script Date: 11/29/2016 09:33:03 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[RV_Likes](
	[UserID] [uniqueidentifier] NOT NULL,
	[LikedID] [uniqueidentifier] NOT NULL,
	[Like] [bit] NOT NULL,
	[ActionDate] [datetime] NOT NULL,
	[ApplicationID] [uniqueidentifier] NULL,
 CONSTRAINT [PK_RV_Likes] PRIMARY KEY CLUSTERED 
(
	[UserID] ASC,
	[LikedID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[RV_Likes]  WITH CHECK ADD  CONSTRAINT [FK_RV_Likes_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[RV_Likes] CHECK CONSTRAINT [FK_RV_Likes_aspnet_Applications]
GO

ALTER TABLE [dbo].[RV_Likes]  WITH CHECK ADD  CONSTRAINT [FK_RV_Likes_aspnet_Users] FOREIGN KEY([UserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[RV_Likes] CHECK CONSTRAINT [FK_RV_Likes_aspnet_Users]
GO





INSERT INTO [dbo].[RV_Likes] (
	UserID,
	LikedID,
	[Like],
	ActionDate,
	ApplicationID
)
SELECT UserID, QuestionID, [Like], [Date], [ApplicationID]
FROM [dbo].[QA_QuestionLikes]

GO



DROP TABLE [dbo].[QA_QuestionLikes]
GO


/****** Object:  Table [dbo].[QA_FAQCategories]    Script Date: 11/29/2016 09:33:03 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[QA_FAQCategories](
	[CategoryID] [uniqueidentifier] NOT NULL,
	[ParentID] [uniqueidentifier] NULL,
	[SequenceNumber] [int] NOT NULL,
	[Name] [nvarchar](200) NOT NULL,
	[CreatorUserID]	[uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL,
	[ApplicationID] [uniqueidentifier] NULL
 CONSTRAINT [PK_QA_FAQCategories] PRIMARY KEY CLUSTERED 
(
	[CategoryID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[QA_FAQCategories]  WITH CHECK ADD  CONSTRAINT [FK_QA_FAQCategories_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[QA_FAQCategories] CHECK CONSTRAINT [FK_QA_FAQCategories_aspnet_Applications]
GO

ALTER TABLE [dbo].[QA_FAQCategories]  WITH CHECK ADD  CONSTRAINT [FK_QA_FAQCategories_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[QA_FAQCategories] CHECK CONSTRAINT [FK_QA_FAQCategories_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[QA_FAQCategories]  WITH CHECK ADD  CONSTRAINT [FK_QA_FAQCategories_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[QA_FAQCategories] CHECK CONSTRAINT [FK_QA_FAQCategories_aspnet_Users_Modifier]
GO

ALTER TABLE [dbo].[QA_FAQCategories]  WITH CHECK ADD  CONSTRAINT [FK_QA_FAQCategories_QA_FAQCategories] FOREIGN KEY([ParentID])
REFERENCES [dbo].[QA_FAQCategories] ([CategoryID])
GO

ALTER TABLE [dbo].[QA_FAQCategories] CHECK CONSTRAINT [FK_QA_FAQCategories_QA_FAQCategories]
GO




/****** Object:  Table [dbo].[QA_FAQItems]    Script Date: 11/29/2016 09:33:03 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[QA_FAQItems](
	[CategoryID] [uniqueidentifier] NOT NULL,
	[QuestionID] [uniqueidentifier] NOT NULL,
	[SequenceNumber] [int] NULL,
	[CreatorUserID]	[uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL,
	[ApplicationID] [uniqueidentifier] NULL
 CONSTRAINT [PK_QA_FAQItems] PRIMARY KEY CLUSTERED 
(
	[CategoryID] ASC,
	[QuestionID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[QA_FAQItems]  WITH CHECK ADD  CONSTRAINT [FK_QA_FAQItems_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[QA_FAQItems] CHECK CONSTRAINT [FK_QA_FAQItems_aspnet_Applications]
GO

ALTER TABLE [dbo].[QA_FAQItems]  WITH CHECK ADD  CONSTRAINT [FK_QA_FAQItems_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[QA_FAQItems] CHECK CONSTRAINT [FK_QA_FAQItems_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[QA_FAQItems]  WITH CHECK ADD  CONSTRAINT [FK_QA_FAQItems_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[QA_FAQItems] CHECK CONSTRAINT [FK_QA_FAQItems_aspnet_Users_Modifier]
GO

ALTER TABLE [dbo].[QA_FAQItems]  WITH CHECK ADD  CONSTRAINT [FK_QA_FAQItems_QA_FAQCategories] FOREIGN KEY([CategoryID])
REFERENCES [dbo].[QA_FAQCategories] ([CategoryID])
GO

ALTER TABLE [dbo].[QA_FAQItems] CHECK CONSTRAINT [FK_QA_FAQItems_QA_FAQCategories]
GO

ALTER TABLE [dbo].[QA_FAQItems]  WITH CHECK ADD  CONSTRAINT [FK_QA_FAQItems_QA_Questions] FOREIGN KEY([QuestionID])
REFERENCES [dbo].[QA_Questions] ([QuestionID])
GO

ALTER TABLE [dbo].[QA_FAQItems] CHECK CONSTRAINT [FK_QA_FAQItems_QA_Questions]
GO


/****** Object:  Table [dbo].[QA_Questions]    Script Date: 12/03/2016 12:38:51 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER TABLE [dbo].[QA_Answers] DROP CONSTRAINT [FK_QA_Answers_QA_Questions]
GO

ALTER TABLE [dbo].[QA_FAQItems] DROP CONSTRAINT [FK_QA_FAQItems_QA_Questions]
GO

ALTER TABLE [dbo].[QA_RefNodes] DROP CONSTRAINT [FK_QA_RefNodes_QA_Questions]
GO

ALTER TABLE [dbo].[QA_RefUsers] DROP CONSTRAINT [FK_QA_RefUsers_QA_Questions]
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[QA_TMPQuestions](
	[QuestionID] [uniqueidentifier] NOT NULL,
	[WorkFlowID] [uniqueidentifier] NULL,
	[Title] [nvarchar](500) NOT NULL,
	[Description] [nvarchar](max) NULL,
	[Status] [varchar](20) NOT NULL,
	[PublicationDate] [datetime] NULL,
	[BestAnswerID] [uniqueidentifier] NULL,
	[SenderUserID] [uniqueidentifier] NOT NULL,
	[SendDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL,
	[IndexLastUpdateDate] [datetime] NULL,
	[ApplicationID] [uniqueidentifier] NULL,
 CONSTRAINT [PK_QA_TMPQuestions] PRIMARY KEY CLUSTERED 
(
	[QuestionID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

INSERT INTO [dbo].[QA_TMPQuestions] (
	QuestionID, WorkFlowID, Title, [Description], [Status], PublicationDate,
	BestAnswerID, SenderUserID, SendDate, LastModifierUserID, LastModificationDate,
	Deleted, IndexLastUpdateDate, ApplicationID
)
SELECT QuestionID, WorkFlowID, Title, [Description], [Status], AcceptionDate,
	BestAnswerID, SenderUserID, SendDate, LastModifierUserID, LastModificationDate,
	Deleted, IndexLastUpdateDate, ApplicationID
FROM [dbo].[QA_Questions]

GO

DROP TABLE [dbo].[QA_Questions]
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[QA_Questions](
	[QuestionID] [uniqueidentifier] NOT NULL,
	[WorkFlowID] [uniqueidentifier] NULL,
	[Title] [nvarchar](500) NOT NULL,
	[Description] [nvarchar](max) NULL,
	[Status] [varchar](20) NOT NULL,
	[PublicationDate] [datetime] NULL,
	[BestAnswerID] [uniqueidentifier] NULL,
	[SenderUserID] [uniqueidentifier] NOT NULL,
	[SendDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL,
	[IndexLastUpdateDate] [datetime] NULL,
	[ApplicationID] [uniqueidentifier] NULL,
 CONSTRAINT [PK_QA_Questions] PRIMARY KEY CLUSTERED 
(
	[QuestionID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

INSERT INTO [dbo].[QA_Questions]
SELECT *
FROM [dbo].[QA_TMPQuestions]

GO

DROP TABLE [dbo].[QA_TMPQuestions]
GO

ALTER TABLE [dbo].[QA_Questions]  WITH CHECK ADD  CONSTRAINT [FK_QA_Questions_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[QA_Questions] CHECK CONSTRAINT [FK_QA_Questions_aspnet_Applications]
GO

ALTER TABLE [dbo].[QA_Questions]  WITH CHECK ADD  CONSTRAINT [FK_QA_Questions_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[QA_Questions] CHECK CONSTRAINT [FK_QA_Questions_aspnet_Users_Modifier]
GO

ALTER TABLE [dbo].[QA_Questions]  WITH CHECK ADD  CONSTRAINT [FK_QA_Questions_aspnet_Users_Sender] FOREIGN KEY([SenderUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[QA_Questions] CHECK CONSTRAINT [FK_QA_Questions_aspnet_Users_Sender]
GO

ALTER TABLE [dbo].[QA_Questions]  WITH CHECK ADD  CONSTRAINT [FK_QA_Questions_QA_Answers] FOREIGN KEY([BestAnswerID])
REFERENCES [dbo].[QA_Answers] ([AnswerID])
GO

ALTER TABLE [dbo].[QA_Questions] CHECK CONSTRAINT [FK_QA_Questions_QA_Answers]
GO


ALTER TABLE [dbo].[QA_Answers]  WITH CHECK ADD  CONSTRAINT [FK_QA_Answers_QA_Questions] FOREIGN KEY([QuestionID])
REFERENCES [dbo].[QA_Questions] ([QuestionID])
GO

ALTER TABLE [dbo].[QA_Answers] CHECK CONSTRAINT [FK_QA_Answers_QA_Questions]
GO

ALTER TABLE [dbo].[QA_FAQItems]  WITH CHECK ADD  CONSTRAINT [FK_QA_FAQItems_QA_Questions] FOREIGN KEY([QuestionID])
REFERENCES [dbo].[QA_Questions] ([QuestionID])
GO

ALTER TABLE [dbo].[QA_FAQItems] CHECK CONSTRAINT [FK_QA_FAQItems_QA_Questions]
GO

ALTER TABLE [dbo].[QA_RefNodes]  WITH CHECK ADD  CONSTRAINT [FK_QA_RefNodes_QA_Questions] FOREIGN KEY([QuestionID])
REFERENCES [dbo].[QA_Questions] ([QuestionID])
GO

ALTER TABLE [dbo].[QA_RefNodes] CHECK CONSTRAINT [FK_QA_RefNodes_QA_Questions]
GO

ALTER TABLE [dbo].[QA_RefUsers]  WITH CHECK ADD  CONSTRAINT [FK_QA_RefUsers_QA_Questions] FOREIGN KEY([QuestionID])
REFERENCES [dbo].[QA_Questions] ([QuestionID])
GO

ALTER TABLE [dbo].[QA_RefUsers] CHECK CONSTRAINT [FK_QA_RefUsers_QA_Questions]
GO


/****** Object:  Table [dbo].[QA_RelatedNodes]    Script Date: 11/29/2016 09:33:03 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[QA_RelatedNodes](
	[NodeID] [uniqueidentifier] NOT NULL,
	[QuestionID] [uniqueidentifier] NOT NULL,
	[CreatorUserID] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL,
	[ApplicationID] [uniqueidentifier] NULL,
 CONSTRAINT [PK_QA_RelatedNodes] PRIMARY KEY CLUSTERED 
(
	[NodeID] ASC,
	[QuestionID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


ALTER TABLE [dbo].[QA_RelatedNodes]  WITH CHECK ADD  CONSTRAINT [FK_QA_RelatedNodes_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[QA_RelatedNodes] CHECK CONSTRAINT [FK_QA_RelatedNodes_aspnet_Applications]
GO

ALTER TABLE [dbo].[QA_RelatedNodes]  WITH CHECK ADD  CONSTRAINT [FK_QA_RelatedNodes_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[QA_RelatedNodes] CHECK CONSTRAINT [FK_QA_RelatedNodes_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[QA_RelatedNodes]  WITH CHECK ADD  CONSTRAINT [FK_QA_RelatedNodes_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[QA_RelatedNodes] CHECK CONSTRAINT [FK_QA_RelatedNodes_aspnet_Users_Modifier]
GO

ALTER TABLE [dbo].[QA_RelatedNodes]  WITH CHECK ADD  CONSTRAINT [FK_QA_RelatedNodes_CN_Nodes] FOREIGN KEY([NodeID])
REFERENCES [dbo].[CN_Nodes] ([NodeID])
GO

ALTER TABLE [dbo].[QA_RelatedNodes] CHECK CONSTRAINT [FK_QA_RelatedNodes_CN_Nodes]
GO

ALTER TABLE [dbo].[QA_RelatedNodes]  WITH CHECK ADD  CONSTRAINT [FK_QA_RelatedNodes_QA_Questions] FOREIGN KEY([QuestionID])
REFERENCES [dbo].[QA_Questions] ([QuestionID])
GO

ALTER TABLE [dbo].[QA_RelatedNodes] CHECK CONSTRAINT [FK_QA_RelatedNodes_QA_Questions]
GO




INSERT INTO [dbo].[QA_RelatedNodes] (
	ApplicationID,
	NodeID,
	QuestionID,
	CreatorUserID,
	CreationDate,
	Deleted
)
SELECT	N.ApplicationID, 
		N.NodeID, 
		N.QuestionID, 
		(
			SELECT TOP(1) UserId
			FROM [dbo].[aspnet_Users]
			WHERE ApplicationID = N.ApplicationID AND LoweredUserName = N'admin'
		), 
		N.SendDate, 
		0
FROM [dbo].[QA_RefNodes] AS N

GO



DROP TABLE [dbo].[QA_RefNodes]
GO


/****** Object:  Table [dbo].[QA_RelatedUsers]    Script Date: 11/29/2016 09:33:03 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[QA_RelatedUsers](
	[UserID] [uniqueidentifier] NOT NULL,
	[QuestionID] [uniqueidentifier] NOT NULL,
	[SenderUserID] [uniqueidentifier] NOT NULL,
	[SendDate] [datetime] NOT NULL,
	[Seen] [bit] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL,
	[ApplicationID] [uniqueidentifier] NULL,
 CONSTRAINT [PK_QA_RelatedUsers] PRIMARY KEY CLUSTERED 
(
	[UserID] ASC,
	[QuestionID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


ALTER TABLE [dbo].[QA_RelatedUsers]  WITH CHECK ADD  CONSTRAINT [FK_QA_RelatedUsers_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[QA_RelatedUsers] CHECK CONSTRAINT [FK_QA_RelatedUsers_aspnet_Applications]
GO

ALTER TABLE [dbo].[QA_RelatedUsers]  WITH CHECK ADD  CONSTRAINT [FK_QA_RelatedUsers_aspnet_Users] FOREIGN KEY([UserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[QA_RelatedUsers] CHECK CONSTRAINT [FK_QA_RelatedUsers_aspnet_Users]
GO

ALTER TABLE [dbo].[QA_RelatedUsers]  WITH CHECK ADD  CONSTRAINT [FK_QA_RelatedUsers_aspnet_Users_Sender] FOREIGN KEY([SenderUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[QA_RelatedUsers] CHECK CONSTRAINT [FK_QA_RelatedUsers_aspnet_Users_Sender]
GO

ALTER TABLE [dbo].[QA_RelatedUsers]  WITH CHECK ADD  CONSTRAINT [FK_QA_RelatedUsers_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[QA_RelatedUsers]  WITH CHECK ADD  CONSTRAINT [FK_QA_RelatedUsers_QA_Questions] FOREIGN KEY([QuestionID])
REFERENCES [dbo].[QA_Questions] ([QuestionID])
GO

ALTER TABLE [dbo].[QA_RelatedUsers] CHECK CONSTRAINT [FK_QA_RelatedUsers_QA_Questions]
GO



INSERT INTO [dbo].[QA_RelatedUsers] (
	ApplicationID,
	UserID,
	QuestionID,
	SenderUserID,
	SendDate,
	Seen,
	Deleted
)
SELECT	U.ApplicationID, 
		U.UserID, 
		U.QuestionID, 
		(
			SELECT TOP(1) UserId
			FROM [dbo].[aspnet_Users]
			WHERE ApplicationID = U.ApplicationID AND LoweredUserName = N'admin'
		), 
		U.SendDate, 
		U.Seen,
		0
FROM [dbo].[QA_RefUsers] AS U

GO



DROP TABLE [dbo].[QA_RefUsers]
GO



UPDATE [dbo].[QA_Questions]
SET [Status] = CASE WHEN [Status] = N'Final' THEN N'Accepted' ELSE N'GettingAnswers' END

GO


SET ANSI_NULLS ON
GO

SET ANSI_PADDING ON
GO


DECLARE @Now datetime = GETDATE()

DECLARE @NodeTypes Table (AdditionalID varchar(20), Name nvarchar(500))

INSERT INTO @NodeTypes (AdditionalID, Name)
VALUES ('11', N'تگ')

INSERT INTO [dbo].[CN_NodeTypes] (
	[ApplicationID],
	[NodeTypeID], 
	[Name], 
	[Deleted], 
	[CreatorUserID], 
	[CreationDate],
	[AdditionalID]
) 
SELECT  App.ApplicationId, 
		NEWID(), 
		[dbo].[GFN_VerifyString](NT.Name), 
		0, 
		UN.UserID, 
		@Now, 
		NT.AdditionalID
FROM [dbo].[aspnet_Applications] AS App
	CROSS JOIN @NodeTypes AS NT
	LEFT JOIN [dbo].[CN_NodeTypes] AS T
	ON T.ApplicationID = App.ApplicationId AND T.AdditionalID = NT.AdditionalID
	INNER JOIN [dbo].[Users_Normal] AS UN
	ON UN.ApplicationID = App.ApplicationId AND LOWER(UN.UserName) = N'admin'
WHERE T.NodeTypeID IS NULL


GO


/****** Object:  Table [dbo].[QA_CandidateRelations]    Script Date: 02/21/2017 16:16:56 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[QA_CandidateRelations](
	[ID] [uniqueidentifier] NOT NULL,
	[WorkFlowID] [uniqueidentifier] NOT NULL,
	[NodeID] [uniqueidentifier] NULL,
	[NodeTypeID] [uniqueidentifier] NULL,
	[CreatorUserID] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL,
	[ApplicationID] [uniqueidentifier] NULL,
 CONSTRAINT [PK_QA_CandidateRelations] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[QA_CandidateRelations]  WITH CHECK ADD  CONSTRAINT [FK_QA_CandidateRelations_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[QA_CandidateRelations] CHECK CONSTRAINT [FK_QA_CandidateRelations_aspnet_Applications]
GO

ALTER TABLE [dbo].[QA_CandidateRelations]  WITH CHECK ADD  CONSTRAINT [FK_QA_CandidateRelations_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[QA_CandidateRelations] CHECK CONSTRAINT [FK_QA_CandidateRelations_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[QA_CandidateRelations]  WITH CHECK ADD  CONSTRAINT [FK_QA_CandidateRelations_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[QA_CandidateRelations] CHECK CONSTRAINT [FK_QA_CandidateRelations_aspnet_Users_Modifier]
GO

ALTER TABLE [dbo].[QA_CandidateRelations]  WITH CHECK ADD  CONSTRAINT [FK_QA_CandidateRelations_CN_Nodes] FOREIGN KEY([NodeID])
REFERENCES [dbo].[CN_Nodes] ([NodeID])
GO

ALTER TABLE [dbo].[QA_CandidateRelations] CHECK CONSTRAINT [FK_QA_CandidateRelations_CN_Nodes]
GO

ALTER TABLE [dbo].[QA_CandidateRelations]  WITH CHECK ADD  CONSTRAINT [FK_QA_CandidateRelations_CN_NodeTypes] FOREIGN KEY([NodeTypeID])
REFERENCES [dbo].[CN_NodeTypes] ([NodeTypeID])
GO

ALTER TABLE [dbo].[QA_CandidateRelations] CHECK CONSTRAINT [FK_QA_CandidateRelations_CN_NodeTypes]
GO

ALTER TABLE [dbo].[QA_CandidateRelations]  WITH CHECK ADD  CONSTRAINT [FK_QA_CandidateRelations_QA_WorkFlows] FOREIGN KEY([WorkFlowID])
REFERENCES [dbo].[QA_WorkFlows] ([WorkFlowID])
GO

ALTER TABLE [dbo].[QA_CandidateRelations] CHECK CONSTRAINT [FK_QA_CandidateRelations_QA_WorkFlows]
GO





ALTER TABLE [dbo].[TMP_KW_KnowledgeTypes]
ADD [ConvertEvaluatorsToExperts] bit NULL
GO


UPDATE [dbo].[TMP_KW_KnowledgeTypes]
SET ConvertEvaluatorsToExperts = 0
GO


DROP TABLE [dbo].[KWF_Paraphs]
GO

DROP TABLE [dbo].[KWF_Evaluators]
GO

DROP TABLE [dbo].[KWF_Experts]
GO

DROP TABLE [dbo].[KWF_Managers]
GO

DROP TABLE [dbo].[KW_TripForms]
GO

DROP TABLE [dbo].[KW_FeedBacks]
GO

DROP TABLE [dbo].[KW_ExperienceHolders]
GO

DROP TABLE [dbo].[KW_KnowledgeCards]
GO

DROP TABLE [dbo].[KW_KnowledgeManagers]
GO

DROP TABLE [dbo].[KW_KnowledgeAssets]
GO

DROP TABLE [dbo].[KW_RelatedNodes]
GO

DROP TABLE [dbo].[KW_RefrenceUsers]
GO

DROP TABLE [dbo].[KW_NodeRelatedTrees]
GO

DROP TABLE [dbo].[KW_UsersConfidentialityLevels]
GO

DROP TABLE [dbo].[KW_CreatorUsers]
GO

DROP TABLE [dbo].[KW_Companies]
GO

DROP TABLE [dbo].[KW_LearningMethods]
GO

DROP TABLE [dbo].[KW_Knowledges]
GO

DROP TABLE [dbo].[KW_SkillLevels]
GO

DROP TABLE [dbo].[KW_ConfidentialityLevels]
GO

DROP TABLE [dbo].[KWF_Statuses]
GO

DROP TABLE [dbo].[KW_KnowledgeTypes]
GO

DROP TABLE [dbo].[ProfileEducation]
GO

DROP TABLE [dbo].[ProfileInstitute]
GO

DROP TABLE [dbo].[ProfileJobs]
GO

DROP TABLE [dbo].[ProfileScientific]
GO


EXEC sp_rename 'TMP_KW_AnswerOptions', 'KW_AnswerOptions'
GO

EXEC sp_rename 'TMP_KW_CandidateRelations', 'KW_CandidateRelations'
GO

EXEC sp_rename 'TMP_KW_FeedBacks', 'KW_FeedBacks'
GO

EXEC sp_rename 'TMP_KW_History', 'KW_History'
GO

EXEC sp_rename 'TMP_KW_KnowledgeTypes', 'KW_KnowledgeTypes'
GO

EXEC sp_rename 'TMP_KW_NecessaryItems', 'KW_NecessaryItems'
GO

EXEC sp_rename 'TMP_KW_QuestionAnswers', 'KW_QuestionAnswers'
GO

EXEC sp_rename 'TMP_KW_Questions', 'KW_Questions'
GO

EXEC sp_rename 'TMP_KW_TempKnowledgeTypeIDs', 'KW_TempKnowledgeTypeIDs'
GO

EXEC sp_rename 'TMP_KW_TypeQuestions', 'KW_TypeQuestions'
GO





ALTER TABLE [dbo].[KW_AnswerOptions]  
DROP CONSTRAINT [FK_TMP_KW_AnswerOptions_aspnet_Applications]
GO

ALTER TABLE [dbo].[KW_AnswerOptions] 
DROP CONSTRAINT [FK_TMP_KW_AnswerOptions_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[KW_AnswerOptions] 
DROP CONSTRAINT [FK_TMP_KW_AnswerOptions_aspnet_Users_Modifier]
GO

ALTER TABLE [dbo].[KW_AnswerOptions] 
DROP CONSTRAINT [FK_TMP_KW_AnswerOptions_TMP_KW_TypeQuestions]
GO

ALTER TABLE [dbo].[KW_CandidateRelations] 
DROP CONSTRAINT [FK_TMP_KW_CandidateRelations_aspnet_Applications]
GO

ALTER TABLE [dbo].[KW_CandidateRelations] 
DROP CONSTRAINT [FK_TMP_KW_CandidateRelations_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[KW_CandidateRelations] 
DROP CONSTRAINT [FK_TMP_KW_CandidateRelations_aspnet_Users_Modifier]
GO

ALTER TABLE [dbo].[KW_CandidateRelations] 
DROP CONSTRAINT [FK_TMP_KW_CandidateRelations_CN_Nodes]
GO

ALTER TABLE [dbo].[KW_CandidateRelations] 
DROP CONSTRAINT [FK_TMP_KW_CandidateRelations_CN_NodeTypes]
GO

ALTER TABLE [dbo].[KW_CandidateRelations] 
DROP CONSTRAINT [FK_TMP_KW_CandidateRelations_TMP_KW_KnowledgeTypes]
GO

ALTER TABLE [dbo].[KW_FeedBacks] 
DROP CONSTRAINT [FK_TMP_KW_FeedBacks_aspnet_Applications]
GO

ALTER TABLE [dbo].[KW_FeedBacks] 
DROP CONSTRAINT [FK_TMP_KW_FeedBacks_aspnet_Users]
GO

ALTER TABLE [dbo].[KW_FeedBacks] 
DROP CONSTRAINT [FK_TMP_KW_FeedBacks_CN_Nodes]
GO

ALTER TABLE [dbo].[KW_History] 
DROP CONSTRAINT [FK_TMP_KW_History_aspnet_Applications]
GO

ALTER TABLE [dbo].[KW_History] 
DROP CONSTRAINT [FK_TMP_KW_History_aspnet_Users]
GO

ALTER TABLE [dbo].[KW_History] 
DROP CONSTRAINT [FK_TMP_KW_History_CN_Nodes]
GO

ALTER TABLE [dbo].[KW_KnowledgeTypes] 
DROP CONSTRAINT [FK_TMP_KW_KnowledgeTypes_aspnet_Applications]
GO

ALTER TABLE [dbo].[KW_KnowledgeTypes] 
DROP CONSTRAINT [FK_TMP_KW_KnowledgeTypes_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[KW_KnowledgeTypes] 
DROP CONSTRAINT [FK_TMP_KW_KnowledgeTypes_aspnet_Users_Modifier]
GO

ALTER TABLE [dbo].[KW_KnowledgeTypes] 
DROP CONSTRAINT [FK_TMP_KW_KnowledgeTypes_CN_NodeTypes]
GO

ALTER TABLE [dbo].[KW_NecessaryItems] 
DROP CONSTRAINT [FK_TMP_KW_NecessaryItems_aspnet_Applications]
GO

ALTER TABLE [dbo].[KW_NecessaryItems] 
DROP CONSTRAINT [FK_TMP_KW_NecessaryItems_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[KW_NecessaryItems] 
DROP CONSTRAINT [FK_TMP_KW_NecessaryItems_aspnet_Users_Modifier]
GO

ALTER TABLE [dbo].[KW_QuestionAnswers] 
DROP CONSTRAINT [FK_TMP_KW_QuestionAnswers_aspnet_Applications]
GO

ALTER TABLE [dbo].[KW_QuestionAnswers] 
DROP CONSTRAINT [FK_TMP_KW_QuestionAnswers_aspnet_Users]
GO

ALTER TABLE [dbo].[KW_QuestionAnswers] 
DROP CONSTRAINT [FK_TMP_KW_QuestionAnswers_CN_Nodes]
GO

ALTER TABLE [dbo].[KW_QuestionAnswers] 
DROP CONSTRAINT [FK_TMP_KW_QuestionAnswers_TMP_KW_Questions]
GO

ALTER TABLE [dbo].[KW_Questions] 
DROP CONSTRAINT [FK_TMP_KW_Questions_aspnet_Applications]
GO

ALTER TABLE [dbo].[KW_Questions] 
DROP CONSTRAINT [FK_TMP_KW_Questions_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[KW_Questions] 
DROP CONSTRAINT [FK_TMP_KW_Questions_aspnet_Users_Modifier]
GO

ALTER TABLE [dbo].[KW_TempKnowledgeTypeIDs] 
DROP CONSTRAINT [FK_TMP_KW_TempKnowledgeTypeIDs_aspnet_Applications]
GO

ALTER TABLE [dbo].[KW_TypeQuestions] 
DROP CONSTRAINT [FK_TMP_KW_TypeQuestions_aspnet_Applications]
GO

ALTER TABLE [dbo].[KW_TypeQuestions] 
DROP CONSTRAINT [FK_TMP_KW_TypeQuestions_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[KW_TypeQuestions] 
DROP CONSTRAINT [FK_TMP_KW_TypeQuestions_aspnet_Users_Modifier]
GO

ALTER TABLE [dbo].[KW_TypeQuestions] 
DROP CONSTRAINT [FK_TMP_KW_TypeQuestions_CN_Nodes]
GO

ALTER TABLE [dbo].[KW_TypeQuestions] 
DROP CONSTRAINT [FK_TMP_KW_TypeQuestions_TMP_KW_KnowledgeTypes]
GO

ALTER TABLE [dbo].[KW_TypeQuestions] 
DROP CONSTRAINT [FK_TMP_KW_TypeQuestions_TMP_KW_Questions]
GO







ALTER TABLE [dbo].[KW_AnswerOptions] 
DROP CONSTRAINT [PK_TMP_KW_AnswerOptions]
GO

ALTER TABLE [dbo].[KW_CandidateRelations] 
DROP CONSTRAINT [PK_TMP_KW_CandidateRelations]
GO

ALTER TABLE [dbo].[KW_FeedBacks] 
DROP CONSTRAINT [PK_TMP_KW_FeedBacks]
GO

ALTER TABLE [dbo].[KW_History] 
DROP CONSTRAINT [PK_TMP_KW_History]
GO

ALTER TABLE [dbo].[KW_KnowledgeTypes] 
DROP CONSTRAINT [PK_TMP_KW_KnowledgeTypes]
GO

ALTER TABLE [dbo].[KW_NecessaryItems] 
DROP CONSTRAINT [PK_TMP_KW_NecessaryItems]
GO

ALTER TABLE [dbo].[KW_QuestionAnswers] 
DROP CONSTRAINT [PK_TMP_KW_QuestionAnswers]
GO

ALTER TABLE [dbo].[KW_TempKnowledgeTypeIDs] 
DROP CONSTRAINT [PK_TMP_KW_TempKnowledgeTypeIDs]
GO

ALTER TABLE [dbo].[KW_TypeQuestions] 
DROP CONSTRAINT [PK_TMP_KW_TypeQuestions]
GO






ALTER TABLE [dbo].[KW_AnswerOptions] ADD  CONSTRAINT [PK_KW_AnswerOptions] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

ALTER TABLE [dbo].[KW_CandidateRelations] ADD  CONSTRAINT [PK_KW_CandidateRelations] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

ALTER TABLE [dbo].[KW_FeedBacks] ADD  CONSTRAINT [PK_KW_FeedBacks] PRIMARY KEY CLUSTERED 
(
	[FeedBackID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

ALTER TABLE [dbo].[KW_History] ADD  CONSTRAINT [PK_KW_History] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

ALTER TABLE [dbo].[KW_KnowledgeTypes] ADD  CONSTRAINT [PK_KW_KnowledgeTypes] PRIMARY KEY CLUSTERED 
(
	[KnowledgeTypeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

ALTER TABLE [dbo].[KW_NecessaryItems] ADD  CONSTRAINT [PK_KW_NecessaryItems] PRIMARY KEY CLUSTERED 
(
	[NodeTypeID] ASC,
	[ItemName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

ALTER TABLE [dbo].[KW_QuestionAnswers] ADD  CONSTRAINT [PK_KW_QuestionAnswers] PRIMARY KEY CLUSTERED 
(
	[KnowledgeID] ASC,
	[UserID] ASC,
	[QuestionID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

ALTER TABLE [dbo].[KW_TempKnowledgeTypeIDs] ADD  CONSTRAINT [PK_KW_TempKnowledgeTypeIDs] PRIMARY KEY CLUSTERED 
(
	[IntID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

ALTER TABLE [dbo].[KW_TypeQuestions] ADD  CONSTRAINT [PK_KW_TypeQuestions] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO




ALTER TABLE [dbo].[KW_AnswerOptions]  WITH CHECK ADD  CONSTRAINT [FK_KW_AnswerOptions_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[KW_AnswerOptions] CHECK CONSTRAINT [FK_KW_AnswerOptions_aspnet_Applications]
GO

ALTER TABLE [dbo].[KW_AnswerOptions]  WITH CHECK ADD  CONSTRAINT [FK_KW_AnswerOptions_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[KW_AnswerOptions] CHECK CONSTRAINT [FK_KW_AnswerOptions_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[KW_AnswerOptions]  WITH CHECK ADD  CONSTRAINT [FK_KW_AnswerOptions_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[KW_AnswerOptions] CHECK CONSTRAINT [FK_KW_AnswerOptions_aspnet_Users_Modifier]
GO

ALTER TABLE [dbo].[KW_AnswerOptions]  WITH CHECK ADD  CONSTRAINT [FK_KW_AnswerOptions_KW_TypeQuestions] FOREIGN KEY([TypeQuestionID])
REFERENCES [dbo].[KW_TypeQuestions] ([ID])
GO

ALTER TABLE [dbo].[KW_AnswerOptions] CHECK CONSTRAINT [FK_KW_AnswerOptions_KW_TypeQuestions]
GO

ALTER TABLE [dbo].[KW_CandidateRelations]  WITH CHECK ADD  CONSTRAINT [FK_KW_CandidateRelations_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[KW_CandidateRelations] CHECK CONSTRAINT [FK_KW_CandidateRelations_aspnet_Applications]
GO

ALTER TABLE [dbo].[KW_CandidateRelations]  WITH CHECK ADD  CONSTRAINT [FK_KW_CandidateRelations_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[KW_CandidateRelations] CHECK CONSTRAINT [FK_KW_CandidateRelations_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[KW_CandidateRelations]  WITH CHECK ADD  CONSTRAINT [FK_KW_CandidateRelations_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[KW_CandidateRelations] CHECK CONSTRAINT [FK_KW_CandidateRelations_aspnet_Users_Modifier]
GO

ALTER TABLE [dbo].[KW_CandidateRelations]  WITH CHECK ADD  CONSTRAINT [FK_KW_CandidateRelations_CN_Nodes] FOREIGN KEY([NodeID])
REFERENCES [dbo].[CN_Nodes] ([NodeID])
GO

ALTER TABLE [dbo].[KW_CandidateRelations] CHECK CONSTRAINT [FK_KW_CandidateRelations_CN_Nodes]
GO

ALTER TABLE [dbo].[KW_CandidateRelations]  WITH CHECK ADD  CONSTRAINT [FK_KW_CandidateRelations_CN_NodeTypes] FOREIGN KEY([NodeTypeID])
REFERENCES [dbo].[CN_NodeTypes] ([NodeTypeID])
GO

ALTER TABLE [dbo].[KW_CandidateRelations] CHECK CONSTRAINT [FK_KW_CandidateRelations_CN_NodeTypes]
GO

ALTER TABLE [dbo].[KW_CandidateRelations]  WITH CHECK ADD  CONSTRAINT [FK_KW_CandidateRelations_KW_KnowledgeTypes] FOREIGN KEY([KnowledgeTypeID])
REFERENCES [dbo].[KW_KnowledgeTypes] ([KnowledgeTypeID])
GO

ALTER TABLE [dbo].[KW_CandidateRelations] CHECK CONSTRAINT [FK_KW_CandidateRelations_KW_KnowledgeTypes]
GO

ALTER TABLE [dbo].[KW_FeedBacks]  WITH CHECK ADD  CONSTRAINT [FK_KW_FeedBacks_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[KW_FeedBacks] CHECK CONSTRAINT [FK_KW_FeedBacks_aspnet_Applications]
GO

ALTER TABLE [dbo].[KW_FeedBacks]  WITH CHECK ADD  CONSTRAINT [FK_KW_FeedBacks_aspnet_Users] FOREIGN KEY([UserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[KW_FeedBacks] CHECK CONSTRAINT [FK_KW_FeedBacks_aspnet_Users]
GO

ALTER TABLE [dbo].[KW_FeedBacks]  WITH CHECK ADD  CONSTRAINT [FK_KW_FeedBacks_CN_Nodes] FOREIGN KEY([KnowledgeID])
REFERENCES [dbo].[CN_Nodes] ([NodeID])
GO

ALTER TABLE [dbo].[KW_FeedBacks] CHECK CONSTRAINT [FK_KW_FeedBacks_CN_Nodes]
GO

ALTER TABLE [dbo].[KW_History]  WITH CHECK ADD  CONSTRAINT [FK_KW_History_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[KW_History] CHECK CONSTRAINT [FK_KW_History_aspnet_Applications]
GO

ALTER TABLE [dbo].[KW_History]  WITH CHECK ADD  CONSTRAINT [FK_KW_History_aspnet_Users] FOREIGN KEY([ActorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[KW_History] CHECK CONSTRAINT [FK_KW_History_aspnet_Users]
GO

ALTER TABLE [dbo].[KW_History]  WITH CHECK ADD  CONSTRAINT [FK_KW_History_CN_Nodes] FOREIGN KEY([KnowledgeID])
REFERENCES [dbo].[CN_Nodes] ([NodeID])
GO

ALTER TABLE [dbo].[KW_History] CHECK CONSTRAINT [FK_KW_History_CN_Nodes]
GO

ALTER TABLE [dbo].[KW_KnowledgeTypes]  WITH CHECK ADD  CONSTRAINT [FK_KW_KnowledgeTypes_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[KW_KnowledgeTypes] CHECK CONSTRAINT [FK_KW_KnowledgeTypes_aspnet_Applications]
GO

ALTER TABLE [dbo].[KW_KnowledgeTypes]  WITH CHECK ADD  CONSTRAINT [FK_KW_KnowledgeTypes_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[KW_KnowledgeTypes] CHECK CONSTRAINT [FK_KW_KnowledgeTypes_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[KW_KnowledgeTypes]  WITH CHECK ADD  CONSTRAINT [FK_KW_KnowledgeTypes_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[KW_KnowledgeTypes] CHECK CONSTRAINT [FK_KW_KnowledgeTypes_aspnet_Users_Modifier]
GO

ALTER TABLE [dbo].[KW_KnowledgeTypes]  WITH CHECK ADD  CONSTRAINT [FK_KW_KnowledgeTypes_CN_NodeTypes] FOREIGN KEY([KnowledgeTypeID])
REFERENCES [dbo].[CN_NodeTypes] ([NodeTypeID])
GO

ALTER TABLE [dbo].[KW_KnowledgeTypes] CHECK CONSTRAINT [FK_KW_KnowledgeTypes_CN_NodeTypes]
GO

ALTER TABLE [dbo].[KW_NecessaryItems]  WITH CHECK ADD  CONSTRAINT [FK_KW_NecessaryItems_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[KW_NecessaryItems] CHECK CONSTRAINT [FK_KW_NecessaryItems_aspnet_Applications]
GO

ALTER TABLE [dbo].[KW_NecessaryItems]  WITH CHECK ADD  CONSTRAINT [FK_KW_NecessaryItems_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[KW_NecessaryItems] CHECK CONSTRAINT [FK_KW_NecessaryItems_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[KW_NecessaryItems]  WITH CHECK ADD  CONSTRAINT [FK_KW_NecessaryItems_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[KW_NecessaryItems] CHECK CONSTRAINT [FK_KW_NecessaryItems_aspnet_Users_Modifier]
GO

ALTER TABLE [dbo].[KW_QuestionAnswers]  WITH CHECK ADD  CONSTRAINT [FK_KW_QuestionAnswers_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[KW_QuestionAnswers] CHECK CONSTRAINT [FK_KW_QuestionAnswers_aspnet_Applications]
GO

ALTER TABLE [dbo].[KW_QuestionAnswers]  WITH CHECK ADD  CONSTRAINT [FK_KW_QuestionAnswers_aspnet_Users] FOREIGN KEY([UserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[KW_QuestionAnswers] CHECK CONSTRAINT [FK_KW_QuestionAnswers_aspnet_Users]
GO

ALTER TABLE [dbo].[KW_QuestionAnswers]  WITH CHECK ADD  CONSTRAINT [FK_KW_QuestionAnswers_CN_Nodes] FOREIGN KEY([KnowledgeID])
REFERENCES [dbo].[CN_Nodes] ([NodeID])
GO

ALTER TABLE [dbo].[KW_QuestionAnswers] CHECK CONSTRAINT [FK_KW_QuestionAnswers_CN_Nodes]
GO

ALTER TABLE [dbo].[KW_QuestionAnswers]  WITH CHECK ADD  CONSTRAINT [FK_KW_QuestionAnswers_KW_Questions] FOREIGN KEY([QuestionID])
REFERENCES [dbo].[KW_Questions] ([QuestionID])
GO

ALTER TABLE [dbo].[KW_QuestionAnswers] CHECK CONSTRAINT [FK_KW_QuestionAnswers_KW_Questions]
GO

ALTER TABLE [dbo].[KW_Questions]  WITH CHECK ADD  CONSTRAINT [FK_KW_Questions_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[KW_Questions] CHECK CONSTRAINT [FK_KW_Questions_aspnet_Applications]
GO

ALTER TABLE [dbo].[KW_Questions]  WITH CHECK ADD  CONSTRAINT [FK_KW_Questions_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[KW_Questions] CHECK CONSTRAINT [FK_KW_Questions_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[KW_Questions]  WITH CHECK ADD  CONSTRAINT [FK_KW_Questions_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[KW_Questions] CHECK CONSTRAINT [FK_KW_Questions_aspnet_Users_Modifier]
GO

ALTER TABLE [dbo].[KW_TempKnowledgeTypeIDs]  WITH CHECK ADD  CONSTRAINT [FK_KW_TempKnowledgeTypeIDs_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[KW_TempKnowledgeTypeIDs] CHECK CONSTRAINT [FK_KW_TempKnowledgeTypeIDs_aspnet_Applications]
GO

ALTER TABLE [dbo].[KW_TypeQuestions]  WITH CHECK ADD  CONSTRAINT [FK_KW_TypeQuestions_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[KW_TypeQuestions] CHECK CONSTRAINT [FK_KW_TypeQuestions_aspnet_Applications]
GO

ALTER TABLE [dbo].[KW_TypeQuestions]  WITH CHECK ADD  CONSTRAINT [FK_KW_TypeQuestions_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[KW_TypeQuestions] CHECK CONSTRAINT [FK_KW_TypeQuestions_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[KW_TypeQuestions]  WITH CHECK ADD  CONSTRAINT [FK_KW_TypeQuestions_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[KW_TypeQuestions] CHECK CONSTRAINT [FK_KW_TypeQuestions_aspnet_Users_Modifier]
GO

ALTER TABLE [dbo].[KW_TypeQuestions]  WITH CHECK ADD  CONSTRAINT [FK_KW_TypeQuestions_CN_Nodes] FOREIGN KEY([NodeID])
REFERENCES [dbo].[CN_Nodes] ([NodeID])
GO

ALTER TABLE [dbo].[KW_TypeQuestions] CHECK CONSTRAINT [FK_KW_TypeQuestions_CN_Nodes]
GO

ALTER TABLE [dbo].[KW_TypeQuestions]  WITH CHECK ADD  CONSTRAINT [FK_KW_TypeQuestions_KW_KnowledgeTypes] FOREIGN KEY([KnowledgeTypeID])
REFERENCES [dbo].[KW_KnowledgeTypes] ([KnowledgeTypeID])
GO

ALTER TABLE [dbo].[KW_TypeQuestions] CHECK CONSTRAINT [FK_KW_TypeQuestions_KW_KnowledgeTypes]
GO

ALTER TABLE [dbo].[KW_TypeQuestions]  WITH CHECK ADD  CONSTRAINT [FK_KW_TypeQuestions_KW_Questions] FOREIGN KEY([QuestionID])
REFERENCES [dbo].[KW_Questions] ([QuestionID])
GO

ALTER TABLE [dbo].[KW_TypeQuestions] CHECK CONSTRAINT [FK_KW_TypeQuestions_KW_Questions]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



UPDATE [dbo].[AppSetting]
	SET [Version] = 'v28.2.14.11' -- 13960202
GO

