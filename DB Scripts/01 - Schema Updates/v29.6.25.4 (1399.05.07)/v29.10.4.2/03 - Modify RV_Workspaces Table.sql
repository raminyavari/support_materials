USE [EKM_App]
GO

/****** Object:  Table [dbo].[RV_Workspaces]    Script Date: 1/9/2022 10:45:31 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


DROP TABLE IF EXISTS [dbo].[RV_WorkSpaces]
GO


CREATE TABLE [dbo].[RV_Workspaces](
	[WorkspaceID] [uniqueidentifier] NOT NULL,
	[Name] [nvarchar](255) NOT NULL,
	[Description] [nvarchar](2000) NULL,
	[AvatarName] [varchar](50) NULL,
	[UseAvatar] [bit] NULL,
	[CreatorUserID] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL,
 CONSTRAINT [PK_RV_Workspaces] PRIMARY KEY CLUSTERED 
(
	[WorkspaceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[RV_Workspaces]  WITH CHECK ADD  CONSTRAINT [FK_RV_Workspaces_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[RV_Workspaces] CHECK CONSTRAINT [FK_RV_Workspaces_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[RV_Workspaces]  WITH CHECK ADD  CONSTRAINT [FK_RV_Workspaces_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[RV_Workspaces] CHECK CONSTRAINT [FK_RV_Workspaces_aspnet_Users_Modifier]
GO


