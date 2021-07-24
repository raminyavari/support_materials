USE [EKM_App]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER TABLE [dbo].[USR_UserApplications]
ADD [CreationDate] datetime NULL
GO

ALTER TABLE [dbo].[USR_UserApplications]
ADD [Deleted] bit NULL
GO
