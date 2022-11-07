USE [EKM_App]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.6' BEGIN
	CREATE TABLE [dbo].[MSG_ThreadNames](
		[ThreadID] [uniqueidentifier] NOT NULL,
		[Name] [nvarchar](500) NOT NULL,
		[LastModifierUserID] [uniqueidentifier] NOT NULL,
		[LastModificationDate] [datetime] NOT NULL,
		[ApplicationID] [uniqueidentifier] NOT NULL,
	 CONSTRAINT [PK_MSG_ThreadNames] PRIMARY KEY CLUSTERED 
	(
		[ThreadID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.6' BEGIN
	ALTER TABLE [dbo].[MSG_ThreadNames]  WITH CHECK ADD  CONSTRAINT [FK_MSG_ThreadNames_aspnet_Users] FOREIGN KEY([LastModifierUserID])
	REFERENCES [dbo].[aspnet_Users] ([UserId])
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.6' BEGIN
	ALTER TABLE [dbo].[MSG_ThreadNames] CHECK CONSTRAINT [FK_MSG_ThreadNames_aspnet_Users]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.6' BEGIN
	ALTER TABLE [dbo].[MSG_ThreadNames]  WITH CHECK ADD  CONSTRAINT [FK_MSG_ThreadNames_aspnet_Applications] FOREIGN KEY([ApplicationID])
	REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.6' BEGIN
	ALTER TABLE [dbo].[MSG_ThreadNames] CHECK CONSTRAINT [FK_MSG_ThreadNames_aspnet_Applications]
END
GO

IF (SELECT TOP(1) X.[Version] FROM [dbo].[AppSetting] AS X) = N'v29.10.4.6' BEGIN
	UPDATE [dbo].[AppSetting]
	SET [Version] = 'v29.10.4.7' -- 14010816
END
GO