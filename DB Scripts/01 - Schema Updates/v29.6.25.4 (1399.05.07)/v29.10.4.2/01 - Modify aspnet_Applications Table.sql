USE [EKM_App]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER TABLE [dbo].[aspnet_Applications]
ADD GeneralInvitationCode uniqueidentifier NULL
GO

ALTER TABLE [dbo].[aspnet_Applications]
ADD GeneralInvitationCodeExpirationTime datetime NULL
GO

ALTER TABLE [dbo].[aspnet_Applications]
ADD WorkspaceID uniqueidentifier NULL
GO

