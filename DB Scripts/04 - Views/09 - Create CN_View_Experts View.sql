USE [EKM_App]
GO

SET NUMERIC_ROUNDABORT OFF;
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT,
    QUOTED_IDENTIFIER, ANSI_NULLS ON;


IF EXISTS(select * FROM sys.views where name = 'CN_View_Experts')
DROP VIEW [dbo].[CN_View_Experts]
GO


CREATE VIEW [dbo].[CN_View_Experts] WITH SCHEMABINDING, ENCRYPTION
AS
SELECT  EX.ApplicationID,
		EX.NodeID AS NodeID,
		EX.UserID AS UserID,
		ND.NodeTypeID AS NodeTypeID,
		ND.Name AS NodeName
FROM    [dbo].[CN_Experts] AS EX
		INNER JOIN [dbo].[CN_Nodes] AS ND
		ON ND.ApplicationID = EX.ApplicationID AND ND.NodeID = EX.NodeID
		INNER JOIN [dbo].[aspnet_Membership] AS M
		ON M.UserId = EX.UserID
WHERE	(EX.Approved = 1 OR EX.SocialApproved = 1) AND 
		ND.Deleted = 0 AND M.IsApproved = 1

GO

CREATE UNIQUE CLUSTERED INDEX PK_CN_View_Experts_NodeID ON [dbo].[CN_View_Experts]
(
	[ApplicationID] ASC,
	[NodeID] ASC,
	[UserID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name='IX_CN_View_Experts_UserID' AND 
	object_id = OBJECT_ID('CN_View_Experts'))
CREATE NONCLUSTERED INDEX [IX_CN_View_Experts_UserID] ON [dbo].[CN_View_Experts] 
(
	[ApplicationID] ASC,
	[UserID] ASC,
	[NodeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO