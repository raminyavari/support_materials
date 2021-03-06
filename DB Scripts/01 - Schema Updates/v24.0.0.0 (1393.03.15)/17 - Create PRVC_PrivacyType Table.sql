USE [EKM_App]
GO


CREATE TABLE [dbo].[PRVC_PrivacyType](
	[ObjectID] [uniqueidentifier] NOT NULL,
	[PrivacyType] [varchar](20) NOT NULL,
	[CreatorUserID] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL
 CONSTRAINT [PK_PRVC_PrivacyType] PRIMARY KEY CLUSTERED 
(
	[ObjectID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


ALTER TABLE [dbo].[PRVC_PrivacyType]  WITH CHECK ADD  CONSTRAINT [FK_PRVC_PrivacyType_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[PRVC_PrivacyType] CHECK CONSTRAINT [FK_PRVC_PrivacyType_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[PRVC_PrivacyType]  WITH CHECK ADD  CONSTRAINT [FK_PRVC_PrivacyType_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[PRVC_PrivacyType] CHECK CONSTRAINT [FK_PRVC_PrivacyType_aspnet_Users_Modifier]
GO