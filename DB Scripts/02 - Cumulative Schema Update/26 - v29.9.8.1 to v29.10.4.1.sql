USE [EKM_App]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
	CREATE TABLE [dbo].[RPT_GroupLimitsForAdmins](
		[NodeTypeID] [uniqueidentifier] NOT NULL,
		[LastModifierUserID] [uniqueidentifier] NULL,
		[LastModificationDate] [datetime] NULL,
		[Deleted] [bit] NOT NULL,
		[ApplicationID] [uniqueidentifier] NULL
	 CONSTRAINT [PK_RPT_GroupLimitsForAdmins] PRIMARY KEY CLUSTERED 
	(
		[NodeTypeID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
	) ON [PRIMARY]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
	ALTER TABLE [dbo].[RPT_GroupLimitsForAdmins]  WITH CHECK ADD  CONSTRAINT [FK_RPT_GroupLimitsForAdmins_aspnet_Applications] FOREIGN KEY([ApplicationID])
	REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
	ALTER TABLE [dbo].[RPT_GroupLimitsForAdmins] CHECK CONSTRAINT [FK_RPT_GroupLimitsForAdmins_aspnet_Applications]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
	ALTER TABLE [dbo].[RPT_GroupLimitsForAdmins]  WITH CHECK ADD  CONSTRAINT [FK_RPT_GroupLimitsForAdmins_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
	REFERENCES [dbo].[aspnet_Users] ([UserId])
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
	ALTER TABLE [dbo].[RPT_GroupLimitsForAdmins] CHECK CONSTRAINT [FK_RPT_GroupLimitsForAdmins_aspnet_Users_Modifier]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
	ALTER TABLE [dbo].[RPT_GroupLimitsForAdmins]  WITH CHECK ADD  CONSTRAINT [FK_RPT_GroupLimitsForAdmins_CN_NodeTypes] FOREIGN KEY([NodeTypeID])
	REFERENCES [dbo].[CN_NodeTypes] ([NodeTypeID])
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
	ALTER TABLE [dbo].[RPT_GroupLimitsForAdmins] CHECK CONSTRAINT [FK_RPT_GroupLimitsForAdmins_CN_NodeTypes]
END
GO


IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
	ALTER TABLE [dbo].[aspnet_Applications]
	ADD Tagline nvarchar(250) NULL
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
	ALTER TABLE [dbo].[aspnet_Applications]
	ADD Website nvarchar(2000) NULL
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
	ALTER TABLE [dbo].[aspnet_Applications]
	ADD About nvarchar(max) NULL
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
	EXEC ('UPDATE [dbo].[aspnet_Applications] ' +
		'SET About = [Description]')
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
	ALTER TABLE [dbo].[aspnet_Applications]
	DROP COLUMN [Description]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
	ALTER TABLE [dbo].[CN_NodeTypes]
	ADD UseAvatar bit NULL
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
	ALTER TABLE [dbo].[CN_Nodes]
	ADD UseAvatar bit NULL
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
	ALTER TABLE [dbo].[USR_Profile]
	ADD UseAvatar bit NULL
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
	ALTER TABLE [dbo].[aspnet_Applications]
	ADD UseAvatar bit NULL
END
GO


IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
	INSERT INTO [dbo].[CN_NodeTypes] (ApplicationID, NodeTypeID, Name, AdditionalID, Deleted)
	SELECT App.ApplicationId, NEWID(), N'مدیران سامانه', N'18', 0
	FROM [dbo].[aspnet_Applications] AS App
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
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
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
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
END
GO


IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
	INSERT INTO [dbo].[CN_NodeMembers] (ApplicationID, NodeID, UserID, UniqueID, MembershipDate, IsAdmin, Deleted, [Status])
	SELECT M.ApplicationID, M.GroupID, M.UserID, NEWID(), ISNULL(M.CreationDate, GETDATE()), 0, 0, N'' 
	FROM [dbo].[USR_UserGroupMembers] AS M
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
	CREATE TABLE [dbo].[PRVC_AudienceTemp](
		[ObjectID] [uniqueidentifier] NOT NULL,
		[RoleID] [uniqueidentifier] NOT NULL,
		[PermissionType] [nvarchar](50) NOT NULL,
		[Allow] [bit] NOT NULL,
		[ExpirationDate] [datetime] NULL,
		[CreatorUserID] [uniqueidentifier] NULL,
		[CreationDate] [datetime] NULL,
		[LastModifierUserID] [uniqueidentifier] NULL,
		[LastModificationDate] [datetime] NULL,
		[Deleted] [bit] NOT NULL,
		[ApplicationID] [uniqueidentifier] NULL
	) ON [PRIMARY]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
	INSERT INTO [dbo].[PRVC_AudienceTemp]
	SELECT *
	FROM [dbo].[PRVC_Audience]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
	DROP TABLE [dbo].[PRVC_Audience]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
	CREATE TABLE [dbo].[PRVC_Audience](
		[ObjectID] [uniqueidentifier] NOT NULL,
		[RoleID] [uniqueidentifier] NOT NULL,
		[PermissionType] [nvarchar](50) NOT NULL,
		[Allow] [bit] NOT NULL,
		[ExpirationDate] [datetime] NULL,
		[CreatorUserID] [uniqueidentifier] NULL,
		[CreationDate] [datetime] NULL,
		[LastModifierUserID] [uniqueidentifier] NULL,
		[LastModificationDate] [datetime] NULL,
		[Deleted] [bit] NOT NULL,
		[ApplicationID] [uniqueidentifier] NOT NULL,
	CONSTRAINT [PK_PRVC_Audience] PRIMARY KEY CLUSTERED 
	(
		[ApplicationID] ASC,
		[ObjectID] ASC,
		[RoleID] ASC,
		[PermissionType] ASC
	) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
	) ON [PRIMARY]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
	ALTER TABLE [dbo].[PRVC_Audience]  WITH CHECK ADD  CONSTRAINT [FK_PRVC_Audience_aspnet_Applications] FOREIGN KEY([ApplicationID])
	REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
	ALTER TABLE [dbo].[PRVC_Audience] CHECK CONSTRAINT [FK_PRVC_Audience_aspnet_Applications]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
	ALTER TABLE [dbo].[PRVC_Audience]  WITH CHECK ADD  CONSTRAINT [FK_PRVC_Audience_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
	REFERENCES [dbo].[aspnet_Users] ([UserId])
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
	ALTER TABLE [dbo].[PRVC_Audience] CHECK CONSTRAINT [FK_PRVC_Audience_aspnet_Users_Creator]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
	ALTER TABLE [dbo].[PRVC_Audience]  WITH CHECK ADD  CONSTRAINT [FK_PRVC_Audience_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
	REFERENCES [dbo].[aspnet_Users] ([UserId])
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
	ALTER TABLE [dbo].[PRVC_Audience] CHECK CONSTRAINT [FK_PRVC_Audience_aspnet_Users_Modifier]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
	INSERT INTO [dbo].[PRVC_Audience]
	SELECT *
	FROM [dbo].[PRVC_AudienceTemp]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
	DROP TABLE [dbo].[PRVC_AudienceTemp]
END
GO


IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
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
END
GO
	

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.9.8.1' BEGIN
	UPDATE [dbo].[AppSetting]
		SET [Version] = 'v29.10.4.1' -- 14000816
END
GO