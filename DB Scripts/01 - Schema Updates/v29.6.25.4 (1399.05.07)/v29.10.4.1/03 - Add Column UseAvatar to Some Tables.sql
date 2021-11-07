USE [EKM_App]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER TABLE [dbo].[CN_NodeTypes]
ADD UseAvatar bit NULL
GO

ALTER TABLE [dbo].[CN_Nodes]
ADD UseAvatar bit NULL
GO

ALTER TABLE [dbo].[USR_Profile]
ADD UseAvatar bit NULL
GO

ALTER TABLE [dbo].[aspnet_Applications]
ADD UseAvatar bit NULL
GO
