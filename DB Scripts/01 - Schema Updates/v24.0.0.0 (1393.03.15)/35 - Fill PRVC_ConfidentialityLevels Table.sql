USE [EKM_App]
GO

/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

DELETE [dbo].[PRVC_ConfidentialityLevels]
GO

DECLARE @UserID uniqueidentifier = (SELECT TOP(1) UserId FROM [dbo].[aspnet_Users]
	WHERE LoweredUserName = N'admin')

INSERT INTO [dbo].[PRVC_ConfidentialityLevels](ID, LevelID, Title, 
	CreatorUserID, CreationDate, Deleted)
SELECT NEWID(), LevelID, Title, @UserID, GETDATE(), 0
FROM [dbo].[KW_ConfidentialityLevels]

GO


DECLARE @UserID uniqueidentifier = (SELECT TOP(1) UserId FROM [dbo].[aspnet_Users]
	WHERE LoweredUserName = N'admin')

INSERT INTO [dbo].[PRVC_Confidentialities](LevelID, ItemID, CreatorUserID, CreationDate, Deleted)
SELECT L.ID, UserID, @UserID, GETDATE(), 0
FROM [dbo].[KW_UsersConfidentialityLevels] AS U
	INNER JOIN [dbo].[PRVC_ConfidentialityLevels] AS L
	ON U.LevelID = L.LevelID
	
INSERT INTO [dbo].[PRVC_Confidentialities](LevelID, ItemID, CreatorUserID, CreationDate, Deleted)
SELECT L.ID, KnowledgeID, @UserID, GETDATE(), 0
FROM [dbo].[KW_Knowledges] AS U
	INNER JOIN [dbo].[PRVC_ConfidentialityLevels] AS L
	ON U.ConfidentialityLevelID = L.LevelID

GO