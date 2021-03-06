USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[TMP_CreateWiki]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[TMP_CreateWiki]
GO

CREATE PROCEDURE [dbo].[TMP_CreateWiki]
    @KID 		uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @KTypeID int = (SELECT TOP(1) KnowledgeTypeID FROM [dbo].[KW_Knowledges] WHERE KnowledgeID = @KID)
	DECLARE @CreatorUserID uniqueidentifier = (SELECT TOP(1) CreatorUserID 
		FROM [dbo].[CN_Nodes]WHERE NodeID = @KID)
		DECLARE @CreationDate datetime = (SELECT TOP(1) CreationDate
		FROM [dbo].[CN_Nodes]WHERE NodeID = @KID)
	DECLARE @TitleID uniqueidentifier
	DECLARE @LastTitleSequence int = 1
	DECLARE @LastParagraphSequence int = 1
	
	IF @KTypeID = 2 BEGIN
		DECLARE @PracticalLevel int, @TheoricalLevel int,
			@strPractical nvarchar(1000), @strTheorical nvarchar(1000)
		
		SELECT TOP(1) @PracticalLevel = PracticalLevelID, @TheoricalLevel = TheoricalLevelID
		FROM [dbo].[KW_KnowledgeAssets]
		WHERE KnowledgeID = @KID
		
		SET @strPractical = (SELECT TOP(1) Name FROM [dbo].[KW_SkillLevels] 
			WHERE LevelID = @PracticalLevel)
		SET @strTheorical = (SELECT TOP(1) Name FROM [dbo].[KW_SkillLevels] 
			WHERE LevelID = @TheoricalLevel)
			
		IF @PracticalLevel IS NOT NULL OR @TheoricalLevel IS NOT NULL BEGIN
			SET @TitleID = NEWID()
		
			INSERT INTO [dbo].[WK_Titles](TitleID, OwnerID, CreatorUserID, CreationDate,
				SequenceNo, Title, [Status], OwnerType, Deleted)
			VALUES(@TitleID, @KID, @CreatorUserID, @CreationDate, @LastTitleSequence,
				N'سطح تخصص', N'Accepted', N'Node', 0)
				
			SET @LastTitleSequence += 1
			
			DECLARE @StrLevel nvarchar(2000)
			IF @TheoricalLevel IS NOT NULL 
				SET @StrLevel = ISNULL(@StrLevel, N'') + N'<div>' + N'تئوری' + N': ' + ISNULL(@strTheorical, N'') + N'</div>'
			IF @PracticalLevel IS NOT NULL 
				SET @StrLevel = ISNULL(@StrLevel, N'') + N'<div>' + N'عملی' + N': ' + ISNULL(@strPractical, N'') + N'</div>'
				
			INSERT INTO [dbo].[WK_Paragraphs](ParagraphID, TitleID, CreatorUserID, 
				CreationDate, SequenceNo, Title, BodyText, IsRichText, [Status], Deleted)
			VALUES(NEWID(), @TitleID, @CreatorUserID, @CreationDate, @LastParagraphSequence,
				NULL, ISNULL(@StrLevel, N''), 1, N'Accepted', 0)
				
			SET @LastParagraphSequence += 1
		END
	END
	
	DECLARE @Usage nvarchar(max) = (SELECT TOP(1) Usage FROM [dbo].[KW_Knowledges] WHERE KnowledgeID = @KID)
	IF @Usage IS NOT NULL AND @Usage <> N'' BEGIN
		SET @TitleID = NEWID()
		
		INSERT INTO [dbo].[WK_Titles](TitleID, OwnerID, CreatorUserID, CreationDate,
			SequenceNo, Title, [Status], OwnerType, Deleted)
		VALUES(@TitleID, @KID, @CreatorUserID, @CreationDate, @LastTitleSequence,
			N'کاربردها', N'Accepted', N'Node', 0)
			
		SET @LastTitleSequence += 1
			
		INSERT INTO [dbo].[WK_Paragraphs](ParagraphID, TitleID, CreatorUserID, CreationDate,
			SequenceNo, Title, BodyText, IsRichText, [Status], Deleted)
		VALUES(NEWID(), @TitleID, @CreatorUserID, @CreationDate, @LastParagraphSequence,
			NULL, ISNULL(@Usage, N''), 1, N'Accepted', 0)
			
		SET @LastParagraphSequence += 1
	END
	
	IF @KTypeID BETWEEN 1 AND 2 BEGIN
		DECLARE @WorkshopMethod nvarchar(max) = (SELECT TOP(1) [Description]
			FROM [dbo].[KW_LearningMethods] WHERE KnowledgeID = @KID AND Title = N'EducationalWorkshops')
		DECLARE @IndividuaMethod nvarchar(max) = (SELECT TOP(1) [Description]
			FROM [dbo].[KW_LearningMethods] WHERE KnowledgeID = @KID AND Title = N'IndividualStudying')
		DECLARE @ActivitiesMethod nvarchar(max) = (SELECT TOP(1) [Description]
			FROM [dbo].[KW_LearningMethods] WHERE KnowledgeID = @KID AND Title = N'WorkingActivities')
		DECLARE @OtherMethod nvarchar(max) = (SELECT TOP(1) [Description]
			FROM [dbo].[KW_LearningMethods] WHERE KnowledgeID = @KID AND Title = N'Other')
		DECLARE @CoworkerMethod nvarchar(max)
		
		-- fill coworker method
		DECLARE @RefUsers Table (ID int IDENTITY(1,1) primary key clustered, 
			UserID uniqueidentifier, FullName nvarchar(max))
			
		INSERT INTO @RefUsers(UserID, FullName)
		SELECT UN.UserID, LTRIM(RTRIM(ISNULL(UN.FirstName, N'') + N' ' + ISNULL(UN.LastName, N'')))
		FROM [dbo].[KW_RefrenceUsers] AS RU
			INNER JOIN [dbo].[USR_Profile] AS UN
			ON RU.UserID = UN.UserID
		WHERE RU.KnowledgeID = @KID
		
		DECLARE @RUCount int = (SELECT COUNT(*) FROM @RefUsers)
		DECLARE @RUIter int = 1
		
		IF @RUCount > 0 BEGIN
			
			SELECT @CoworkerMethod = N'<div style="clear:both;">' + LTRIM(RTRIM(STUFF(
					(
						SELECT N' <div> @[[' + LOWER(CAST(UserID AS varchar(100))) + N':User:' + 
							ISNULL(FullName, N'') + N']] </div>'
						FROM @RefUsers
						FOR xml path('a'), type
					).value('.','nvarchar(max)'),
					1,
					1,
					''
				))) + N'</div>'
		END
		-- end of fill coworker method
			
		IF @WorkshopMethod IS NOT NULL AND @WorkshopMethod <> N'' AND
			@IndividuaMethod IS NOT NULL AND @IndividuaMethod <> N'' AND
			@ActivitiesMethod IS NOT NULL AND @ActivitiesMethod <> N'' AND
			@OtherMethod IS NOT NULL AND @OtherMethod <> N'' AND
			@CoworkerMethod IS NOT NULL AND @CoworkerMethod <> N'' BEGIN
			
			DECLARE @WorkShopTitle nvarchar(200) = 
				CASE WHEN @KTypeID = 1 THEN N'بازنگری پس از اقدام (AAR)' ELSE N'یادگیری از طریق دوره های آموزشی' END
			DECLARE @IndividualTitle nvarchar(200) = 
				CASE WHEN @KTypeID = 1 THEN N'بازنگری پس از پروژه (PPR)' ELSE N'یادگیری از طریق تمرین و مطالعه شخصی' END
			DECLARE @ActivitiesTitle nvarchar(200) = 
				CASE WHEN @KTypeID = 1 THEN N'تجربه شخصی ناشی از تصمیم گیری / سعی و خطا / حل مساله' ELSE N'یادگیری از طریق فعالیت های کاری' END
			DECLARE @OtherTitle nvarchar(200) = 
				CASE WHEN @KTypeID = 1 THEN N'اکتساب دانش (Knowledge Acquisition)' ELSE N'یادگیری از روش های دیگر' END	
			DECLARE @CoworkerTitle nvarchar(200) = 
				CASE WHEN @KTypeID = 1 THEN N'مساعدت همکاران (Peer Assist/Review)' ELSE N'یادگیری از همکاران' END	
			
			SET @TitleID = NEWID()
			
			INSERT INTO [dbo].[WK_Titles](TitleID, OwnerID, CreatorUserID, CreationDate,
				SequenceNo, Title, [Status], OwnerType, Deleted)
			VALUES(@TitleID, @KID, @CreatorUserID, @CreationDate, @LastTitleSequence,
				N'روش یادگیری', N'Accepted', N'Node', 0)
			
			SET @LastTitleSequence += 1
			
			IF @WorkshopMethod IS NOT NULL AND @WorkshopMethod <> N'' BEGIN
				INSERT INTO [dbo].[WK_Paragraphs](ParagraphID, TitleID, CreatorUserID, 
					CreationDate, SequenceNo, Title, BodyText, IsRichText, [Status], Deleted)
				VALUES(NEWID(), @TitleID, @CreatorUserID, @CreationDate, @LastParagraphSequence,
					@WorkShopTitle, ISNULL(@WorkshopMethod, N''), 1, N'Accepted', 0)
					
				SET @LastParagraphSequence += 1
			END
			
			IF @IndividuaMethod IS NOT NULL AND @IndividuaMethod <> N'' BEGIN
				INSERT INTO [dbo].[WK_Paragraphs](ParagraphID, TitleID, CreatorUserID, 
					CreationDate, SequenceNo, Title, BodyText, IsRichText, [Status], Deleted)
				VALUES(NEWID(), @TitleID, @CreatorUserID, @CreationDate, @LastParagraphSequence,
					@IndividualTitle, ISNULL(@IndividuaMethod, N''), 1, N'Accepted', 0)
					
				SET @LastParagraphSequence += 1
			END
			
			IF @CoworkerMethod IS NOT NULL AND @CoworkerMethod <> N'' BEGIN
				INSERT INTO [dbo].[WK_Paragraphs](ParagraphID, TitleID, CreatorUserID, 
					CreationDate, SequenceNo, Title, BodyText, IsRichText, [Status], Deleted)
				VALUES(NEWID(), @TitleID, @CreatorUserID, @CreationDate, @LastParagraphSequence,
					@CoworkerTitle, ISNULL(@CoworkerMethod, N''), 1, N'Accepted', 0)
					
				SET @LastParagraphSequence += 1
			END
			
			IF @ActivitiesMethod IS NOT NULL AND @ActivitiesMethod <> N'' BEGIN
				INSERT INTO [dbo].[WK_Paragraphs](ParagraphID, TitleID, CreatorUserID, 
					CreationDate, SequenceNo, Title, BodyText, IsRichText, [Status], Deleted)
				VALUES(NEWID(), @TitleID, @CreatorUserID, @CreationDate, @LastParagraphSequence,
					@ActivitiesTitle, ISNULL(@ActivitiesMethod, N''), 1, N'Accepted', 0)
					
				SET @LastParagraphSequence += 1
			END
			
			IF @OtherMethod IS NOT NULL AND @OtherMethod <> N'' BEGIN
				INSERT INTO [dbo].[WK_Paragraphs](ParagraphID, TitleID, CreatorUserID, 
					CreationDate, SequenceNo, Title, BodyText, IsRichText, [Status], Deleted)
				VALUES(NEWID(), @TitleID, @CreatorUserID, @CreationDate, @LastParagraphSequence,
					@OtherTitle, ISNULL(@OtherMethod, N''), 1, N'Accepted', 0)
					
				SET @LastParagraphSequence += 1
			END
		END
	END -- end of 'IF @KTypeID BETWEEN 1 AND 2 BEGIN' : Learning Methods
	
	IF @KTypeID = 3 AND EXISTS(SELECT TOP(1) * FROM [dbo].[KW_TripForms] 
		WHERE KnowledgeID = @KID) BEGIN
		
		DECLARE @TripBegin datetime, @TripFinish datetime,
			@TripCountry nvarchar(1000), @TripCity nvarchar(1000),
			@TripResults nvarchar(4000), @TripChalenges nvarchar(4000)
		
		SELECT @TripBegin = BeginDate, @TripFinish = FinishDate,
			@TripCountry = Country, @TripCity = City,
			@TripResults = Results, @TripChalenges = Chalenges
		FROM [dbo].[KW_TripForms]
		WHERE KnowledgeID = @KID
		
		SET @TitleID = NEWID()
			
		INSERT INTO [dbo].[WK_Titles](TitleID, OwnerID, CreatorUserID, CreationDate,
			SequenceNo, Title, [Status], OwnerType, Deleted)
		VALUES(@TitleID, @KID, @CreatorUserID, @CreationDate, @LastTitleSequence,
			N'گزارش سفر', N'Accepted', N'Node', 0)
		
		SET @LastTitleSequence += 1
		
		IF @TripBegin IS NOT NULL OR @TripFinish IS NOT NULL BEGIN
			DECLARE @TripDate nvarchar(2000)
			IF @TripBegin IS NOT NULL SET @TripDate = @TripDate + N'<div>' + N'تاریخ شروع' + 
				N': ' + CAST(@TripBegin as nvarchar(100)) + N'</div>'
			IF @TripFinish IS NOT NULL SET @TripDate = @TripDate + N'<div>' + N'تاریخ پایان' + 
				N': ' + CAST(@TripFinish as nvarchar(100)) + N'</div>'
				
			INSERT INTO [dbo].[WK_Paragraphs](ParagraphID, TitleID, CreatorUserID, 
				CreationDate, SequenceNo, Title, BodyText, IsRichText, [Status], Deleted)
			VALUES(NEWID(), @TitleID, @CreatorUserID, @CreationDate, @LastParagraphSequence,
				N'تاریخ سفر', ISNULL(@TripDate, N''), 1, N'Accepted', 0)
				
			SET @LastParagraphSequence += 1
		END
		
		IF @TripCountry IS NOT NULL OR @TripCity IS NOT NULL BEGIN
			DECLARE @TripLoc nvarchar(2000)
			IF @TripCountry IS NOT NULL SET @TripLoc = @TripLoc + N'<div>' + N'کشور' + 
				N': ' + CAST(@TripCountry as nvarchar(100)) + N'</div>'
			IF @TripCity IS NOT NULL SET @TripLoc = @TripLoc + N'<div>' + N'شهر' + 
				N': ' + CAST(@TripLoc as nvarchar(100)) + N'</div>'
				
			INSERT INTO [dbo].[WK_Paragraphs](ParagraphID, TitleID, CreatorUserID, 
				CreationDate, SequenceNo, Title, BodyText, IsRichText, [Status], Deleted)
			VALUES(NEWID(), @TitleID, @CreatorUserID, @CreationDate, @LastParagraphSequence,
				N'محل سفر', ISNULL(@TripLoc, N''), 1, N'Accepted', 0)
				
			SET @LastParagraphSequence += 1
		END
		
		IF @TripResults IS NOT NULL AND @TripResults <> N'' BEGIN
			INSERT INTO [dbo].[WK_Paragraphs](ParagraphID, TitleID, CreatorUserID, 
				CreationDate, SequenceNo, Title, BodyText, IsRichText, [Status], Deleted)
			VALUES(NEWID(), @TitleID, @CreatorUserID, @CreationDate, @LastParagraphSequence,
				N'دستاوردها', ISNULL(@TripResults, N''), 1, N'Accepted', 0)
				
			SET @LastParagraphSequence += 1
		END
		
		IF @TripChalenges IS NOT NULL AND @TripChalenges <> N'' BEGIN
			INSERT INTO [dbo].[WK_Paragraphs](ParagraphID, TitleID, CreatorUserID, 
				CreationDate, SequenceNo, Title, BodyText, IsRichText, [Status], Deleted)
			VALUES(NEWID(), @TitleID, @CreatorUserID, @CreationDate, @LastParagraphSequence,
				N'چالش ها', ISNULL(@TripChalenges, N''), 1, N'Accepted', 0)
				
			SET @LastParagraphSequence += 1
		END
		
		IF EXISTS(SELECT TOP(1) * FROM [dbo].[KW_Companies] 
			WHERE KnowledgeID = @KID AND Title IS NOT NULL AND Title <> N'') BEGIN
			
			DECLARE @TripCompanies nvarchar(max)
			
			SELECT @TripCompanies = N'<div style="clear:both;">' + STUFF(
					(
						SELECT top(2) N' <div style="margin-bottom:10px;">' +
							'<div style="margin-bottom:4px; font-weight:bold;">' + Title + N'</div>' + 
							'<div>' + N'محصولات' + N': ' + Products + N'</div>' + 
							N'</div>'
						FROM [dbo].[KW_Companies]
						WHERE KnowledgeID = @KID AND Title IS NOT NULL AND Title <> N''
						FOR xml path('a'), type
					).value('.','nvarchar(max)'),
					1,
					1,
					''
				) + N'</div>'
				
			INSERT INTO [dbo].[WK_Paragraphs](ParagraphID, TitleID, CreatorUserID, 
				CreationDate, SequenceNo, Title, BodyText, IsRichText, [Status], Deleted)
			VALUES(NEWID(), @TitleID, @CreatorUserID, @CreationDate, @LastParagraphSequence,
				N'شرکت ها و کارخانه های مورد بازدید', ISNULL(@TripCompanies, N''), 1, N'Accepted', 0)
				
			SET @LastParagraphSequence += 1
		END
	END
