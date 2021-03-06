USE [EKM_App]
GO

/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

DECLARE @PropertyID uniqueidentifier = [dbo].[CN_FN_GetRelatedRelationTypeID]()


INSERT INTO [dbo].[CN_NodeRelations](SourceNodeID, DestinationNodeID, PropertyID, Deleted)
SELECT KnowledgeID, NodeID, @PropertyID, ISNULL(Deleted, 0)
FROM [dbo].[KW_RelatedNodes] AS RN
WHERE NOT EXISTS(
		SELECT TOP(1) *
		FROM [dbo].[CN_NodeRelations] AS NR
		WHERE NR.SourceNodeID = RN.KnowledgeID AND DestinationNodeID = RN.NodeID AND
			NR.PropertyID = @PropertyID
	)

GO