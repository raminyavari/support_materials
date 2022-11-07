USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MSG_FN_GetThreadUsers]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[MSG_FN_GetThreadUsers]
GO

CREATE FUNCTION [dbo].[MSG_FN_GetThreadUsers](
	@ApplicationID	uniqueidentifier,
    @ThreadIDsTemp	GuidTableType readonly
)	
RETURNS @OutputTable TABLE (
	SequenceNumber	bigint,
	ThreadID		uniqueidentifier,
	UserID			uniqueidentifier
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @ThreadIDs GuidTableType
	INSERT INTO @ThreadIDs SELECT * FROM @ThreadIDsTemp

	;WITH LastIDs AS (
		SELECT MD.ThreadID, MAX(MD.ID) AS LastMessageID
		FROM @ThreadIDs AS T
			INNER JOIN [dbo].[MSG_MessageDetails] AS MD
			ON MD.ApplicationID = @ApplicationID AND MD.ThreadID = T.Value
		GROUP BY MD.ThreadID
	),
	MessageIDs AS (
		SELECT MD.ThreadID, MD.MessageID
		FROM LastIDs AS L
			INNER JOIN [dbo].[MSG_MessageDetails] AS MD
			ON MD.ApplicationID = @ApplicationID AND MD.ID = L.LastMessageID
	)
	INSERT INTO @OutputTable (SequenceNumber, ThreadID, UserID)
	SELECT  ROW_NUMBER() OVER (PARTITION BY MD.ThreadID ORDER BY MD.ID DESC, MD.UserID DESC) AS RowNumber,
			MD.ThreadID, 
			MD.UserID
	FROM MessageIDs AS M
		INNER JOIN [dbo].[MSG_MessageDetails] AS MD
		ON MD.ThreadID = M.ThreadID AND MD.MessageID = M.MessageID
	WHERE MD.ApplicationID = @ApplicationID

	RETURN
END

GO