END

GO


DECLARE @KWS Table(ID bigint IDENTITY(1,1) primary key clustered, KnowledgeID uniqueidentifier)

INSERT INTO @KWS (KnowledgeID)
SELECT KnowledgeID
FROM [dbo].[KW_Knowledges]

DECLARE @Count int = (SELECT COUNT(*) FROM @KWS)
DECLARE @iter int = 1

WHILE @iter <=  @Count  BEGIN
	DECLARE @KID uniqueidentifier = (SELECT TOP(1) KnowledgeID FROM @KWS WHERE ID = @iter)
	
	EXEC [dbo].[TMP_CreateWiki] @KID
	
	SET @iter = @iter + 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[TMP_CreateWiki]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[TMP_CreateWiki]
GO


/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

DECLARE @PropertyID uniqueidentifier = [dbo].[CN_FN_GetRelatedRelationTypeID]()


INSERT INTO [dbo].[CN_NodeRelations](SourceNodeID, DestinationNodeID, PropertyID, Deleted)
SELECT KnowledgeID, NodeID, @PropertyID, ISNULL(Deleted, 0)
FROM [dbo].[KW_RelatedNodes] AS RN
WHERE NOT EXISTS(
		SELECT TOP(1) *
		FROM [dbo].[CN_NodeRelations] AS NR
		WHERE NR.SourceNodeID = RN.KnowledgeID AND DestinationNodeID = RN.NodeID AND
			NR.PropertyID = @PropertyID
	)

