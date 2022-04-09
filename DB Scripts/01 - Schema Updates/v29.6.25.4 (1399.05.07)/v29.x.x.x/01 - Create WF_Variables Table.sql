USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[WF_Variables](
	[ID] [uniqueidentifier] NOT NULL,
	[WorkFlowID] [uniqueidentifier] NOT NULL,
	[FromStateID] [uniqueidentifier] NOT NULL,
	[ToStateID] [uniqueidentifier] NOT NULL,
	[Type] [varchar](50) NOT NULL,
	[Name] [nvarchar](255) NOT NULL,
	[Value] [nvarchar](255) NULL,
	[CreatorUserID] [uniqueidentifier] NULL,
	[CreationDate] [datetime] NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL,
	[ApplicationID] [uniqueidentifier] NULL,
 CONSTRAINT [PK_WF_Variables] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UK_WF_Variables] UNIQUE NONCLUSTERED 
(
	[WorkFlowID] ASC,
	[FromStateID] ASC,
	[ToStateID] ASC,
	[Type] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[WF_Variables]  WITH CHECK ADD  CONSTRAINT [FK_WF_Variables_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[WF_Variables] CHECK CONSTRAINT [FK_WF_Variables_aspnet_Applications]
GO

ALTER TABLE [dbo].[WF_Variables]  WITH CHECK ADD  CONSTRAINT [FK_WF_Variables_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[WF_Variables] CHECK CONSTRAINT [FK_WF_Variables_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[WF_Variables]  WITH CHECK ADD  CONSTRAINT [FK_WF_Variables_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[WF_Variables] CHECK CONSTRAINT [FK_WF_Variables_aspnet_Users_Modifier]
GO

ALTER TABLE [dbo].[WF_Variables]  WITH CHECK ADD  CONSTRAINT [FK_WF_Variables_WF_States_From] FOREIGN KEY([FromStateID])
REFERENCES [dbo].[WF_States] ([StateID])
GO

ALTER TABLE [dbo].[WF_Variables] CHECK CONSTRAINT [FK_WF_Variables_WF_States_From]
GO

ALTER TABLE [dbo].[WF_Variables]  WITH CHECK ADD  CONSTRAINT [FK_WF_Variables_WF_States_To] FOREIGN KEY([ToStateID])
REFERENCES [dbo].[WF_States] ([StateID])
GO

ALTER TABLE [dbo].[WF_Variables] CHECK CONSTRAINT [FK_WF_Variables_WF_States_To]
GO

ALTER TABLE [dbo].[WF_Variables]  WITH CHECK ADD  CONSTRAINT [FK_WF_Variables_WF_WorkFlows] FOREIGN KEY([WorkFlowID])
REFERENCES [dbo].[WF_WorkFlows] ([WorkFlowID])
GO

ALTER TABLE [dbo].[WF_Variables] CHECK CONSTRAINT [FK_WF_Variables_WF_WorkFlows]
GO
