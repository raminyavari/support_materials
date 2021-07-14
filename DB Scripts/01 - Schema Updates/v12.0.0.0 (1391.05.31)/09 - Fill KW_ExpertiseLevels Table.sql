USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


INSERT INTO [dbo].[KW_ExpertiseLevels]
		   ([LevelID]
		   ,[Title]
		   ,[CreatorUserID]
		   ,[CreationDate]
		   ,[Deleted])
	 VALUES
		   (1
		   ,N'تبحر'
           ,(SELECT TOP(1) [dbo].[aspnet_Users].[UserId] FROM [dbo].[aspnet_Users])
           ,GETDATE()
           ,0)
GO