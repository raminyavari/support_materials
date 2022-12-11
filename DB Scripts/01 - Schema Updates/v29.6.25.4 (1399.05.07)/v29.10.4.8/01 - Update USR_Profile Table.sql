USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER TABLE [dbo].[USR_Profile]
ADD [NationalID] nvarchar(20)
GO

ALTER TABLE [dbo].[USR_Profile]
ADD [PersonnelID] nvarchar(20)
GO
