USE [EKM_App]
GO

/****** Object:  Table [dbo].[KKnowledges]    Script Date: 04/04/2012 12:34:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


UPDATE [dbo].[NodeUsers]
	SET NodeUsersID = NEWID()
    WHERE NodeUsersID = '00000000-0000-0000-0000-000000000000'
GO

