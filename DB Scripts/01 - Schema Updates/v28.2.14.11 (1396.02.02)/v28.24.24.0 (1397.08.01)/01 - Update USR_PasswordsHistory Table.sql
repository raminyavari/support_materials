USE [EKM_App]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

ALTER TABLE [dbo].[USR_PasswordsHistory]
ADD [AutoGenerated] bit NULL
GO

SET ANSI_PADDING OFF
GO
