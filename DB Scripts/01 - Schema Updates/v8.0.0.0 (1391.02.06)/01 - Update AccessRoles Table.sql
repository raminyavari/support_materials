USE [EKM_App]
GO

/****** Object:  Table [dbo].[KKnowledges]    Script Date: 04/04/2012 12:34:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



DELETE FROM [dbo].[AccessRoles]
      WHERE Role = N'OrganMetrics'
GO


INSERT INTO [dbo].[AccessRoles]
           ([ID]
           ,[Role]
           ,[Title])
     VALUES
           (NEWID()
           ,N'AssignUsersAsExpert'
           ,N'تعیین خبرگان حوزه های دانش')
GO


