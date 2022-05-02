USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER TABLE [dbo].[WF_HistoryVariables]
DROP COLUMN [TextValue]
GO

ALTER TABLE [dbo].[WF_HistoryVariables]
DROP COLUMN [NumberValue]
GO

ALTER TABLE [dbo].[WF_HistoryVariables]
ADD [TextValue] [NVARCHAR](2000)
GO

ALTER TABLE [dbo].[WF_HistoryVariables]
ADD [NumberValue] [FLOAT]
GO

