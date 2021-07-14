USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



INSERT INTO [dbo].[DCT_TreeTypes]
           ([TreeTypeID]
           ,[Name]
           ,[CreatorUserID]
           ,[CreationDate]
           ,[Deleted])
     VALUES
           (1
           ,N'مستندات'
           ,(SELECT TOP(1) [dbo].[aspnet_Users].[UserId] FROM [dbo].[aspnet_Users])
           ,GETDATE()
           ,0)
GO