USE [EKM_App]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.4' BEGIN
	ALTER TABLE [dbo].[WF_Actions]
	ADD [SaveToFormElementID] [uniqueidentifier] NULL
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.4' BEGIN
	ALTER TABLE [dbo].[WF_Actions]  WITH CHECK ADD  CONSTRAINT [FK_WF_Actions_FG_ExtendedFormElements] FOREIGN KEY([SaveToFormElementID])
	REFERENCES [dbo].[FG_ExtendedFormElements] ([ElementID])
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.4' BEGIN
	ALTER TABLE [dbo].[WF_Actions] CHECK CONSTRAINT [FK_WF_Actions_FG_ExtendedFormElements]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.4' BEGIN
	ALTER TABLE [dbo].[FG_ExtendedFormElements]
	ADD [IsWorkFlowField] [bit] NULL
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.4' BEGIN
	ALTER TABLE [dbo].[FG_Changes]
	ADD [AutoFilledInWorkFlow] [bit] NULL
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.4' BEGIN
	UPDATE [dbo].[AppSetting]
	SET [Version] = 'v29.10.4.5' -- 14010419
END
GO
