USE [EKM_App]
GO


IF NOT EXISTS(SELECT * 
FROM sys.indexes WHERE name='IX_DCT_Trees_OwnerID' AND object_id = OBJECT_ID('DCT_Trees'))
CREATE NONCLUSTERED INDEX [IX_DCT_Trees_OwnerID] ON [dbo].[DCT_Trees] 
(
	[OwnerID] ASC,
	[TreeID] ASC,
	[IsPrivate] ASC,
	[Privacy] ASC,
	[Deleted] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO


IF NOT EXISTS(SELECT * 
FROM sys.indexes WHERE name='IX_DCT_TreeNodes_TreeID' AND object_id = OBJECT_ID('DCT_TreeNodes'))
CREATE NONCLUSTERED INDEX [IX_DCT_TreeNodes_TreeID] ON [dbo].[DCT_TreeNodes] 
(
	[TreeID] ASC,
	[TreeNodeID] ASC,
	[ParentNodeID] ASC,
	[Privacy] ASC,
	[Deleted] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO


IF NOT EXISTS(SELECT * 
FROM sys.indexes WHERE name='IX_DCT_TreeNodes_ParentNodeID' AND object_id = OBJECT_ID('DCT_TreeNodes'))
CREATE NONCLUSTERED INDEX [IX_DCT_TreeNodes_ParentNodeID] ON [dbo].[DCT_TreeNodes] 
(
	[ParentNodeID] ASC,
	[TreeNodeID] ASC,
	[TreeID] ASC,
	[Privacy] ASC,
	[Deleted] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO