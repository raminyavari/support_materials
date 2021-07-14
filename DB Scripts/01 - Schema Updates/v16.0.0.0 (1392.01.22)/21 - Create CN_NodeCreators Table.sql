USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CN_NodeCreators](
	[NodeID] [uniqueidentifier] NOT NULL,
	[UserID] [uniqueidentifier] NOT NULL,
	[CollaborationShare] [float] NULL,
	[Status] [varchar](20) NULL,
	[CreatorUserID] [uniqueidentifier] NULL,
	[CreationDate] [datetime] NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL,
 CONSTRAINT [PK_CN_NodeCreators] PRIMARY KEY CLUSTERED 
(
	[NodeID] ASC,
	[UserID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[CN_NodeCreators]  WITH CHECK ADD  CONSTRAINT [FK_CN_NodeCreators_CN_Nodes] FOREIGN KEY([NodeID])
REFERENCES [dbo].[CN_Nodes] ([NodeID])
GO

ALTER TABLE [dbo].[CN_NodeCreators] CHECK CONSTRAINT [FK_CN_NodeCreators_CN_Nodes]
GO

ALTER TABLE [dbo].[CN_NodeCreators]  WITH CHECK ADD  CONSTRAINT [FK_CN_NodeCreators_aspnet_Users] FOREIGN KEY([UserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[CN_NodeCreators] CHECK CONSTRAINT [FK_CN_NodeCreators_aspnet_Users]
GO

ALTER TABLE [dbo].[CN_NodeCreators]  WITH CHECK ADD  CONSTRAINT [FK_CN_NodeCreators_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[CN_NodeCreators] CHECK CONSTRAINT [FK_CN_NodeCreators_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[CN_NodeCreators]  WITH CHECK ADD  CONSTRAINT [FK_CN_NodeCreators_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[CN_NodeCreators] CHECK CONSTRAINT [FK_CN_NodeCreators_aspnet_Users_Modifier]
GO