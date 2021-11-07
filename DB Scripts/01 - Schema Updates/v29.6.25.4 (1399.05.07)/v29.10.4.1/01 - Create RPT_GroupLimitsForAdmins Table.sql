USE [EKM_App]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[RPT_GroupLimitsForAdmins](
	[NodeTypeID] [uniqueidentifier] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL,
	[ApplicationID] [uniqueidentifier] NULL
 CONSTRAINT [PK_RPT_GroupLimitsForAdmins] PRIMARY KEY CLUSTERED 
(
	[NodeTypeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[RPT_GroupLimitsForAdmins]  WITH CHECK ADD  CONSTRAINT [FK_RPT_GroupLimitsForAdmins_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[RPT_GroupLimitsForAdmins] CHECK CONSTRAINT [FK_RPT_GroupLimitsForAdmins_aspnet_Applications]
GO

ALTER TABLE [dbo].[RPT_GroupLimitsForAdmins]  WITH CHECK ADD  CONSTRAINT [FK_RPT_GroupLimitsForAdmins_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[RPT_GroupLimitsForAdmins] CHECK CONSTRAINT [FK_RPT_GroupLimitsForAdmins_aspnet_Users_Modifier]
GO

ALTER TABLE [dbo].[RPT_GroupLimitsForAdmins]  WITH CHECK ADD  CONSTRAINT [FK_RPT_GroupLimitsForAdmins_CN_NodeTypes] FOREIGN KEY([NodeTypeID])
REFERENCES [dbo].[CN_NodeTypes] ([NodeTypeID])
GO

ALTER TABLE [dbo].[RPT_GroupLimitsForAdmins] CHECK CONSTRAINT [FK_RPT_GroupLimitsForAdmins_CN_NodeTypes]
GO


