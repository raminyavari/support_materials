USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[WF_WorkFlowActionsTemp] (
	[ConnectionID] [uniqueidentifier] NOT NULL,
	[Action] [varchar](255) NOT NULL,
	[SequenceNumber] [int] NULL,
	[CreatorUserID] [uniqueidentifier] NULL,
	[CreationDate] [datetime] NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL,
	[ApplicationID] [uniqueidentifier] NULL
 CONSTRAINT [PK_WF_WorkFlowActionsTemp] PRIMARY KEY CLUSTERED 
(
	[ConnectionID] ASC,
	[Action] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

INSERT INTO [dbo].[WF_WorkFlowActionsTemp] (ApplicationID, ConnectionID, [Action], SequenceNumber, CreatorUserID, 
											CreationDate, LastModifierUserID, LastModificationDate, Deleted)
SELECT	A.ApplicationID, A.ConnectionID, A.[Action], A.SequenceNumber, A.CreatorUserID, 
		A.CreationDate, A.LastModifierUserID, A.LastModificationDate, A.Deleted
FROM [dbo].[WF_WorkFlowActions] AS A
GO

DROP TABLE [dbo].[WF_WorkFlowActions]
GO


CREATE TABLE [dbo].[WF_Actions](
	[ID] [uniqueidentifier] NOT NULL,
	[ConnectionID] [uniqueidentifier] NOT NULL,
	[Action] [varchar](50) NOT NULL,
	[SequenceNumber] [int] NULL,
	[Formula] [nvarchar](max) NULL,
	[VariableType] [varchar](50) NOT NULL,
	[VariableName] [nvarchar](255) NOT NULL,
	[VariableDefaultValue] [nvarchar](255) NULL,
	[CreatorUserID] [uniqueidentifier] NULL,
	[CreationDate] [datetime] NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL,
	[ApplicationID] [uniqueidentifier] NULL,
 CONSTRAINT [PK_WF_Actions] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

INSERT INTO [dbo].[WF_Actions] (ID, ApplicationID, ConnectionID, [Action], SequenceNumber, CreatorUserID, 
											CreationDate, LastModifierUserID, LastModificationDate, Deleted)
SELECT	NEWID(), A.ApplicationID, A.ConnectionID, A.[Action], A.SequenceNumber, A.CreatorUserID, 
		A.CreationDate, A.LastModifierUserID, A.LastModificationDate, A.Deleted
FROM [dbo].[WF_WorkFlowActionsTemp] AS A
GO

DROP TABLE [dbo].[WF_WorkFlowActionsTemp]
GO

ALTER TABLE [dbo].[WF_Actions]  WITH CHECK ADD  CONSTRAINT [FK_WF_Actions_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[WF_Actions] CHECK CONSTRAINT [FK_WF_Actions_aspnet_Applications]
GO

ALTER TABLE [dbo].[WF_Actions]  WITH CHECK ADD  CONSTRAINT [FK_WF_Actions_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[WF_Actions] CHECK CONSTRAINT [FK_WF_Actions_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[WF_Actions]  WITH CHECK ADD  CONSTRAINT [FK_WF_Actions_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[WF_Actions] CHECK CONSTRAINT [FK_WF_Actions_aspnet_Users_Modifier]
GO

ALTER TABLE [dbo].[WF_Actions]  WITH CHECK ADD  CONSTRAINT [FK_WF_Actions_WF_StateConnections] FOREIGN KEY([ConnectionID])
REFERENCES [dbo].[WF_StateConnections] ([ID])
GO

ALTER TABLE [dbo].[WF_Actions] CHECK CONSTRAINT [FK_WF_Actions_WF_StateConnections]
GO


