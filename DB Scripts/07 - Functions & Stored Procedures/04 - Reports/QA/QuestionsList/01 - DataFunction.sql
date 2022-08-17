USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[QA_FN_QuestionsListReport]') 
    AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[QA_FN_QuestionsListReport]
GO

CREATE FUNCTION [dbo].[QA_FN_QuestionsListReport](
	@ApplicationID	uniqueidentifier,
	@NodeTypeID		uniqueidentifier,
	@NodeID			uniqueidentifier,
	@DateFrom		datetime,
	@DateTo			datetime
)
RETURNS @outputTable TABLE (
	QuestionID		uniqueidentifier,
	QuestionTitle	nvarchar(max),
	SendDate		datetime,
	SenderUserID	uniqueidentifier,
	SenderFullName	nvarchar(max)
)
WITH ENCRYPTION
AS
BEGIN
	INSERT INTO @outputTable (QuestionID, QuestionTitle, SendDate, SenderUserID, SenderFullName)
	SELECT	Q.QuestionID,
			MAX(Q.Title) AS QuestionTitle,
			MAX(Q.SendDate) AS SendDate,
			CAST(MAX(CAST(Q.SenderUserID AS varchar(50))) AS uniqueidentifier) AS SenderUserID,
			MAX(LTRIM(RTRIM(ISNULL(USR.FirstName, N'') + N' ' + ISNULL(USR.LastName, N'')))) AS SenderFullName
	FROM [dbo].[QA_Questions] AS Q
		INNER JOIN [dbo].[USR_View_Users] AS USR
		ON USR.UserID = Q.SenderUserID
		LEFT JOIN [dbo].[QA_RelatedNodes] AS RN
		ON RN.ApplicationID = @ApplicationID AND RN.QuestionID = Q.QuestionID AND RN.Deleted = 0
		LEFT JOIN [dbo].[CN_View_Nodes_Normal] AS ND
		ON ND.NodeID = RN.NodeID AND 
			(@NodeID IS NULL OR ND.NodeID = @NodeID) AND
			(@NodeTypeID IS NULL OR ND.NodeTypeID = @NodeTypeID) AND ND.Deleted = 0
	WHERE Q.ApplicationID = @ApplicationID AND
		(@DateFrom IS NULL OR Q.SendDate >= @DateFrom) AND
		(@DateTo IS NULL OR Q.SendDate < @DateTo) AND
		(ISNULL(@NodeTypeID, @NodeID) IS NULL OR ND.NodeID IS NOT NULL)
	GROUP BY Q.QuestionID

	RETURN
END

GO
