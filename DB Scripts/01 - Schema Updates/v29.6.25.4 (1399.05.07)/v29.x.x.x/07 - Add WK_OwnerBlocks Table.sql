USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[WK_OwnerBlocks](
	[OwnerID] [uniqueidentifier] NOT NULL,
	[BlockID] [uniqueidentifier] NOT NULL,
	[SequenceNumber] [int] NOT NULL,
	[Depth] [int] NOT NULL,
	[ModifierUserID] [uniqueidentifier] NOT NULL,
	[ModificationDate] [datetime] NOT NULL,
	[ApplicationID] [uniqueidentifier] NOT NULL
 CONSTRAINT [PK_WK_OwnerBlocks] PRIMARY KEY CLUSTERED 
(
	[OwnerID] ASC,
	[BlockID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


ALTER TABLE [dbo].[WK_OwnerBlocks]  WITH CHECK ADD  CONSTRAINT [FK_WK_OwnerBlocks_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[WK_OwnerBlocks] CHECK CONSTRAINT [FK_WK_OwnerBlocks_aspnet_Applications]
GO

ALTER TABLE [dbo].[WK_OwnerBlocks]  WITH CHECK ADD  CONSTRAINT [FK_WK_OwnerBlocks_WK_Blocks] FOREIGN KEY([BlockID])
REFERENCES [dbo].[WK_Blocks] ([BlockID])
GO

ALTER TABLE [dbo].[WK_OwnerBlocks] CHECK CONSTRAINT [FK_WK_OwnerBlocks_WK_Blocks]
GO

ALTER TABLE [dbo].[WK_OwnerBlocks]  WITH CHECK ADD  CONSTRAINT [FK_WK_OwnerBlocks_aspnet_Users] FOREIGN KEY([ModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserID])
GO

ALTER TABLE [dbo].[WK_OwnerBlocks] CHECK CONSTRAINT [FK_WK_OwnerBlocks_aspnet_Users]
GO
