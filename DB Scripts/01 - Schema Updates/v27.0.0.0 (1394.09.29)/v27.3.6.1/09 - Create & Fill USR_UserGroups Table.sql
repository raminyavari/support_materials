USE [EKM_App]
GO

/****** Object:  Table [dbo].[UserGroups]    Script Date: 05/16/2016 09:26:25 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[USR_UserGroups](
	[GroupID] [uniqueidentifier] NOT NULL,
	[Title] [nvarchar](256) NOT NULL,
	[Description] [nvarchar](2000) NULL,
	[CreatorUserID] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL,
	[ApplicationID] [uniqueidentifier] NULL
 CONSTRAINT [PK_USR_UserGroups] PRIMARY KEY CLUSTERED 
(
	[GroupID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[USR_UserGroups]  WITH CHECK ADD  CONSTRAINT [FK_USR_UserGroups_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[USR_UserGroups] CHECK CONSTRAINT [FK_USR_UserGroups_aspnet_Applications]
GO


ALTER TABLE [dbo].[USR_UserGroups]  WITH CHECK ADD  CONSTRAINT [FK_USR_UserGroups_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[USR_UserGroups] CHECK CONSTRAINT [FK_USR_UserGroups_aspnet_Users_Creator]
GO


ALTER TABLE [dbo].[USR_UserGroups]  WITH CHECK ADD  CONSTRAINT [FK_USR_UserGroups_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[USR_UserGroups] CHECK CONSTRAINT [FK_USR_UserGroups_aspnet_Users_Modifier]
GO


DECLARE @UID uniqueidentifier = (SELECT TOP(1) UserId FROM [dbo].[aspnet_Users] WHERE LoweredUserName = N'admin')
DECLARE @Now datetime = GETDATE()

INSERT INTO [dbo].[USR_UserGroups] (
	ApplicationID,
	GroupID,
	Title,
	[Description],
	CreatorUserID,
	CreationDate,
	Deleted
)
SELECT	G.ApplicationID,
		G.ID,
		REPLACE(REPLACE(G.Title, N'ي', N'ی'), N'ك', N'ک'),
		REPLACE(REPLACE(G.[Description], N'ي', N'ی'), N'ك', N'ک'),
		ISNULL(G.CreatorUserId, @UID),
		ISNULL(G.CreateDate, @Now),
		0
FROM [dbo].[UserGroups] AS G

GO
