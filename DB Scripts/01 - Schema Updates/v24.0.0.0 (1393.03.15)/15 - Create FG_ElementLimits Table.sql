USE [EKM_App]
GO


CREATE TABLE [dbo].[FG_ElementLimits](
	[OwnerID] [uniqueidentifier] NOT NULL,
	[ElementID] [uniqueidentifier] NOT NULL,
	[Necessary] [bit] NOT NULL,
	[CreatorUserID] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL
 CONSTRAINT [PK_FG_ElementLimits] PRIMARY KEY CLUSTERED 
(
	[OwnerID] ASC,
	[ElementID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


ALTER TABLE [dbo].[FG_ElementLimits]  WITH CHECK ADD  CONSTRAINT [FK_FG_ElementLimits_FG_FormOwners] FOREIGN KEY([OwnerID])
REFERENCES [dbo].[FG_FormOwners] ([OwnerID])
GO

ALTER TABLE [dbo].[FG_ElementLimits] CHECK CONSTRAINT [FK_FG_ElementLimits_FG_FormOwners]
GO

ALTER TABLE [dbo].[FG_ElementLimits]  WITH CHECK ADD  CONSTRAINT [FK_FG_ElementLimits_FG_ExtendedFormElements] FOREIGN KEY([ElementID])
REFERENCES [dbo].[FG_ExtendedFormElements] ([ElementID])
GO

ALTER TABLE [dbo].[FG_ElementLimits] CHECK CONSTRAINT [FK_FG_ElementLimits_FG_ExtendedFormElements]
GO

ALTER TABLE [dbo].[FG_ElementLimits]  WITH CHECK ADD  CONSTRAINT [FK_FG_ElementLimits_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[FG_ElementLimits] CHECK CONSTRAINT [FK_FG_ElementLimits_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[FG_ElementLimits]  WITH CHECK ADD  CONSTRAINT [FK_FG_ElementLimits_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[FG_ElementLimits] CHECK CONSTRAINT [FK_FG_ElementLimits_aspnet_Users_Modifier]
GO