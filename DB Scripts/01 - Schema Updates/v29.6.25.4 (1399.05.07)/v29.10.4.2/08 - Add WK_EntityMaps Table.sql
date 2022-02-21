USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[WK_EntityMaps](
	[OwnerID] [uniqueidentifier] NOT NULL,
	[EntityMap] [nvarchar](max) NOT NULL,
	[ModifierUserID] [uniqueidentifier] NOT NULL,
	[ModificationDate] [datetime] NOT NULL,
	[ApplicationID] [uniqueidentifier] NOT NULL
 CONSTRAINT [PK_WK_EntityMaps] PRIMARY KEY CLUSTERED 
(
	[OwnerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


ALTER TABLE [dbo].[WK_EntityMaps]  WITH CHECK ADD  CONSTRAINT [FK_WK_EntityMaps_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[WK_EntityMaps] CHECK CONSTRAINT [FK_WK_EntityMaps_aspnet_Applications]
GO

ALTER TABLE [dbo].[WK_EntityMaps]  WITH CHECK ADD  CONSTRAINT [FK_WK_EntityMaps_aspnet_Users] FOREIGN KEY([ModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserID])
GO

ALTER TABLE [dbo].[WK_EntityMaps] CHECK CONSTRAINT [FK_WK_EntityMaps_aspnet_Users]
GO
