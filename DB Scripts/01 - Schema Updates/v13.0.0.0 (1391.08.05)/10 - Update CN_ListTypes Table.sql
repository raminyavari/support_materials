USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


INSERT INTO [dbo].[CN_ListTypes]
           ([ListTypeID]
           ,[AdditionalID]
           ,[Name]
           ,[Deleted])
     VALUES
           (NEWID()
           ,'100'
           ,N'گروه سازمانی'
           ,0)
GO

