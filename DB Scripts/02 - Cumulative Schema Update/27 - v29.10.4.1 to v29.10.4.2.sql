USE [EKM_App]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	ALTER TABLE [dbo].[aspnet_Applications]
	ADD GeneralInvitationCode uniqueidentifier NULL	
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	ALTER TABLE [dbo].[aspnet_Applications]
	ADD GeneralInvitationCodeExpirationTime datetime NULL
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	ALTER TABLE [dbo].[aspnet_Applications]
	ADD WorkspaceID uniqueidentifier NULL
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	DROP TABLE [dbo].[RV_WorkSpaceApplications]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	DROP TABLE [dbo].[RV_WorkSpaces]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	CREATE TABLE [dbo].[RV_Workspaces](
		[WorkspaceID] [uniqueidentifier] NOT NULL,
		[Name] [nvarchar](255) NOT NULL,
		[Description] [nvarchar](2000) NULL,
		[AvatarName] [varchar](50) NULL,
		[UseAvatar] [bit] NULL,
		[CreatorUserID] [uniqueidentifier] NOT NULL,
		[CreationDate] [datetime] NOT NULL,
		[LastModifierUserID] [uniqueidentifier] NULL,
		[LastModificationDate] [datetime] NULL,
		[Deleted] [bit] NOT NULL,
	 CONSTRAINT [PK_RV_Workspaces] PRIMARY KEY CLUSTERED 
	(
		[WorkspaceID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	ALTER TABLE [dbo].[RV_Workspaces]  WITH CHECK ADD  CONSTRAINT [FK_RV_Workspaces_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
	REFERENCES [dbo].[aspnet_Users] ([UserId])
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	ALTER TABLE [dbo].[RV_Workspaces] CHECK CONSTRAINT [FK_RV_Workspaces_aspnet_Users_Creator]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	ALTER TABLE [dbo].[RV_Workspaces]  WITH CHECK ADD  CONSTRAINT [FK_RV_Workspaces_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
	REFERENCES [dbo].[aspnet_Users] ([UserId])
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	ALTER TABLE [dbo].[RV_Workspaces] CHECK CONSTRAINT [FK_RV_Workspaces_aspnet_Users_Modifier]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
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
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	UPDATE A
	SET WorkspaceID = (
			SELECT TOP(1) W.WorkspaceID
			FROM [dbo].[RV_Workspaces] AS W
			WHERE W.CreatorUserID = A.CreatorUserID
		)
	FROM [dbo].[aspnet_Applications] AS A
	WHERE A.WorkspaceID IS NULL AND A.CreatorUserID IS NOT NULL
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	CREATE TABLE [dbo].[WK_Blocks](
		[BlockID] [uniqueidentifier] NOT NULL,
		[OwnerID] [uniqueidentifier] NOT NULL,
		[Key] [varchar](20) NOT NULL,
		[Type] [varchar](20) NOT NULL,
		[Body] [nvarchar](max) NULL,
		[ApplicationID] [uniqueidentifier] NOT NULL
	 CONSTRAINT [PK_WK_Blocks] PRIMARY KEY CLUSTERED 
	(
		[BlockID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
	 CONSTRAINT [UK_WK_Blocks] UNIQUE NONCLUSTERED 
	(
		[OwnerID] ASC,
		[BlockID] ASC,
		[Key] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	ALTER TABLE [dbo].[WK_Blocks]  WITH CHECK ADD  CONSTRAINT [FK_WK_Blocks_aspnet_Applications] FOREIGN KEY([ApplicationID])
	REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	ALTER TABLE [dbo].[WK_Blocks] CHECK CONSTRAINT [FK_WK_Blocks_aspnet_Applications]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	CREATE TABLE [dbo].[WK_History](
		[ID] [bigint] IDENTITY(1, 1) NOT NULL,
		[BlockID] [uniqueidentifier] NULL,
		[OwnerID] [uniqueidentifier] NULL,
		[Action] [varchar](20) NOT NULL,
		[Time] [datetime] NOT NULL,
		[Body] [nvarchar](max),
		[UserID] [uniqueidentifier] NOT NULL,
		[ApplicationID] [uniqueidentifier] NOT NULL
	 CONSTRAINT [PK_WK_History] PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
	 CONSTRAINT [UK_WK_History_BlockID] UNIQUE NONCLUSTERED 
	(
		[BlockID] ASC,
		[ID] ASC,
		[OwnerID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
	CONSTRAINT [UK_WK_History_OwnerID] UNIQUE NONCLUSTERED 
	(
		[OwnerID] ASC,
		[BlockID] ASC,
		[ID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	ALTER TABLE [dbo].[WK_History]  WITH CHECK ADD  CONSTRAINT [FK_WK_History_aspnet_Applications] FOREIGN KEY([ApplicationID])
	REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	ALTER TABLE [dbo].[WK_History] CHECK CONSTRAINT [FK_WK_History_aspnet_Applications]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	ALTER TABLE [dbo].[WK_History]  WITH CHECK ADD  CONSTRAINT [FK_WK_History_aspnet_Users] FOREIGN KEY([UserID])
	REFERENCES [dbo].[aspnet_Users] ([UserId])
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	ALTER TABLE [dbo].[WK_History] CHECK CONSTRAINT [FK_WK_History_aspnet_Users]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	ALTER TABLE [dbo].[WK_History]  WITH CHECK ADD  CONSTRAINT [FK_WK_History_WK_Blocks] FOREIGN KEY([BlockID])
	REFERENCES [dbo].[WK_Blocks] ([BlockID])
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	ALTER TABLE [dbo].[WK_History] CHECK CONSTRAINT [FK_WK_History_WK_Blocks]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	CREATE TABLE [dbo].[WK_OwnerBlocks](
		[OwnerID] [uniqueidentifier] NOT NULL,
		[BlockID] [uniqueidentifier] NOT NULL,
		[SequenceNumber] [int] NOT NULL,
		[Depth] [int] NOT NULL,
		[ModifierUserID] [uniqueidentifier] NOT NULL,
		[ModificationDate] [datetime] NOT NULL,
		[ApplicationID] [uniqueidentifier] NOT NULL
	 CONSTRAINT [PK_WK_OwnerBlocks] PRIMARY KEY CLUSTERED 
	(
		[OwnerID] ASC,
		[BlockID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	ALTER TABLE [dbo].[WK_OwnerBlocks]  WITH CHECK ADD  CONSTRAINT [FK_WK_OwnerBlocks_aspnet_Applications] FOREIGN KEY([ApplicationID])
	REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	ALTER TABLE [dbo].[WK_OwnerBlocks] CHECK CONSTRAINT [FK_WK_OwnerBlocks_aspnet_Applications]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	ALTER TABLE [dbo].[WK_OwnerBlocks]  WITH CHECK ADD  CONSTRAINT [FK_WK_OwnerBlocks_WK_Blocks] FOREIGN KEY([BlockID])
	REFERENCES [dbo].[WK_Blocks] ([BlockID])
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	ALTER TABLE [dbo].[WK_OwnerBlocks] CHECK CONSTRAINT [FK_WK_OwnerBlocks_WK_Blocks]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	ALTER TABLE [dbo].[WK_OwnerBlocks]  WITH CHECK ADD  CONSTRAINT [FK_WK_OwnerBlocks_aspnet_Users] FOREIGN KEY([ModifierUserID])
	REFERENCES [dbo].[aspnet_Users] ([UserID])
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	ALTER TABLE [dbo].[WK_OwnerBlocks] CHECK CONSTRAINT [FK_WK_OwnerBlocks_aspnet_Users]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	CREATE TABLE [dbo].[WK_EntityMaps](
		[OwnerID] [uniqueidentifier] NOT NULL,
		[EntityMap] [nvarchar](max) NOT NULL,
		[ModifierUserID] [uniqueidentifier] NOT NULL,
		[ModificationDate] [datetime] NOT NULL,
		[ApplicationID] [uniqueidentifier] NOT NULL
	 CONSTRAINT [PK_WK_EntityMaps] PRIMARY KEY CLUSTERED 
	(
		[OwnerID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	ALTER TABLE [dbo].[WK_EntityMaps]  WITH CHECK ADD  CONSTRAINT [FK_WK_EntityMaps_aspnet_Applications] FOREIGN KEY([ApplicationID])
	REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	ALTER TABLE [dbo].[WK_EntityMaps] CHECK CONSTRAINT [FK_WK_EntityMaps_aspnet_Applications]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	ALTER TABLE [dbo].[WK_EntityMaps]  WITH CHECK ADD  CONSTRAINT [FK_WK_EntityMaps_aspnet_Users] FOREIGN KEY([ModifierUserID])
	REFERENCES [dbo].[aspnet_Users] ([UserID])
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	ALTER TABLE [dbo].[WK_EntityMaps] CHECK CONSTRAINT [FK_WK_EntityMaps_aspnet_Users]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	ALTER TABLE [dbo].[CN_Services]
	ADD [IsCommunityPage] bit NULL
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	ALTER TABLE [dbo].[CN_Services]
	ADD [EnableComments] bit NULL
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.1' BEGIN
	UPDATE [dbo].[AppSetting]
	SET [Version] = 'v29.10.4.2' -- 14001202
END
GO
