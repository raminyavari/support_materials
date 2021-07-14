USE [EKM_App]
GO


IF NOT EXISTS(SELECT * 
FROM sys.indexes WHERE name='IX_EVT_Events_BeginDate' AND object_id = OBJECT_ID('EVT_Events'))
CREATE NONCLUSTERED INDEX [IX_EVT_Events_BeginDate] ON [dbo].[EVT_Events] 
(
	[BeginDate] ASC,
	[EventID] ASC,
	[OwnerID] ASC,
	[CreatorUserID] ASC,
	[Deleted] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO


IF NOT EXISTS(SELECT * 
FROM sys.indexes WHERE name='IX_EVT_Events_FinishDate' AND object_id = OBJECT_ID('EVT_Events'))
CREATE NONCLUSTERED INDEX [IX_EVT_Events_FinishDate] ON [dbo].[EVT_Events] 
(
	[FinishDate] ASC,
	[EventID] ASC,
	[OwnerID] ASC,
	[CreatorUserID] ASC,
	[Deleted] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO


IF NOT EXISTS(SELECT * 
FROM sys.indexes WHERE name='IX_EVT_RelatedUsers_UserID' AND object_id = OBJECT_ID('EVT_RelatedUsers'))
CREATE NONCLUSTERED INDEX [IX_EVT_RelatedUsers_UserID] ON [dbo].[EVT_RelatedUsers] 
(
	[UserID] ASC,
	[EventID] ASC,
	[Status] ASC,
	[Done] ASC,
	[Deleted] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO


IF NOT EXISTS(SELECT * 
FROM sys.indexes WHERE name='IX_EVT_RelatedNodes_NodeID' AND object_id = OBJECT_ID('EVT_RelatedNodes'))
CREATE NONCLUSTERED INDEX [IX_EVT_RelatedNodes_NodeID] ON [dbo].[EVT_RelatedNodes] 
(
	[NodeID] ASC,
	[EventID] ASC,
	[Deleted] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO