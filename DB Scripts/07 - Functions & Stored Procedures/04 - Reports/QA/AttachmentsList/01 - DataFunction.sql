USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[QA_FN_AttachmentsListReport]') 
    AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[QA_FN_AttachmentsListReport]
GO

CREATE FUNCTION [dbo].[QA_FN_AttachmentsListReport](
	@ApplicationID	uniqueidentifier,
	@NodeTypeID		uniqueidentifier,
	@NodeID			uniqueidentifier,
	@DateFrom		datetime,
	@DateTo			datetime
)
RETURNS @outputTable TABLE (
	QuestionID		uniqueidentifier,
	QuestionTitle	nvarchar(max),
	FileID			uniqueidentifier,
	[FileName]		nvarchar(max),
	Extension		nvarchar(max),
	Size			bigint,
	SendDate		datetime,
	SenderUserID	uniqueidentifier,
	SenderFullName	nvarchar(max),
	IsAnswer		bit
)
WITH ENCRYPTION
AS
BEGIN
	;WITH Questions AS (
		SELECT	Q.QuestionID,
				MAX(Q.Title) AS QuestionTitle,
				MAX(Q.SendDate) AS Senddate
		FROM [dbo].[QA_Questions] AS Q
			LEFT JOIN [dbo].[QA_RelatedNodes] AS RN
			ON RN.ApplicationID = @ApplicationID AND RN.QuestionID = Q.QuestionID AND RN.Deleted = 0
			LEFT JOIN [dbo].[CN_Nodes] AS ND
			ON ND.NodeID = RN.NodeID AND ND.Deleted = 0
		WHERE Q.ApplicationID = @ApplicationID AND
			(ISNULL(@NodeTypeID, @NodeID) IS NULL OR ND.NodeID IS NOT NULL)
		GROUP BY Q.QuestionID
	),
	Answers AS (
		SELECT	ANS.AnswerID,
				Q.QuestionID,
				Q.QuestionTitle,
				ANS.SendDate
		FROM Questions AS Q
			INNER JOIN [dbo].[QA_Answers] AS ANS
			ON ANS.ApplicationID = @ApplicationID AND ANS.QuestionID = Q.QuestionID AND ANS.Deleted = 0
	)
	INSERT INTO @outputTable (QuestionID, QuestionTitle, FileID, [FileName], Extension, Size, SendDate, SenderUserID, SenderFullName, IsAnswer)
	SELECT	X.QuestionID, X.QuestionTitle, F.FileNameGuid, F.[FileName], F.Extension, F.Size, F.CreationDate, U.UserID,
			LTRIM(RTRIM(ISNULL(U.FirstName, N'') + N' ' + ISNULL(U.LastName, N''))),
			CASE WHEN X.AnswerID IS NULL THEN 0 ELSE 1 END
	FROM (
			SELECT	Q.QuestionID,
					Q.QuestionTitle,
					NULL AS AnswerID,
					Q.QuestionID AS ID
			FROM Questions AS Q

			UNION ALL

			SELECT	A.QuestionID,
					A.QuestionTitle,
					A.AnswerID,
					A.AnswerID AS ID
			FROM Answers AS A
		) AS X
		INNER JOIN [dbo].[DCT_Files] AS F
		ON F.ApplicationID = @ApplicationID AND F.OwnerID = X.ID AND
			(@DateFrom IS NULL OR F.CreationDate >= @DateFrom) AND
			(@DateTo IS NULL OR F.CreationDate < @DateTo) AND F.Deleted = 0
		INNER JOIN [dbo].[USR_View_Users] AS U
		ON U.UserID = F.CreatorUserID

	RETURN
END

GO
