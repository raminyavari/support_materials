USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[QA_AttachmentsListReport]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[QA_AttachmentsListReport]
GO

CREATE PROCEDURE [dbo].[QA_AttachmentsListReport]
	@ApplicationID	uniqueidentifier,
	@CurrentUserID	uniqueidentifier,
	@NodeTypeID		uniqueidentifier,
	@NodeID			uniqueidentifier,
	@DateFrom		datetime,
	@DateTo			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT	X.FileID AS FileID_Hide,
			X.[FileName],
			X.Extension,
			(ISNULL(X.Size, 0) / 1024) AS Size,
			X.QuestionID AS QuestionID_Hide,
			X.QuestionTitle,
			X.SenderUserID AS UserID_Hide,
			X.SenderFullName,
			X.SendDate,
			CASE WHEN ISNULL(X.IsAnswer, 0) = 1 THEN N'Answer' ELSE N'Question' END AS Type_Dic
	FROM [dbo].[QA_FN_AttachmentsListReport](@ApplicationID, @NodeTypeID, @NodeID, @DateFrom, @DateTo) AS X
	ORDER BY X.SendDate DESC

	SELECT ('{' +
			'"QuestionTitle": {"Action": "Link", "Type": "Question",' +
				'"Requires": {"ID": "QuestionID_Hide"}' +
			'},' +
			'"SenderFullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'},' +
			'"FileName": {"Action": "Link", "Type": "File",' +
				'"Requires": {"ID": "FileID_Hide"}' +
			'}' +
		   '}') AS Actions
END

GO