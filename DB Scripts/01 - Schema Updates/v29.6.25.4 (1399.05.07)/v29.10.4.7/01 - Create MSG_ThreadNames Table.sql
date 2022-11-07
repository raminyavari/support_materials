USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[MSG_ThreadNames](
	[ThreadID] [uniqueidentifier] NOT NULL,
	[Name] [nvarchar](500) NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NOT NULL,
	[LastModificationDate] [datetime] NOT NULL,
	[ApplicationID] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_MSG_ThreadNames] PRIMARY KEY CLUSTERED 
(
	[ThreadID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[MSG_ThreadNames]  WITH CHECK ADD  CONSTRAINT [FK_MSG_ThreadNames_aspnet_Users] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[MSG_ThreadNames] CHECK CONSTRAINT [FK_MSG_ThreadNames_aspnet_Users]
GO

ALTER TABLE [dbo].[MSG_ThreadNames]  WITH CHECK ADD  CONSTRAINT [FK_MSG_ThreadNames_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[MSG_ThreadNames] CHECK CONSTRAINT [FK_MSG_ThreadNames_aspnet_Applications]
GO
