USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[USR_UserGroupPermissions](
	[GroupID] [uniqueidentifier] NOT NULL,
	[RoleID] [uniqueidentifier] NOT NULL,
	[CreatorUserID] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL,
	[ApplicationID] [uniqueidentifier] NULL
 CONSTRAINT [PK_USR_UserGroupPermissions] PRIMARY KEY CLUSTERED 
(
	[GroupID] ASC,
	[RoleID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[USR_UserGroupPermissions]  WITH CHECK ADD  CONSTRAINT [FK_USR_UserGroupPermissions_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[USR_UserGroupPermissions] CHECK CONSTRAINT [FK_USR_UserGroupPermissions_aspnet_Applications]
GO


ALTER TABLE [dbo].[USR_UserGroupPermissions]  WITH CHECK ADD  CONSTRAINT [FK_USR_UserGroupPermissions_USR_UserGroups] FOREIGN KEY([GroupID])
REFERENCES [dbo].[USR_UserGroups] ([GroupID])
GO

ALTER TABLE [dbo].[USR_UserGroupPermissions] CHECK CONSTRAINT [FK_USR_UserGroupPermissions_USR_UserGroups]
GO


ALTER TABLE [dbo].[USR_UserGroupPermissions]  WITH CHECK ADD  CONSTRAINT [FK_USR_UserGroupPermissions_USR_AccessRoles] FOREIGN KEY([RoleID])
REFERENCES [dbo].[USR_AccessRoles] ([RoleID])
GO

ALTER TABLE [dbo].[USR_UserGroupPermissions] CHECK CONSTRAINT [FK_USR_UserGroupPermissions_USR_AccessRoles]
GO


ALTER TABLE [dbo].[USR_UserGroupPermissions]  WITH CHECK ADD  CONSTRAINT [FK_USR_UserGroupPermissions_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[USR_UserGroupPermissions] CHECK CONSTRAINT [FK_USR_UserGroupPermissions_aspnet_Users_Creator]
GO


ALTER TABLE [dbo].[USR_UserGroupPermissions]  WITH CHECK ADD  CONSTRAINT [FK_USR_UserGroupPermissions_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[USR_UserGroupPermissions] CHECK CONSTRAINT [FK_USR_UserGroupPermissions_aspnet_Users_Modifier]
GO


DECLARE @UID uniqueidentifier = (SELECT TOP(1) UserId FROM [dbo].[aspnet_Users] WHERE LoweredUserName = N'admin')
DECLARE @Now datetime = GETDATE()

INSERT INTO [dbo].[USR_UserGroupPermissions] (
	ApplicationID,
	GroupID,
	RoleID,
	CreatorUserID,
	CreationDate,
	Deleted
)
SELECT DISTINCT
	G.ApplicationID,
	G.UserGroupId,
	G.AccessRoleId,
	@UID,
	ISNULL(G.[Date], @Now),
	0
FROM [dbo].[UserGroupAccessRoles] AS G

GO
