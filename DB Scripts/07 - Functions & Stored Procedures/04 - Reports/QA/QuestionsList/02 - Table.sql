USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[QA_QuestionsListReport]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[QA_QuestionsListReport]
GO

CREATE PROCEDURE [dbo].[QA_QuestionsListReport]
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

	SELECT	X.QuestionID AS QuestionID_Hide,
			X.QuestionTitle,
			X.SenderUserID AS UserID_Hide,
			X.SenderFullName,
			X.SendDate
	FROM [dbo].[QA_FN_QuestionsListReport](@ApplicationID, @NodeTypeID, @NodeID, @DateFrom, @DateTo) AS X
	ORDER BY X.SendDate DESC

	SELECT ('{' +
			'"QuestionTitle": {"Action": "Link", "Type": "Question",' +
				'"Requires": {"ID": "QuestionID_Hide"}' +
			'},' +
			'"SenderFullName": {"Action": "Link", "Type": "User",' +
				'"Requires": {"UID": "UserID_Hide"}' +
			'}' +
		   '}') AS Actions
END

GO