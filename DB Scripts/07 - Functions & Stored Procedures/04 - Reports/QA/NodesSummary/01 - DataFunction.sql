USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[QA_FN_NodesSummaryReport]') 
    AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[QA_FN_NodesSummaryReport]
GO

CREATE FUNCTION [dbo].[QA_FN_NodesSummaryReport](
	@ApplicationID	uniqueidentifier,
	@NodeTypeID		uniqueidentifier,
	@DateFrom		datetime,
	@DateTo			datetime
)
RETURNS @outputTable TABLE (
	QuestionID		uniqueidentifier,
	AnswerID		uniqueidentifier,
	SendDate		datetime,
	SenderUserID	uniqueidentifier,
	NodeTypeID		uniqueidentifier,
	NodeType		nvarchar(max),
	NodeID			uniqueidentifier,
	NodeName		nvarchar(max)
)
WITH ENCRYPTION
AS
BEGIN
	;WITH Questions AS (
		SELECT	Q.QuestionID,
				NULL AS AnswerID,
				Q.SendDate,
				Q.SenderUserID,
				ND.NodeTypeID,
				ND.TypeName AS NodeType,
				ND.NodeID,
				ND.NodeName
		FROM [dbo].[QA_Questions] AS Q
			INNER JOIN [dbo].[QA_RelatedNodes] AS RN
			ON RN.ApplicationID = @ApplicationID AND RN.QuestionID = Q.QuestionID AND RN.Deleted = 0
			INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
			ON ND.NodeID = RN.NodeID AND 
				(@NodeTypeID IS NULL OR ND.NodeTypeID = @NodeTypeID) AND ND.Deleted = 0
		WHERE Q.ApplicationID = @ApplicationID
	),
	Answers AS (
		SELECT	Q.QuestionID,
				ANS.AnswerID,
				ANS.SendDate,
				ANS.SenderUserID,
				Q.NodeTypeID,
				Q.NodeType,
				Q.NodeID,
				Q.NodeName
		FROM Questions AS Q
			INNER JOIN [dbo].[QA_Answers] AS ANS
			ON ANS.ApplicationID = @ApplicationID AND ANS.QuestionID = Q.QuestionID AND
				(@DateFrom IS NULL OR ANS.SendDate >= @DateFrom) AND
				(@DateTo IS NULL OR ANS.SendDate < @DateTo) AND
				ANS.Deleted = 0
	)
	INSERT INTO @outputTable (QuestionID, AnswerID, SendDate, SenderUserID, NodeTypeID, NodeType, NodeID, NodeName)
	SELECT X.QuestionID, X.AnswerID, X.SendDate, X.SenderUserID, X.NodeTypeID, X.NodeType, X.NodeID, X.NodeName
	FROM (
			SELECT *
			FROM Questions AS Q
			WHERE (@DateFrom IS NULL OR Q.SendDate >= @DateFrom) AND
				(@DateTo IS NULL OR Q.SendDate < @DateTo)

			UNION ALL

			SELECT *
			FROM Answers
		) AS X

	RETURN
END

GO
