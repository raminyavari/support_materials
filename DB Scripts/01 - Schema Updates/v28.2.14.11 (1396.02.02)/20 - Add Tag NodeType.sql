USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET ANSI_PADDING ON
GO


DECLARE @Now datetime = GETDATE()

DECLARE @NodeTypes Table (AdditionalID varchar(20), Name nvarchar(500))

INSERT INTO @NodeTypes (AdditionalID, Name)
VALUES ('11', N'تگ')

INSERT INTO [dbo].[CN_NodeTypes] (
	[ApplicationID],
	[NodeTypeID], 
	[Name], 
	[Deleted], 
	[CreatorUserID], 
	[CreationDate],
	[AdditionalID]
) 
SELECT  App.ApplicationId, 
		NEWID(), 
		[dbo].[GFN_VerifyString](NT.Name), 
		0, 
		UN.UserID, 
		@Now, 
		NT.AdditionalID
FROM [dbo].[aspnet_Applications] AS App
	CROSS JOIN @NodeTypes AS NT
	LEFT JOIN [dbo].[CN_NodeTypes] AS T
	ON T.ApplicationID = App.ApplicationId AND T.AdditionalID = NT.AdditionalID
	INNER JOIN [dbo].[Users_Normal] AS UN
	ON UN.ApplicationID = App.ApplicationId AND LOWER(UN.UserName) = N'admin'
WHERE T.NodeTypeID IS NULL


GO