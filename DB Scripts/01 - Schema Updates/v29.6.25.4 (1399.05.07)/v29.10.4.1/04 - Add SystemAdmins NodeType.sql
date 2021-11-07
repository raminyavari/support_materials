USE [EKM_App]
GO


INSERT INTO [dbo].[CN_NodeTypes] (ApplicationID, NodeTypeID, Name, AdditionalID, Deleted)
SELECT App.ApplicationId, NEWID(), N'مدیران سامانه', N'18', 0
FROM [dbo].[aspnet_Applications] AS App
GO

;WITH NTs AS
(
	SELECT T.ApplicationID, T.NodeTypeID
	FROM [dbo].[CN_NodeTypes] AS T
	WHERE T.AdditionalID = N'18'
),
Admins AS 
(

	SELECT	X.ApplicationID, 
			ISNULL(App.CreatorUserID, (
				SELECT TOP(1) U.UserId
				FROM [dbo].[USR_UserApplications] AS UA
					INNER JOIN [dbo].[aspnet_Users] AS U
					ON U.UserId = UA.UserID AND U.LoweredUserName = N'admin'
				WHERE UA.ApplicationID = X.ApplicationID
			)) AS AdminUserID
	FROM NTs AS X
		LEFT JOIN [dbo].[aspnet_Applications] AS App
		ON App.ApplicationId = X.ApplicationID
)
INSERT INTO [dbo].[CN_Extensions] (ApplicationID, OwnerID, Extension, SequenceNumber, CreatorUserID, CreationDate, Deleted)
SELECT X.ApplicationID, X.NodeTypeID, N'Members', 6, A.AdminUserID, GETDATE(), 0
FROM NTs AS X
	INNER JOIN Admins AS A
	ON A.ApplicationID = X.ApplicationID
GO


;WITH NTs AS
(
	SELECT T.ApplicationID, T.NodeTypeID
	FROM [dbo].[CN_NodeTypes] AS T
	WHERE T.AdditionalID = N'18'
)
INSERT INTO [dbo].[CN_Nodes] (ApplicationID, NodeTypeID, NodeID, [Name], Deleted)
SELECT X.ApplicationID, X.NodeTypeID, G.GroupID, G.Title, G.Deleted
FROM [dbo].[USR_UserGroups] AS G
	INNER JOIN NTs AS X
	ON X.ApplicationID = G.ApplicationID
GO


INSERT INTO [dbo].[CN_NodeMembers] (ApplicationID, NodeID, UserID, UniqueID, MembershipDate, IsAdmin, Deleted, [Status])
SELECT M.ApplicationID, M.GroupID, M.UserID, NEWID(), ISNULL(M.CreationDate, GETDATE()), 0, 0, N'' 
FROM [dbo].[USR_UserGroupMembers] AS M
GO