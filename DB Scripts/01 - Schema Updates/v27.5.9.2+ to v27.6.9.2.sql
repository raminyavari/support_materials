USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



UPDATE [dbo].[AppSetting]
	SET [Version] = 'v27.6.4.5' -- 13950631
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



ALTER TABLE [dbo].[CN_NodeTypes]
ADD [SequenceNumber] int NULL
GO

ALTER TABLE [dbo].[CN_Nodes]
ADD [SequenceNumber] int NULL
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



UPDATE [dbo].[AppSetting]
	SET [Version] = 'v27.6.9.2' -- 13950718
GO

