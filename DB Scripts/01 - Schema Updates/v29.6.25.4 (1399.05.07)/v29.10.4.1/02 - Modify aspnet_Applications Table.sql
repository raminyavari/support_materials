USE [EKM_App]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER TABLE [dbo].[aspnet_Applications]
ADD Tagline nvarchar(250) NULL
GO

ALTER TABLE [dbo].[aspnet_Applications]
ADD Website nvarchar(2000) NULL
GO

ALTER TABLE [dbo].[aspnet_Applications]
ADD About nvarchar(max) NULL
GO

UPDATE [dbo].[aspnet_Applications]
SET About = [Description]
GO

ALTER TABLE [dbo].[aspnet_Applications]
DROP COLUMN [Description]
GO