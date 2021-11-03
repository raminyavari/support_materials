USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_NodeVisitDetailsReport_Chart]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_NodeVisitDetailsReport_Chart]
GO

CREATE PROCEDURE [dbo].[CN_NodeVisitDetailsReport_Chart]
	@ApplicationID			uniqueidentifier,
	@CurrentUserID			uniqueidentifier,
	@Period					varchar(50),
	@CalendarType			varchar(50),
	@PeriodList				BigIntTableType readonly,
	@NodeTypeID				uniqueidentifier,
	@NodeIDsTemp			GuidTableType readonly,
	@GrabSubNodeTypes		bit,
	@CreatorGroupIDsTemp	GuidTableType readonly,
	@CreatorUserIDsTemp		GuidTableType readonly,
	@DateFrom				datetime,
	@DateTo					datetime
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @NodeIDs GuidTableType
	INSERT INTO @NodeIDs (Value) SELECT Ref.Value FROM @NodeIDsTemp AS Ref

	DECLARE @CreatorGroupIDs GuidTableType
	INSERT INTO @CreatorGroupIDs (Value) SELECT Ref.Value FROM @CreatorGroupIDsTemp AS Ref

	DECLARE @CreatorUserIDs GuidTableType
	INSERT INTO @CreatorUserIDs (Value) SELECT Ref.Value FROM @CreatorUserIDsTemp AS Ref

	;WITH Content AS (
		SELECT X.*
		FROM [dbo].[CN_FN_NodeVisitDetailsReport](@ApplicationID, @CurrentUserID, @NodeTypeID, 
			@NodeIDs, @GrabSubNodeTypes, @CreatorGroupIDs, @CreatorUserIDs, @DateFrom, @DateTo) AS X
	)
	SELECT	P.[Value] AS [Period],
			COUNT(C.VisitedID) AS VisitsCount,
			COUNT(C.SearchID) AS SearchesCount
	FROM @PeriodList AS P
		LEFT JOIN Content AS C
		ON C.[Period] = P.[Value]
	GROUP BY P.[Value]
	ORDER BY P.[Value]
END

GO

