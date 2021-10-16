USE [EKM_App]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[WF_WorkFlowStateActions](
	[WorkFlowID] [uniqueidentifier] NOT NULL,
	[StateID] [uniqueidentifier] NOT NULL,
	[Action] [varchar](255) NOT NULL,
	[SequenceNumber] [int] NULL,
	[CreatorUserID] [uniqueidentifier] NULL,
	[CreationDate] [datetime] NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL,
	[ApplicationID] [uniqueidentifier] NULL
 CONSTRAINT [PK_WF_WorkFlowStateActions] PRIMARY KEY CLUSTERED 
(
	[WorkFlowID] ASC,
	[StateID] ASC,
	[Action] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[WF_WorkFlowStateActions]  WITH CHECK ADD  CONSTRAINT [FK_WF_WorkFlowStateActions_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[WF_WorkFlowStateActions] CHECK CONSTRAINT [FK_WF_WorkFlowStateActions_aspnet_Applications]
GO

ALTER TABLE [dbo].[WF_WorkFlowStateActions]  WITH CHECK ADD  CONSTRAINT [FK_WF_WorkFlowStateActions_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[WF_WorkFlowStateActions] CHECK CONSTRAINT [FK_WF_WorkFlowStateActions_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[WF_WorkFlowStateActions]  WITH CHECK ADD  CONSTRAINT [FK_WF_WorkFlowStateActions_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[WF_WorkFlowStateActions] CHECK CONSTRAINT [FK_WF_WorkFlowStateActions_aspnet_Users_Modifier]
GO

ALTER TABLE [dbo].[WF_WorkFlowStateActions]  WITH CHECK ADD  CONSTRAINT [FK_WF_WorkFlowStateActions_WF_States] FOREIGN KEY([StateID])
REFERENCES [dbo].[WF_States] ([StateID])
GO

ALTER TABLE [dbo].[WF_WorkFlowStateActions] CHECK CONSTRAINT [FK_WF_WorkFlowStateActions_WF_States]
GO

ALTER TABLE [dbo].[WF_WorkFlowStateActions]  WITH CHECK ADD  CONSTRAINT [FK_WF_WorkFlowStateActions_WF_WorkFlows_WorkFlow] FOREIGN KEY([WorkFlowID])
REFERENCES [dbo].[WF_WorkFlows] ([WorkFlowID])
GO

ALTER TABLE [dbo].[WF_WorkFlowStateActions] CHECK CONSTRAINT [FK_WF_WorkFlowStateActions_WF_WorkFlows_WorkFlow]
GO


