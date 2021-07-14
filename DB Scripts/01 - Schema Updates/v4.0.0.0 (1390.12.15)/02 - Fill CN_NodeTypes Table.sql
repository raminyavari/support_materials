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
           ,[Deleted]
           ,[TypeID])
     VALUES
           (NEWID()
           ,'1'
           ,'حوزه دانش'
           ,0
           ,1)
GO

INSERT INTO [dbo].[CN_NodeTypes]
           ([NodeTypeID]
           ,[AdditionalID]
           ,[Name]
           ,[Deleted]
           ,[TypeID])
     VALUES
           (NEWID()
           ,'2'
           ,'پروژه'
           ,0
           ,2)
GO

INSERT INTO [dbo].[CN_NodeTypes]
           ([NodeTypeID]
           ,[AdditionalID]
           ,[Name]
           ,[Deleted]
           ,[TypeID])
     VALUES
           (NEWID()
           ,'3'
           ,'فرآیند'
           ,0
           ,3)
GO

INSERT INTO [dbo].[CN_NodeTypes]
           ([NodeTypeID]
           ,[AdditionalID]
           ,[Name]
           ,[Deleted]
           ,[TypeID])
     VALUES
           (NEWID()
           ,'4'
           ,'انجمن دانایی'
           ,0
           ,4)
GO

