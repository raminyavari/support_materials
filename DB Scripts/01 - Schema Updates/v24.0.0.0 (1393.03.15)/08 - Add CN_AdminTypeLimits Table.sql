USE [EKM_App]
GO

/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[CN_AdminTypeLimits](
	[NodeTypeID] [uniqueidentifier] NOT NULL,
	[LimitNodeTypeID] [uniqueidentifier] NOT NULL,
	[CreatorUserID] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL
 CONSTRAINT [PK_CN_AdminTypeLimits] PRIMARY KEY CLUSTERED 
(
	[NodeTypeID] ASC,
	[LimitNodeTypeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


ALTER TABLE [dbo].[CN_AdminTypeLimits]  WITH CHECK ADD  CONSTRAINT [FK_CN_AdminTypeLimits_CN_NodeTypes] FOREIGN KEY([NodeTypeID])
REFERENCES [dbo].[CN_NodeTypes] ([NodeTypeID])
GO

ALTER TABLE [dbo].[CN_AdminTypeLimits] CHECK CONSTRAINT [FK_CN_AdminTypeLimits_CN_NodeTypes]
GO

ALTER TABLE [dbo].[CN_AdminTypeLimits]  WITH CHECK ADD  CONSTRAINT [FK_CN_AdminTypeLimits_CN_NodeTypes_Limit] FOREIGN KEY([LimitNodeTypeID])
REFERENCES [dbo].[CN_NodeTypes] ([NodeTypeID])
GO

ALTER TABLE [dbo].[CN_AdminTypeLimits] CHECK CONSTRAINT [FK_CN_AdminTypeLimits_CN_NodeTypes_Limit]
GO

ALTER TABLE [dbo].[CN_AdminTypeLimits]  WITH CHECK ADD  CONSTRAINT [FK_CN_AdminTypeLimits_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[CN_AdminTypeLimits] CHECK CONSTRAINT [FK_CN_AdminTypeLimits_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[CN_AdminTypeLimits]  WITH CHECK ADD  CONSTRAINT [FK_CN_AdminTypeLimits_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[CN_AdminTypeLimits] CHECK CONSTRAINT [FK_CN_AdminTypeLimits_aspnet_Users_Modifier]
GO