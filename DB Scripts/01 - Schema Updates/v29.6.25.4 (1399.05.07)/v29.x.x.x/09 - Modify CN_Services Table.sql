USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER TABLE [dbo].[CN_Services]
ADD [IsCommunityPage] bit NULL
GO

ALTER TABLE [dbo].[CN_Services]
ADD [EnableComments] bit NULL
GO