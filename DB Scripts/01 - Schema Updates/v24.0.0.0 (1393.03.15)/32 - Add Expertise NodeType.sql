USE [EKM_App]
GO

/****** Object:  View [dbo].[CN_View_Nodes_Normal]    Script Date: 06/22/2012 13:03:22 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

DECLARE @UserID uniqueidentifier = (SELECT TOP(1) UserId FROM [dbo].[aspnet_Users] WHERE LoweredUserName = N'admin')

INSERT INTO [dbo].[CN_NodeTypes](
	NodeTypeID,
	AdditionalID,
	Name,
	CreatorUserID,
	CreationDate,
	Deleted
)
VALUES(
	NEWID(),
	7,
	N'تخصص',
	@UserID,
	GETDATE(),
	0
)

GO
