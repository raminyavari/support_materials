USE [EKM_App]
GO

SET ANSI_PADDING ON
GO

DECLARE @UserID uniqueidentifier = N'e4f33bd2-bb3f-40fe-a1d2-912732a4fd80'

IF NOT EXISTS(SELECT TOP(1) * FROM [dbo].[aspnet_Users] WHERE UserId = @UserID) BEGIN
	DECLARE @AppId uniqueidentifier = 
		(SELECT TOP(1) ApplicationId FROM [dbo].[aspnet_Applications])

	INSERT [dbo].[aspnet_Users] ([ApplicationId], [UserId], [UserName], [LoweredUserName], 
		[MobileAlias], [IsAnonymous], [LastActivityDate]) 
	VALUES (@AppId, @UserID, N'system', N'system', NULL, 0, CAST(0x0000A1A900C898BC AS DateTime))
		
	INSERT [dbo].[USR_Profile] ([UserId], [FirstName], [Lastname], [JobTitle], [BirthDay]) 
	VALUES (@UserID, N'رای', N'ون', NULL, NULL)
		
	INSERT [dbo].[aspnet_Membership] ([ApplicationId], [UserId], [Password], [PasswordFormat], 
		[PasswordSalt], [MobilePIN], [Email], [LoweredEmail], [PasswordQuestion], 
		[PasswordAnswer], [IsApproved], [IsLockedOut], [CreateDate], [LastLoginDate], 
		[LastPasswordChangedDate], [LastLockoutDate], [FailedPasswordAttemptCount], 
		[FailedPasswordAttemptWindowStart], [FailedPasswordAnswerAttemptCount], 
		[FailedPasswordAnswerAttemptWindowStart], [Comment]) 
	VALUES (@AppId, @UserID, 
		N'saS+wizpq8cetvwnCAdCAHek3Ls=', 1, N'0QnG9cGvuzB99qo+ycdaow==', NULL, NULL, NULL, NULL, 
		NULL, 1, 0, CAST(0x0000A1A900C898BC AS DateTime), CAST(0x0000A1A900C898BC AS DateTime), 
		CAST(0x0000A1A900C898BC AS DateTime), CAST(0xFFFF2FB300000000 AS DateTime), 0, 
		CAST(0xFFFF2FB300000000 AS DateTime), 0, CAST(0xFFFF2FB300000000 AS DateTime), NULL)
END

GO

SET ANSI_PADDING OFF
GO