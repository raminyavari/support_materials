USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER TABLE [dbo].[FG_ExtendedFormElements]
ADD [IsWorkFlowField] [bit] NULL
GO

ALTER TABLE [dbo].[FG_Changes]
ADD [AutoFilledInWorkFlow] [bit] NULL
GO