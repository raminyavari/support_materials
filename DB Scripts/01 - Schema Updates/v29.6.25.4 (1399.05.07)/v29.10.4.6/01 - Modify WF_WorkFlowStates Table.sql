USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER TABLE [dbo].[WF_WorkFlowStates]
ADD [PollAudienceType] [varchar](50) NULL
GO

ALTER TABLE [dbo].[WF_WorkFlowStates]
ADD [PollAudienceID] [uniqueidentifier] NULL
GO

ALTER TABLE [dbo].[WF_WorkFlowStates]
ADD [PollAudienceRefStateID] [uniqueidentifier] NULL
GO


ALTER TABLE [dbo].[WF_WorkFlowStates]  WITH CHECK ADD  CONSTRAINT [FK_WF_WorkFlowStates_WF_States_Poll_Audience] FOREIGN KEY([PollAudienceRefStateID])
REFERENCES [dbo].[WF_States] ([StateID])
GO

ALTER TABLE [dbo].[WF_WorkFlowStates] CHECK CONSTRAINT [FK_WF_WorkFlowStates_WF_States_Poll_Audience]
GO
