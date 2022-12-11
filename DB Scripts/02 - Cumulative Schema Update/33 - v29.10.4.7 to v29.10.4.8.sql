USE [EKM_App]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.7' BEGIN
	ALTER TABLE [dbo].[USR_Profile]
	ADD [NationalID] nvarchar(20)
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.7' BEGIN
	ALTER TABLE [dbo].[USR_Profile]
	ADD [PersonnelID] nvarchar(20)
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.7' BEGIN
	UPDATE [dbo].[AppSetting]
	SET [Version] = 'v29.10.4.8' -- 14010921
END
GO