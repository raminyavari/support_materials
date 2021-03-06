USE [EKM_App]
GO

/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS(select * FROM sys.views where name = 'KW_View_ContentFileExtensions')
DROP VIEW [dbo].[KW_View_ContentFileExtensions]
GO

IF EXISTS(select * FROM sys.views where name = 'KW_View_Knowledges')
DROP VIEW [dbo].[KW_View_Knowledges]
GO

CREATE VIEW [dbo].[KW_View_Knowledges] WITH SCHEMABINDING, ENCRYPTION
AS
SELECT     dbo.KW_Knowledges.KnowledgeID, dbo.KW_Knowledges.KnowledgeTypeID,
		   dbo.KW_KnowledgeTypes.Name AS KnowledgeType, 
		   dbo.CN_Nodes.AdditionalID AS AdditionalID,
		   dbo.KW_Knowledges.PreviousVersionID,
		   dbo.KW_Knowledges.ContentType, dbo.KW_Knowledges.IsDefault, 
           dbo.KW_Knowledges.ExtendedFormID, dbo.KW_Knowledges.TreeNodeID, 
           dbo.KW_Knowledges.ConfidentialityLevelID, dbo.KW_Knowledges.StatusID, 
           dbo.KW_Knowledges.PublicationDate, dbo.CN_Nodes.Name AS Title, 
           dbo.CN_Nodes.CreatorUserID, dbo.CN_Nodes.LastModifierUserID, 
           dbo.CN_Nodes.CreationDate, dbo.CN_Nodes.LastModificationDate, 
           dbo.KW_Knowledges.Score, dbo.KW_Knowledges.ScoresWeight,
           dbo.CN_Nodes.Privacy, dbo.CN_Nodes.Deleted
FROM       dbo.CN_Nodes INNER JOIN dbo.KW_Knowledges ON 
		   dbo.CN_Nodes.NodeID = dbo.KW_Knowledges.KnowledgeID INNER JOIN
		   dbo.KW_KnowledgeTypes ON 
		   dbo.KW_Knowledges.KnowledgeTypeID = dbo.KW_KnowledgeTypes.KnowledgeTypeID

GO


INSERT INTO [dbo].[CN_NodeCreators](NodeID, UserID, CollaborationShare, CreatorUserID,
	CreationDate, Deleted)
SELECT KW.KnowledgeID, KW.CreatorUserID, 100, KW.CreatorUserID, KW.CreationDate, 0
FROM [dbo].[KW_View_Knowledges] AS KW
WHERE NOT EXISTS(
		SELECT TOP(1) *
		FROM [dbo].[KW_CreatorUsers] AS CU
		WHERE CU.KnowledgeID = KW.KnowledgeID
	)
GO
	

INSERT INTO [dbo].[CN_NodeCreators](NodeID, UserID, CollaborationShare, CreatorUserID,
	CreationDate, Deleted)
SELECT KW.KnowledgeID, CU.UserID, CU.CollaborationShare, 
	KW.CreatorUserID, KW.CreationDate, 0
FROM [dbo].[KW_View_Knowledges] AS KW
	INNER JOIN [dbo].[KW_CreatorUsers] AS CU
	ON CU.KnowledgeID = KW.KnowledgeID
GO

IF EXISTS(select * FROM sys.views where name = 'KW_View_Knowledges')
DROP VIEW [dbo].[KW_View_Knowledges]
GO