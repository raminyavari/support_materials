USE [EKM_App]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[PRVC_AudienceTemp](
	[ObjectID] [uniqueidentifier] NOT NULL,
	[RoleID] [uniqueidentifier] NOT NULL,
	[PermissionType] [nvarchar](50) NOT NULL,
	[Allow] [bit] NOT NULL,
	[ExpirationDate] [datetime] NULL,
	[CreatorUserID] [uniqueidentifier] NULL,
	[CreationDate] [datetime] NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL,
	[ApplicationID] [uniqueidentifier] NULL
) ON [PRIMARY]
GO

INSERT INTO [dbo].[PRVC_AudienceTemp]
SELECT *
FROM [dbo].[PRVC_Audience]
GO

DROP TABLE [dbo].[PRVC_Audience]
GO

CREATE TABLE [dbo].[PRVC_Audience](
	[ObjectID] [uniqueidentifier] NOT NULL,
	[RoleID] [uniqueidentifier] NOT NULL,
	[PermissionType] [nvarchar](50) NOT NULL,
	[Allow] [bit] NOT NULL,
	[ExpirationDate] [datetime] NULL,
	[CreatorUserID] [uniqueidentifier] NULL,
	[CreationDate] [datetime] NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL,
	[ApplicationID] [uniqueidentifier] NOT NULL,
	CONSTRAINT [PK_PRVC_Audience] PRIMARY KEY CLUSTERED 
	(
		[ApplicationID] ASC,
		[ObjectID] ASC,
		[RoleID] ASC,
		[PermissionType] ASC
	)
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[PRVC_Audience]  WITH CHECK ADD  CONSTRAINT [FK_PRVC_Audience_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[PRVC_Audience] CHECK CONSTRAINT [FK_PRVC_Audience_aspnet_Applications]
GO

ALTER TABLE [dbo].[PRVC_Audience]  WITH CHECK ADD  CONSTRAINT [FK_PRVC_Audience_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[PRVC_Audience] CHECK CONSTRAINT [FK_PRVC_Audience_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[PRVC_Audience]  WITH CHECK ADD  CONSTRAINT [FK_PRVC_Audience_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[PRVC_Audience] CHECK CONSTRAINT [FK_PRVC_Audience_aspnet_Users_Modifier]
GO


INSERT INTO [dbo].[PRVC_Audience]
SELECT *
FROM [dbo].[PRVC_AudienceTemp]
GO

DROP TABLE [dbo].[PRVC_AudienceTemp]
GO