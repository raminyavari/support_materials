USE [EKM_App]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.3' BEGIN
	ALTER TABLE [dbo].[WF_HistoryVariables]
	DROP COLUMN [TextValue]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.3' BEGIN
	ALTER TABLE [dbo].[WF_HistoryVariables]
	DROP COLUMN [NumberValue]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.3' BEGIN
	ALTER TABLE [dbo].[WF_HistoryVariables]
	ADD [TextValue] [NVARCHAR](2000)
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.3' BEGIN
	ALTER TABLE [dbo].[WF_HistoryVariables]
	ADD [NumberValue] [FLOAT]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.3' BEGIN
	UPDATE [dbo].[AppSetting]
	SET [Version] = 'v29.10.4.4' -- 14010212
END
GO
