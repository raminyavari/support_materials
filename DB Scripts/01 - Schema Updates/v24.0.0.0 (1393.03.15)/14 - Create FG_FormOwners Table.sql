USE [EKM_App]
GO


CREATE TABLE [dbo].[FG_FormOwners](
	[OwnerID] [uniqueidentifier] NOT NULL,
	[FormID] [uniqueidentifier] NOT NULL,
	[CreatorUserID] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL
 CONSTRAINT [PK_FG_FormOwners] PRIMARY KEY CLUSTERED 
(
	[OwnerID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


ALTER TABLE [dbo].[FG_FormOwners]  WITH CHECK ADD  CONSTRAINT [FK_FG_FormOwners_FG_ExtendedForms] FOREIGN KEY([FormID])
REFERENCES [dbo].[FG_ExtendedForms] ([FormID])
GO

ALTER TABLE [dbo].[FG_FormOwners] CHECK CONSTRAINT [FK_FG_FormOwners_FG_ExtendedForms]
GO

ALTER TABLE [dbo].[FG_FormOwners]  WITH CHECK ADD  CONSTRAINT [FK_FG_FormOwners_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[FG_FormOwners] CHECK CONSTRAINT [FK_FG_FormOwners_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[FG_FormOwners]  WITH CHECK ADD  CONSTRAINT [FK_FG_FormOwners_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[FG_FormOwners] CHECK CONSTRAINT [FK_FG_FormOwners_aspnet_Users_Modifier]
GO