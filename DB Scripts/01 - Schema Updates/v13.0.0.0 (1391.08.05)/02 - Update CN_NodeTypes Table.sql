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
           ,'6'
           ,N'واحد سازمانی'
           ,0)
GO

