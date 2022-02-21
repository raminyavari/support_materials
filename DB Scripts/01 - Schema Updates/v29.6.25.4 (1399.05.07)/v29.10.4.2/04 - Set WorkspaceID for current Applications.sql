USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


INSERT INTO [dbo].[RV_Workspaces] (WorkspaceID, [Name], CreatorUserID, CreationDate, Deleted)
SELECT NEWID(), N'پیش فرض', Creators.CreatorUserID, GETDATE(), 0
FROM (
		SELECT A.CreatorUserID
		FROM [dbo].[aspnet_Applications] AS A
		WHERE A.CreatorUserID IS NOT NULL
		GROUP BY A.CreatorUserID
	) AS Creators
	LEFT JOIN [dbo].[RV_Workspaces] AS WS
	ON WS.CreatorUserID = Creators.CreatorUserID
WHERE WS.WorkspaceID IS NULL
GO


UPDATE A
SET WorkspaceID = (
		SELECT TOP(1) W.WorkspaceID
		FROM [dbo].[RV_Workspaces] AS W
		WHERE W.CreatorUserID = A.CreatorUserID
	)
FROM [dbo].[aspnet_Applications] AS A
WHERE A.WorkspaceID IS NULL AND A.CreatorUserID IS NOT NULL
GO