USE [EKM_App]
GO

/****** Object:  Table [dbo].[KKnowledges]    Script Date: 04/04/2012 12:34:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


INSERT INTO [dbo].[AccessRoles]
           ([ID]
           ,[Role]
           ,[Title])
     VALUES
           (NEWID()
           ,N'DataImport'
           ,N'وارد کردن اطلاعات از منابع خارجی')
GO


INSERT INTO [dbo].[AccessRoles]
           ([ID]
           ,[Role]
           ,[Title])
     VALUES
           (NEWID()
           ,N'DepsAndUsersImport'
           ,N'وارد کردن کاربران و ساختار سازمانی از منابع خارجی')
GO


