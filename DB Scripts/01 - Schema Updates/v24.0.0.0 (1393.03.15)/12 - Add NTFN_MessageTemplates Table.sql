USE [EKM_App]
GO

/****** Object:  Table [dbo].[WF_StateConnectionAudience]    Script Date: 06/10/2013 09:30:24 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO


CREATE TABLE [dbo].[NTFN_MessageTemplates](
	[TemplateID] [uniqueidentifier] NOT NULL,
	[OwnerID] [uniqueidentifier] NOT NULL,
	[BodyText] [nvarchar](max) NOT NULL,
	[AudienceType] [varchar](20) NULL,
	[AudienceRefOwnerID] [uniqueidentifier] NULL,
	[AudienceNodeID] [uniqueidentifier] NULL,
	[AudienceNodeAdmin] [bit] NOT NULL,
	[CreatorUserID] [uniqueidentifier] NULL,
	[CreationDate] [datetime] NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL,
 CONSTRAINT [PK_NTFN_MessageTemplates] PRIMARY KEY CLUSTERED 
(
	[TemplateID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


ALTER TABLE [dbo].[NTFN_MessageTemplates]  WITH CHECK ADD  CONSTRAINT [FK_NTFN_MessageTemplates_CN_Nodes] FOREIGN KEY([AudienceNodeID])
REFERENCES [dbo].[CN_Nodes] ([NodeID])
GO

ALTER TABLE [dbo].[NTFN_MessageTemplates] CHECK CONSTRAINT [FK_NTFN_MessageTemplates_CN_Nodes]
GO

ALTER TABLE [dbo].[NTFN_MessageTemplates]  WITH CHECK ADD  CONSTRAINT [FK_NTFN_MessageTemplates_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[NTFN_MessageTemplates] CHECK CONSTRAINT [FK_NTFN_MessageTemplates_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[NTFN_MessageTemplates]  WITH CHECK ADD  CONSTRAINT [FK_NTFN_MessageTemplates_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[NTFN_MessageTemplates] CHECK CONSTRAINT [FK_NTFN_MessageTemplates_aspnet_Users_Modifier]
GO
