USE [EKM_App]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.5' BEGIN
	ALTER TABLE [dbo].[WF_WorkFlowStates]
	ADD [PollAudienceType] [varchar](50) NULL
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.5' BEGIN
	ALTER TABLE [dbo].[WF_WorkFlowStates]
	ADD [PollAudienceID] [uniqueidentifier] NULL
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.5' BEGIN
	ALTER TABLE [dbo].[WF_WorkFlowStates]
	ADD [PollAudienceRefStateID] [uniqueidentifier] NULL
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.5' BEGIN
	ALTER TABLE [dbo].[WF_WorkFlowStates]  WITH CHECK ADD  CONSTRAINT [FK_WF_WorkFlowStates_WF_States_Poll_Audience] FOREIGN KEY([PollAudienceRefStateID])
	REFERENCES [dbo].[WF_States] ([StateID])
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.5' BEGIN
	ALTER TABLE [dbo].[WF_WorkFlowStates] CHECK CONSTRAINT [FK_WF_WorkFlowStates_WF_States_Poll_Audience]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.5' BEGIN
	UPDATE [dbo].[AppSetting]
	SET [Version] = 'v29.10.4.6' -- 14010511
END
GO