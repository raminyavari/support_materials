USE [EKM_App]
GO


DECLARE @Items TABLE (RoleID uniqueidentifier, RoleName varchar(100))

INSERT INTO @Items (RoleID, RoleName)
VALUES	(N'675C0100-03E1-4EA9-BF03-CABCAB8726AD', 'UsersManagement'),
		(N'CC25C1FB-868A-45F9-8815-FA34AAECAFF0', 'ManageConfidentialityLevels'),
		(N'6CD7A66D-ECB8-4C30-8C68-DFBA67F0C903', 'UserGroupsManagement'),
		(N'83EA38C8-BB18-4581-B270-2A1AC64232B6', 'ContentsManagement'),
		(N'541D1973-777A-4B23-A7F7-787D15DBD1F6', 'DataImport'),
		(N'F05B2E41-25CB-4B34-AA59-9DFC3CEF558F', 'ManageOntology'),
		(N'9469F9F8-D36F-4BAF-97BD-966942CE5111', 'ManageWorkflow'),
		(N'74DEC1FD-C22A-4C14-8474-77241555593B', 'ManageForms'),
		(N'F89C4058-368C-4036-887A-DA174A32BE04', 'ManagePolls'),
		(N'4AE0E1F9-408F-4911-8202-F09BC6F2736D', 'KnowledgeAdmin'),
		(N'2B3C7D75-46DF-4A3A-A3A5-656597B9447E', 'SMSEMailNotifier'),
		(N'1A56D148-7222-4D8D-9FEF-32000A3EB745', 'ManageQA'),
		(N'CB3B9489-3DA6-414A-A9B8-0F7ED127B9AE', 'RemoteServers')

INSERT INTO [dbo].[PRVC_Audience] (ApplicationID, ObjectID, RoleID, PermissionType, Allow, 
	CreatorUserID, CreationDate, LastModifierUserID, LastModificationDate, Deleted)
SELECT	AR.ApplicationID, 
		I.RoleID AS ObjectID, 
		P.GroupID AS RoleID,
		N'View' AS PermissionType,
		1 AS Allow,
		P.CreatorUserID,
		P.CreationDate,
		P.LastModifierUserID,
		P.LastModificationDate,
		P.Deleted
FROM @Items AS I
	INNER JOIN [dbo].[USR_AccessRoles] AS AR
	ON LOWER(AR.[Name]) = LOWER(I.RoleName)
	INNER JOIN [dbo].[USR_UserGroupPermissions] AS P
	ON P.ApplicationID = AR.ApplicationID AND P.RoleID = AR.RoleID
GO
