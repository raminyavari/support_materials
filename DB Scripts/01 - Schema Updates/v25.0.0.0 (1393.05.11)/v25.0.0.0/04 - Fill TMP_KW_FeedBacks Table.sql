USE [EKM_App]
GO

/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

INSERT INTO [dbo].[TMP_KW_FeedBacks] (KnowledgeID, UserID, FeedBackTypeID, 
	SendDate, Value, [Description], Deleted)
SELECT KnowledgeID, UserID, FeedBackTypeID, SendDate, Value, [Description], Deleted
FROM [dbo].[KW_FeedBacks]

GO