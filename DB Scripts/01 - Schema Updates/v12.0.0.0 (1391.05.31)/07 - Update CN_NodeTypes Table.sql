USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


INSERT INTO [dbo].[CN_NodeTypes]
           ([NodeTypeID]
           ,[AdditionalID]
           ,[Name]
           ,[Deleted])
     VALUES
           (NEWID()
           ,'5'
           ,N'دانش'
           ,0)
GO

