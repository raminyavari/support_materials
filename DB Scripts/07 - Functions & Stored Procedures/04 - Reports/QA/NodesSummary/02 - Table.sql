USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[QA_NodesSummaryReport]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[QA_NodesSummaryReport]
GO

CREATE PROCEDURE [dbo].[QA_NodesSummaryReport]
	@ApplicationID	uniqueidentifier,
	@CurrentUserID	uniqueidentifier,
	@NodeTypeID		uniqueidentifier,
	@DateFrom		datetime,
	@DateTo			datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON

	SELECT	X.NodeID AS NodeID_Hide,
			MAX(X.NodeName) AS NodeName,
			MAX(X.NodeType) AS NodeType,
			COUNT(DISTINCT X.SenderUserID) AS ContributorsCount,
			COUNT(DISTINCT X.QuestionID) AS QuestionsCount,
			COUNT(DISTINCT X.AnswerID) AS AnswersCount
	FROM [dbo].[QA_FN_NodesSummaryReport](@ApplicationID, @NodeTypeID, @DateFrom, @DateTo) AS X
	GROUP BY X.NodeID

	SELECT ('{' +
			'"NodeName": {"Action": "Link", "Type": "Node",' +
				'"Requires": {"ID": "NodeID_Hide"}' +
			'}' +
		   '}') AS Actions
END

GO