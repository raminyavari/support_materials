USE [EKM_App]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.8' BEGIN
	ALTER TABLE [dbo].[KW_KnowledgeTypes]
	ADD [EnableKnowledgeForwardingByEvaluators] bit
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.8' BEGIN
	ALTER TABLE [dbo].[CN_Nodes]
	ADD [Locked] bit
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.8' BEGIN
	UPDATE [dbo].[AppSetting]
	SET [Version] = 'v29.12.6.4' -- 14020430
END
GO