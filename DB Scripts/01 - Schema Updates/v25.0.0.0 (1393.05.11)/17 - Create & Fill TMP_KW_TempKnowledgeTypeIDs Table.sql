USE [EKM_App]
GO

/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[TMP_KW_TempKnowledgeTypeIDs](
	[IntID] [int] NOT NULL,
	[Guid] [uniqueidentifier] NOT NULL
 CONSTRAINT [PK_TMP_KW_TempKnowledgeTypeIDs] PRIMARY KEY CLUSTERED 
(
	[IntID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


INSERT INTO [dbo].[TMP_KW_TempKnowledgeTypeIDs]
SELECT KnowledgeTypeID, NEWID()
FROM [dbo].[KW_KnowledgeTypes]

GO
