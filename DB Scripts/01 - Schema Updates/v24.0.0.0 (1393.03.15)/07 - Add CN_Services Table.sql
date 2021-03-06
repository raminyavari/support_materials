USE [EKM_App]
GO

/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[CN_Services](
	[NodeTypeID] [uniqueidentifier] NOT NULL,
	[ServiceTitle] [nvarchar](512) NULL,
	[ServiceDescription] [nvarchar](4000) NULL,
	[SuccessMessage] [nvarchar] (4000) NULL,
	[EnableContribution] [bit] NOT NULL,
	[AdminType] [varchar](20) NULL,
	[AdminNodeID] [uniqueidentifier] NULL,
	[SequenceNumber] [int] NOT NULL,
	[MaxAcceptableAdminLevel] [int] NULL,
	[LimitAttachedFilesTo] [varchar](2000) NULL,
	[MaxAttachedFileSize] [int] NULL,
	[MaxAttachedFilesCount] [int] NULL,
	[EditableForAdmin] [bit] NOT NULL,
	[EditableForCreator] [bit] NOT NULL,
	[EditableForOwners] [bit] NOT NULL,
	[EditableForExperts] [bit] NOT NULL,
	[EditableForMembers] [bit] NOT NULL,
	[Deleted] [bit] NOT NULL
 CONSTRAINT [PK_CN_Services] PRIMARY KEY CLUSTERED 
(
	[NodeTypeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


ALTER TABLE [dbo].[CN_Services]  WITH CHECK ADD  CONSTRAINT [FK_CN_Services_CN_NodeTypes] FOREIGN KEY([NodeTypeID])
REFERENCES [dbo].[CN_NodeTypes] ([NodeTypeID])
GO

ALTER TABLE [dbo].[CN_Services] CHECK CONSTRAINT [FK_CN_Services_CN_NodeTypes]
GO

ALTER TABLE [dbo].[CN_Services]  WITH CHECK ADD  CONSTRAINT [FK_CN_Services_CN_Nodes] FOREIGN KEY([AdminNodeID])
REFERENCES [dbo].[CN_Nodes] ([NodeID])
GO

ALTER TABLE [dbo].[CN_Services] CHECK CONSTRAINT [FK_CN_Services_CN_Nodes]
GO