USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[USR_AccessRoles](
	[RoleID] [uniqueidentifier] NOT NULL,
	[Name] [varchar](100) NOT NULL,
	[Title] [nvarchar](2000) NOT NULL,
	[ApplicationID] [uniqueidentifier] NULL
 CONSTRAINT [PK_USR_AccessRoles] PRIMARY KEY CLUSTERED 
(
	[RoleID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[USR_AccessRoles]  WITH CHECK ADD  CONSTRAINT [FK_USR_AccessRoles_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[USR_AccessRoles] CHECK CONSTRAINT [FK_USR_AccessRoles_aspnet_Applications]
GO


INSERT INTO [dbo].[USR_AccessRoles] (
	ApplicationID,
	RoleID,
	Name,
	Title
)
SELECT DISTINCT ApplicationID, ID, [Role], Title
FROM [dbo].[AccessRoles]

GO