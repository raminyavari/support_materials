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