USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER TABLE [dbo].[WF_WorkFlowActions]
ADD [Formula] [nvarchar](max) NULL
GO