USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[USR_UserGroupMembers](
	[GroupID] [uniqueidentifier] NOT NULL,
	[UserID] [uniqueidentifier] NOT NULL,
	[CreatorUserID] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL,
	[ApplicationID] [uniqueidentifier] NULL
 CONSTRAINT [PK_USR_UserGroupMembers] PRIMARY KEY CLUSTERED 
(
	[GroupID] ASC,
	[UserID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[USR_UserGroupMembers]  WITH CHECK ADD  CONSTRAINT [FK_USR_UserGroupMembers_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[USR_UserGroupMembers] CHECK CONSTRAINT [FK_USR_UserGroupMembers_aspnet_Applications]
GO


ALTER TABLE [dbo].[USR_UserGroupMembers]  WITH CHECK ADD  CONSTRAINT [FK_USR_UserGroupMembers_USR_UserGroups] FOREIGN KEY([GroupID])
REFERENCES [dbo].[USR_UserGroups] ([GroupID])
GO

ALTER TABLE [dbo].[USR_UserGroupMembers] CHECK CONSTRAINT [FK_USR_UserGroupMembers_USR_UserGroups]
GO


ALTER TABLE [dbo].[USR_UserGroupMembers]  WITH CHECK ADD  CONSTRAINT [FK_USR_UserGroupMembers_aspnet_Users] FOREIGN KEY([UserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[USR_UserGroupMembers] CHECK CONSTRAINT [FK_USR_UserGroupMembers_aspnet_Users]
GO


ALTER TABLE [dbo].[USR_UserGroupMembers]  WITH CHECK ADD  CONSTRAINT [FK_USR_UserGroupMembers_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[USR_UserGroupMembers] CHECK CONSTRAINT [FK_USR_UserGroupMembers_aspnet_Users_Creator]
GO


ALTER TABLE [dbo].[USR_UserGroupMembers]  WITH CHECK ADD  CONSTRAINT [FK_USR_UserGroupMembers_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[USR_UserGroupMembers] CHECK CONSTRAINT [FK_USR_UserGroupMembers_aspnet_Users_Modifier]
GO


DECLARE @UID uniqueidentifier = (SELECT TOP(1) UserId FROM [dbo].[aspnet_Users] WHERE LoweredUserName = N'admin')
DECLARE @Now datetime = GETDATE()

INSERT INTO [dbo].[USR_UserGroupMembers] (
	ApplicationID,
	GroupID,
	UserID,
	CreatorUserID,
	CreationDate,
	Deleted
)
SELECT DISTINCT
	G.ApplicationID,
	G.UserGroupId,
	G.UserId,
	@UID,
	ISNULL(G.[Date], @Now),
	0
FROM [dbo].[UserGroupUsers] AS G

GO
