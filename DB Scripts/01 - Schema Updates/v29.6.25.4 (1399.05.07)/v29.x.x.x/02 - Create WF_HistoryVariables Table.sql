USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[WF_HistoryVariables](
	[HistoryID] [uniqueidentifier] NOT NULL,
	[VariableID] [uniqueidentifier] NOT NULL,
	[TextValue] [uniqueidentifier] NOT NULL,
	[NumberValue] [uniqueidentifier] NOT NULL,
	[ApplicationID] [uniqueidentifier] NULL,
 CONSTRAINT [PK_WF_HistoryVariables] PRIMARY KEY CLUSTERED 
(
	[HistoryID] ASC,
	[VariableID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[WF_HistoryVariables]  WITH CHECK ADD  CONSTRAINT [FK_WF_HistoryVariables_WF_History] FOREIGN KEY([HistoryID])
REFERENCES [dbo].[WF_History] ([HistoryID])
GO

ALTER TABLE [dbo].[WF_HistoryVariables] CHECK CONSTRAINT [FK_WF_HistoryVariables_WF_History]
GO

ALTER TABLE [dbo].[WF_HistoryVariables]  WITH CHECK ADD  CONSTRAINT [FK_WF_HistoryVariables_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[WF_HistoryVariables] CHECK CONSTRAINT [FK_WF_HistoryVariables_aspnet_Applications]
GO

ALTER TABLE [dbo].[WF_HistoryVariables]  WITH CHECK ADD  CONSTRAINT [FK_WF_HistoryVariables_WF_Variables] FOREIGN KEY([VariableID])
REFERENCES [dbo].[WF_Variables] ([ID])
GO

ALTER TABLE [dbo].[WF_HistoryVariables] CHECK CONSTRAINT [FK_WF_HistoryVariables_WF_Variables]
GO
