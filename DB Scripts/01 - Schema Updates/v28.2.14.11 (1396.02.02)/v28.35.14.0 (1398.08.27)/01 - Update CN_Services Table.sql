USE [EKM_App]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

ALTER TABLE [dbo].[CN_Services]
ADD [DisableRelatedNodesSelect] [bit] NULL
GO

ALTER TABLE [dbo].[CN_Services]
ADD [DisableAbstractAndKeywords] [bit] NULL
GO

SET ANSI_PADDING OFF
GO