GO

/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[TMP_KW_FeedBacks](
	[FeedBackID] [bigint] IDENTITY(1,1) NOT NULL,
	[KnowledgeID] [uniqueidentifier] NOT NULL,
	[UserID] [uniqueidentifier] NOT NULL,
	[FeedBackTypeID] [int] NOT NULL,
	[SendDate] [datetime] NOT NULL,
	[Value] [float] NOT NULL,
	[Description] [nvarchar](2000) NULL,
	[Deleted] [bit] NOT NULL,
 CONSTRAINT [PK_TMP_KW_FeedBacks] PRIMARY KEY CLUSTERED 
(
	[FeedBackID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[TMP_KW_FeedBacks]  WITH CHECK ADD  CONSTRAINT [FK_TMP_KW_FeedBacks_aspnet_Users] FOREIGN KEY([UserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[TMP_KW_FeedBacks] CHECK CONSTRAINT [FK_TMP_KW_FeedBacks_aspnet_Users]
GO

ALTER TABLE [dbo].[TMP_KW_FeedBacks]  WITH CHECK ADD  CONSTRAINT [FK_TMP_KW_FeedBacks_CN_Nodes] FOREIGN KEY([KnowledgeID])
REFERENCES [dbo].[CN_Nodes] ([NodeID])
GO

ALTER TABLE [dbo].[TMP_KW_FeedBacks] CHECK CONSTRAINT [FK_TMP_KW_FeedBacks_CN_Nodes]
GO



/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

INSERT INTO [dbo].[TMP_KW_FeedBacks] (KnowledgeID, UserID, FeedBackTypeID, 
	SendDate, Value, [Description], Deleted)
SELECT KnowledgeID, UserID, FeedBackTypeID, SendDate, Value, [Description], Deleted
FROM [dbo].[KW_FeedBacks]

GO


DECLARE @Evs Table(ID int IDENTITY(1,1) primary key clustered, 
	UserID uniqueidentifier, KnowledgeID uniqueidentifier, Score float, DT datetime)

INSERT INTO @Evs(UserID, KnowledgeID, Score, DT)
SELECT	E.UserID,
		E.KnowledgeID,
		CAST(ISNULL(SUM(E.Score), 0) AS float) / 
			CAST(ISNULL(COUNT(E.Score), 1) AS float) AS Score,
		MAX(E.EvaluationDate) AS DT
FROM (	
		SELECT Ev.KnowledgeID, Ev.UserID, Ev.Score, Ev.EvaluationDate
		FROM [dbo].[KWF_Evaluators] AS Ev
		WHERE Ev.Deleted = 0 AND Ev.Score IS NOT NULL AND Ev.Score > 0

		UNION ALL

		SELECT Ex.KnowledgeID, Ex.UserID, Ex.Score, Ex.EvaluationDate
		FROM [dbo].[KWF_Experts] AS Ex
		WHERE Ex.Deleted = 0 AND Ex.Score IS NOT NULL AND Ex.Score > 0
	) AS E
GROUP BY E.UserID, E.KnowledgeID


INSERT INTO [dbo].[TMP_KW_QuestionAnswers](
	KnowledgeID,
	UserID,
	QuestionID,
	Title,
	Score,
	ResponderUserID,
	EvaluationDate,
	Deleted
)
SELECT DISTINCT	
		E.KnowledgeID,
		E.UserID,
		TQ.QuestionID,
		Q.Title,
		E.Score,
		E.UserID,
		E.DT,
		0
FROM @Evs AS E
	INNER JOIN [dbo].[CN_Nodes] AS ND
	ON ND.NodeID = E.KnowledgeID
	INNER JOIN [dbo].[TMP_KW_TypeQuestions] AS TQ
	ON TQ.KnowledgeTypeID = ND.NodeTypeID
	INNER JOIN [dbo].[TMP_KW_Questions] AS Q
	ON TQ.QuestionID = Q.QuestionID
	
	
DECLARE @Count int = (SELECT MAX(ID) FROM @Evs)

WHILE @Count > 0 BEGIN
	DECLARE @KID uniqueidentifier = 
		(SELECT TOP(1) E.KnowledgeID FROM @Evs AS E WHERE E.ID = @Count)
	
	DECLARE @Score float = (
		SELECT TOP(1) (SUM(Ref.Score) / ISNULL(COUNT(Ref.UserID), 1)) AS S
		FROM (
				SELECT	QA.UserID, 
						SUM(ISNULL(QA.Score, 0)) / ISNULL(COUNT(QA.QuestionID), 1) AS Score
				FROM [dbo].[TMP_KW_QuestionAnswers] AS QA
				WHERE QA.KnowledgeID = @KID AND QA.Deleted = 0
				GROUP BY QA.UserID
			) AS Ref
		GROUP BY Ref.UserID
	)
	
	UPDATE [dbo].[CN_Nodes]
		SET Score = @Score
	WHERE NodeID = @KID
	
	SET @Count = @Count - 1
END

GO


IF EXISTS(select * FROM sys.views where name = 'KW_View_ContentFileExtensions')
DROP VIEW [dbo].[KW_View_ContentFileExtensions]
GO

IF EXISTS(select * FROM sys.views where name = 'KW_View_Knowledges')
DROP VIEW [dbo].[KW_View_Knowledges]
GO

CREATE VIEW [dbo].[KW_View_Knowledges] WITH SCHEMABINDING, ENCRYPTION
AS
SELECT     dbo.KW_Knowledges.KnowledgeID, dbo.KW_Knowledges.KnowledgeTypeID,
		   dbo.KW_KnowledgeTypes.Name AS KnowledgeType, 
		   dbo.CN_Nodes.AdditionalID AS AdditionalID,
		   dbo.KW_Knowledges.PreviousVersionID,
		   dbo.KW_Knowledges.ContentType, dbo.KW_Knowledges.IsDefault, 
           dbo.KW_Knowledges.ExtendedFormID, dbo.KW_Knowledges.TreeNodeID, 
           dbo.KW_Knowledges.ConfidentialityLevelID, dbo.KW_Knowledges.StatusID, 
           dbo.KW_Knowledges.PublicationDate, dbo.CN_Nodes.Name AS Title, 
           dbo.CN_Nodes.CreatorUserID, dbo.CN_Nodes.LastModifierUserID, 
           dbo.CN_Nodes.CreationDate, dbo.CN_Nodes.LastModificationDate, 
           dbo.KW_Knowledges.Score, dbo.KW_Knowledges.ScoresWeight,
           dbo.CN_Nodes.Privacy, dbo.CN_Nodes.Deleted
FROM       dbo.CN_Nodes INNER JOIN dbo.KW_Knowledges ON 
		   dbo.CN_Nodes.NodeID = dbo.KW_Knowledges.KnowledgeID INNER JOIN
		   dbo.KW_KnowledgeTypes ON 
		   dbo.KW_Knowledges.KnowledgeTypeID = dbo.KW_KnowledgeTypes.KnowledgeTypeID

GO



CREATE TYPE [dbo].[TMPDashboardTableType] AS TABLE(
	UserID			uniqueidentifier NOT NULL,
	NodeID			uniqueidentifier NOT NULL,
	RefItemID		uniqueidentifier NULL,
	[Type]			varchar(20) NOT NULL,
	SubType			varchar(20) NULL,
	Info			nvarchar(max) NULL,
	Removable		bit	NULL,
	SenderUserID	uniqueidentifier NULL,
	SendDate		datetime NULL,
	ExpirationDate	datetime NULL,
	Seen			bit NULL,
	ViewDate		datetime NULL,
	Done			bit NULL,
	ActionDate		datetime NULL
)
GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[NTFN_P_SendDashboards]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[NTFN_P_SendDashboards]
GO

CREATE PROCEDURE [dbo].[NTFN_P_SendDashboards]
    @Dashboards		TMPDashboardTableType readonly,
    @_Result		int output
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	INSERT INTO [dbo].[NTFN_Dashboards](
		UserID,
		NodeID,
		RefItemID,
		[Type],
		SubType,
		Info,
		Removable,
		SenderUserID,
		SendDate,
		ExpirationDate,
		Seen,
		ViewDate,
		Done,
		ActionDate,
		Deleted
	)
	SELECT DISTINCT
		Ref.UserID,
		Ref.NodeID,
		ISNULL(Ref.RefItemID, Ref.NodeID),
		Ref.[Type],
		Ref.SubType,
		ref.Info,
		ISNULL(Ref.Removable, 0),
		Ref.SenderUserID,
		Ref.SendDate,
		Ref.ExpirationDate,
		ISNULL(Ref.Seen, 0),
		Ref.ViewDate,
		ISNULL(Ref.Done, 0),
		Ref.ActionDate,
		0
	FROM @Dashboards AS Ref
	/*
		LEFT JOIN [dbo].[NTFN_Dashboards] AS D
		ON D.UserID = Ref.UserID AND D.NodeID = Ref.NodeID AND 
			D.RefItemID = Ref.RefItemID AND D.[Type] = Ref.[Type] AND
			((D.SubType IS NULL AND Ref.SubType IS NULL) OR D.SubType = Ref.SubType) AND
			D.Done = 0 AND D.Deleted = 0
	WHERE D.ID IS NULL
	*/
	
	SET @_Result = @@ROWCOUNT
END

GO


DECLARE @Dashboards TMPDashboardTableType

INSERT INTO [dbo].[NTFN_Dashboards](
	UserID, 
	NodeID, 
	RefItemID, 
	[Type], 
	SubType, 
	SendDate,
	ExpirationDate,
	ViewDate,
	Done,
	ActionDate,
	Seen,
	Removable, 
	Deleted
)
SELECT Ref.*
FROM (
		SELECT	MNG.UserID AS UserID,
				MNG.KnowledgeID AS NodeID,
				MNG.KnowledgeID AS RefItemID,
				N'Knowledge' AS [Type],
				N'Admin' AS SubType,
				MNG.EntranceDate AS SendDate,
				NULL AS ExpirationDate,
				NULL AS ViewDate,
				MNG.[Sent] AS Done,
				MNG.EvaluationDate AS ActionDate,
				1 AS Seen,
				0 AS Removable,
				0 AS Deleted
		FROM [dbo].[KWF_Managers] AS MNG
			INNER JOIN [dbo].[KW_View_Knowledges] AS KW
			ON MNG.[KnowledgeID] = KW.[KnowledgeID]
		WHERE MNG.[Deleted] = 0 AND 
			KW.[StatusID] < 5 AND KW.[Deleted] = 0
			
		UNION ALL
		
		SELECT	Ev.UserID AS UserID,
				Ev.KnowledgeID AS NodeID,
				Ev.KnowledgeID AS RefItemID,
				N'Knowledge' AS [Type],
				N'Evaluator' AS SubType,
				MAX(Ev.EntranceDate) AS SendDate,
				NULL AS ExpirationDate,
				NULL AS ViewDate,
				MAX(CAST(Ev.[Evaluated] AS int)) AS Done,
				MAX(Ev.EvaluationDate) AS ActionDate,
				1 AS Seen,
				0 AS Removable,
				0 AS Deleted
		FROM (
				SELECT	Ex.UserID, Ex.KnowledgeID, Ex.EntranceDate, Ex.ExpirationDate, 
						Ex.Evaluated, Ex.EvaluationDate, 1 AS IsEx
				FROM [dbo].[KWF_Experts] AS Ex
					INNER JOIN [dbo].[KW_View_Knowledges] AS KW
					ON Ex.[KnowledgeID] = KW.[KnowledgeID]
				WHERE Ex.[Deleted] = 0 AND
					(Ex.[Rejected] IS NULL OR Ex.[Rejected] = 0) AND KW.[Deleted] = 0
					
				UNION ALL
				
				SELECT	Ev.UserID, Ev.KnowledgeID, Ev.EntranceDate, Ev.ExpirationDate, 
						Ev.Evaluated, Ev.EvaluationDate, 0 AS IsEx
				FROM [dbo].[KWF_Evaluators] AS Ev
					INNER JOIN [dbo].[KW_View_Knowledges] AS KW
					ON Ev.[KnowledgeID] = KW.[KnowledgeID]
				WHERE Ev.[Deleted] = 0 AND
					(Ev.[Rejected] IS NULL OR Ev.[Rejected] = 0) AND KW.[Deleted] = 0
			) AS Ev
		GROUP BY Ev.UserID, Ev.KnowledgeID
	) AS Ref

DECLARE @_Result int

EXEC [dbo].[NTFN_P_SendDashboards] @Dashboards, @_Result output

GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[NTFN_P_SendDashboards]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[NTFN_P_SendDashboards]
GO

DROP TYPE dbo.TMPDashboardTableType
GO

IF EXISTS(select * FROM sys.views where name = 'KW_View_Knowledges')
DROP VIEW [dbo].[KW_View_Knowledges]
GO


INSERT INTO [dbo].[TMP_KW_History](
	KnowledgeID,
	[Action],
	ActorUserID,
	ActionDate
)
SELECT *
FROM (
		SELECT	MNG.KnowledgeID,
				N'SendToAdmin' AS [Action],
				ND.CreatorUserID AS ActorUserID,
				MNG.EntranceDate AS ActionDate
		FROM [dbo].[KWF_Managers] AS MNG
			INNER JOIN [dbo].[CN_Nodes] AS ND
			ON ND.NodeID = MNG.KnowledgeID
			
		UNION ALL
		
		SELECT	MNG.KnowledgeID,
				N'SendToEvaluators' AS [Action],
				MNG.UserID AS ActorUserID,
				MIN(MNG.EvaluationDate) AS ActionDate
		FROM [dbo].[KWF_Managers] AS MNG
		WHERE MNG.[Sent] = 1 AND MNG.EvaluationDate IS NOT NULL
		GROUP BY MNG.KnowledgeID, MNG.UserID
		
		UNION ALL
		
		SELECT	E.KnowledgeID,
				N'Evaluation' AS [Action],
				E.UserID AS ActorUserID,
				MIN(E.EvaluationDate) AS ActionDate
		FROM (
				SELECT Ex.KnowledgeID, Ex.UserID, Ex.EvaluationDate
				FROM [dbo].[KWF_Experts] AS Ex
				WHERE Ex.Evaluated = 1 AND ISNULL(Ex.Score, 0) > 0
				
				UNION ALL
				
				SELECT Ev.KnowledgeID, Ev.UserID, Ev.EvaluationDate
				FROM [dbo].[KWF_Evaluators] AS Ev
				WHERE Ev.Evaluated = 1 AND ISNULL(Ev.Score, 0) > 0
			) AS E
		GROUP BY E.KnowledgeID, E.UserID
	) AS Ref
ORDER BY Ref.ActionDate ASC

GO

