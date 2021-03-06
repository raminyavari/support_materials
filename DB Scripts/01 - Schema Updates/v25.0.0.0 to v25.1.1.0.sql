USE [EKM_App]
GO

CREATE TABLE [dbo].[USR_LanguageNames](
	LanguageID		UNIQUEIDENTIFIER NOT NULL,
	AdditionalID	NVARCHAR(50) NULL,
	LanguageName	NVARCHAR(500) NOT NULL
	
	CONSTRAINT [PK_USR_LanguageID] PRIMARY KEY CLUSTERED
	(
		LanguageID ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


CREATE TABLE [dbo].[USR_UserLanguages](
	ID				UNIQUEIDENTIFIER NOT NULL,
	AdditionalID	NVARCHAR(50) NULL,
	LanguageID		UNIQUEIDENTIFIER NOT NULL,
	UserID			UNIQUEIDENTIFIER NOT NULL,
	[Level]			VARCHAR(50) NOT NULL,
	CreatorUserID	UNIQUEIDENTIFIER NOT NULL,
	CreationDate	DATETIME NOT NULL,
	Deleted			BIT NOT NULL
	
	CONSTRAINT [PK_USR_UserLanguages] PRIMARY KEY CLUSTERED
	(
		[ID] ASC 
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


ALTER TABLE [dbo].[USR_UserLanguages]  WITH CHECK ADD  CONSTRAINT [FK_USR_UserLanguages_aspnet_Users] FOREIGN KEY([UserID])
REFERENCES [dbo].[aspnet_Users] ([UserID])
GO

ALTER TABLE [dbo].[USR_UserLanguages] CHECK CONSTRAINT [FK_USR_UserLanguages_aspnet_Users]
GO


ALTER TABLE [dbo].[USR_UserLanguages]  WITH CHECK ADD  CONSTRAINT [FK_USR_UserLanguages_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserID])
GO

ALTER TABLE [dbo].[USR_UserLanguages] CHECK CONSTRAINT [FK_USR_UserLanguages_aspnet_Users_Creator]
GO


ALTER TABLE [dbo].[USR_UserLanguages]  WITH CHECK ADD  CONSTRAINT [FK_USR_UserLanguages_USR_LanguageNames] FOREIGN KEY([LanguageID])
REFERENCES [dbo].[USR_LanguageNames] ([LanguageID])
GO

ALTER TABLE [dbo].[USR_UserLanguages] CHECK CONSTRAINT [FK_USR_UserLanguages_USR_LanguageNames]
GO


-- create new table
CREATE TABLE [dbo].[USR_JobExperiences](
	JobID			UNIQUEIDENTIFIER NOT NULL,
	AdditionalID	NVARCHAR(50) NULL,
	UserID			UNIQUEIDENTIFIER NOT NULL,
	Title			NVARCHAR(256) NOT NULL,
	Employer		NVARCHAR(256) NOT NULL,
	StartDate		DATETIME NULL,
	EndDate			DATETIME NULL,
	CreatorUserID	UNIQUEIDENTIFIER NOT NULL,
	CreationDate	DATETIME NOT NULL,
	Deleted			BIT NOT NULL
	
	CONSTRAINT [PK_USR_JobExperiences] PRIMARY KEY CLUSTERED
	(
		[JobID] ASC 
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


ALTER TABLE [dbo].[USR_JobExperiences]  WITH CHECK ADD  CONSTRAINT [FK_USR_JobExperiences_aspnet_Users] FOREIGN KEY([UserID])
REFERENCES [dbo].[aspnet_Users] ([UserID])
GO

ALTER TABLE [dbo].[USR_JobExperiences] CHECK CONSTRAINT [FK_USR_JobExperiences_aspnet_Users]
GO


ALTER TABLE [dbo].[USR_JobExperiences]  WITH CHECK ADD  CONSTRAINT [FK_USR_JobExperiences_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserID])
GO

ALTER TABLE [dbo].[USR_JobExperiences] CHECK CONSTRAINT [FK_USR_JobExperiences_aspnet_Users_Creator]
GO




CREATE TABLE [dbo].[USR_EducationalExperiences](
	EducationID		UNIQUEIDENTIFIER NOT NULL,
	AdditionalID	NVARCHAR(50) NULL,
	UserID			UNIQUEIDENTIFIER NOT NULL,
	School			NVARCHAR(256) NOT NULL,
	StudyField		NVARCHAR(256) NOT NULL,
	[Level]			VARCHAR(50) NOT NULL,
	StartDate		DATETIME NULL,
	EndDate			DATETIME NULL,
	GraduateDegree	VARCHAR(50) NULL,
	IsSchool		BIT NOT NULL,
	CreatorUserID	UNIQUEIDENTIFIER NOT NULL,
	CreationDate	DATETIME NOT NULL,	
	Deleted			BIT NOT NULL
	
	CONSTRAINT [PK_USR_EducationalExperiences] PRIMARY KEY CLUSTERED
	(
		EducationID ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


ALTER TABLE [dbo].[USR_EducationalExperiences]  WITH CHECK ADD  CONSTRAINT [FK_USR_EducationalExperiences_aspnet_Users] FOREIGN KEY([UserID])
REFERENCES [dbo].[aspnet_Users] ([UserID])
GO

ALTER TABLE [dbo].[USR_EducationalExperiences] CHECK CONSTRAINT [FK_USR_EducationalExperiences_aspnet_Users]
GO


ALTER TABLE [dbo].[USR_EducationalExperiences]  WITH CHECK ADD  CONSTRAINT [FK_USR_EducationalExperiences_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserID])
GO

ALTER TABLE [dbo].[USR_EducationalExperiences] CHECK CONSTRAINT [FK_USR_EducationalExperiences_aspnet_Users_Creator]
GO




-- create new table
CREATE TABLE [dbo].[USR_HonorsAndAwards](
	ID				UNIQUEIDENTIFIER NOT NULL,
	AdditionalID	NVARCHAR(50) NULL,
	UserID			UNIQUEIDENTIFIER NOT NULL,
	Title			NVARCHAR(512) NOT NULL,
	Issuer			NVARCHAR(512) NOT NULL,
	Occupation		NVARCHAR(512) NOT NULL,
	IssueDate		DATETIME NULL,
	[Description]	NVARCHAR(MAX) NULL,
	CreatorUserID	UNIQUEIDENTIFIER NOT NULL,
	CreationDate	DATETIME NOT NULL,
	Deleted			BIT NOT NULL
	
	CONSTRAINT [PK_USR_HonorsAndAwards] PRIMARY KEY CLUSTERED
	(
		ID ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


ALTER TABLE [dbo].[USR_HonorsAndAwards] WITH CHECK ADD  CONSTRAINT [FK_USR_HonorsAndAwards_aspnet_Users] FOREIGN KEY([UserID])
REFERENCES [dbo].[aspnet_Users] ([UserID])
GO

ALTER TABLE [dbo].[USR_HonorsAndAwards] CHECK CONSTRAINT [FK_USR_HonorsAndAwards_aspnet_Users]
GO


ALTER TABLE [dbo].[USR_HonorsAndAwards] WITH CHECK ADD  CONSTRAINT [FK_USR_HonorsAndAwards_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserID])
GO

ALTER TABLE [dbo].[USR_HonorsAndAwards] CHECK CONSTRAINT [FK_USR_HonorsAndAwards_aspnet_Users_Creator]
GO


IF  EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[GFN_PersianDate2Gregorian]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[GFN_PersianDate2Gregorian]
GO

CREATE FUNCTION [dbo].[GFN_PersianDate2Gregorian](@iYear INT,@iMonth INT,@iDay INT)
	RETURNS DATETIME
AS
BEGIN
	DECLARE @PERSIAN_EPOCH  AS INT
	DECLARE @epbase AS BIGINT
	DECLARE @epyear AS BIGINT
	DECLARE @mdays AS BIGINT
	DECLARE @Jofst  AS NUMERIC(18,2)
	DECLARE @jdn AS BIGINT
	DECLARE @Jofst2  AS NUMERIC(18,2)
	 
	SET @PERSIAN_EPOCH=1948321
	SET @Jofst=2415020.5
	
	IF (@iYear >= 0) SET @epbase = @iyear-474
	ELSE SET @epbase = @iYear - 473
	
	SET @epyear = 474 + (@epbase % 2820)
	    
	IF (@iMonth <= 7) SET @mdays = (CONVERT(BIGINT,(@iMonth) - 1) * 31)
	ELSE SET @mdays = (CONVERT(BIGINT,(@iMonth) - 1) * 30 + 6)
	
	SET @jdn = CONVERT(INT, @iday) + @mdays + CAST(((@epyear * 682) - 110) / 2816 AS INT) + 
		(@epyear - 1) * 365 + CAST(@epbase / 2820 AS INT) * 1029983 + (@PERSIAN_EPOCH - 1)
	
	SET @Jofst2=2415020.5
	
	RETURN CONVERT(DATETIME, (@jdn - @Jofst2), 113)
END

GO


INSERT INTO [dbo].[USR_EducationalExperiences](
	[EducationID],
	[UserID],
	[School],
	[StudyField],
	[Level],
	[GraduateDegree],
	StartDate,
	EndDate,
	IsSchool,
	CreatorUserID,
	CreationDate,
	Deleted
)
SELECT
	ref.ID,
	ref.UserID,
	SUBSTRING(ISNULL(ref.UniversityTitle, N''), 0, 200),
	SUBSTRING(ISNULL(ref.UniversityField, N''), 0, 200),
	CASE ref.EducationDegree
		WHEN N'دیپلم' THEN 'Diploma'
		WHEN N'کارشناسی' THEN 'Bachelor'
		WHEN N'لیسانس'  THEN 'Bachelor'
		WHEN N'فوق لیسانس' THEN 'Master'
		WHEN N'کارشناسی_ارشد' THEN 'Master'
		WHEN N'دکتری' THEN 'Doctor'
		ELSE 'None'
	END,
	CASE ref.UniversityFinalLevel
		WHEN N'اول' THEN 'First'
		WHEN N'دوم' THEN 'Second'
		WHEN N'سوم'  THEN 'Third'
		WHEN N'پایین تر از سوم' THEN 'Other'
		ELSE 'None'
	END,
	NULL,
	NULL,
	1,
	ref.UserID,
	GETDATE(),
	0
FROM [dbo].[ProfileEducation] AS ref

UNION

SELECT
	ref.ID,
	ref.UserID,
	SUBSTRING(ISNULL(ref.Institute, N''), 0, 200),
	SUBSTRING(ISNULL(ref.Title, N''), 0, 200),
	'None',
	NULL,
	CASE
		WHEN ISNUMERIC(ref.[Year]) = 1 AND LEN(ISNULL(ref.[Year], N'')) = 4 
			THEN [dbo].[GFN_PersianDate2Gregorian](CAST(ref.[Year] AS int), 1, 1)
		ELSE NULL
	END,
	NULL,
	0,
	ref.UserID,
	GETDATE(),
	0
FROM [dbo].[ProfileInstitute] AS ref

GO

IF  EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[GFN_PersianDate2Gregorian]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[GFN_PersianDate2Gregorian]
GO



INSERT INTO [dbo].[USR_JobExperiences](
	JobID,
	UserID,
	Title,
	Employer,
	StartDate,
	EndDate,
	CreatorUserID,
	CreationDate,	
	Deleted
)
SELECT
	pj.ID,
	pj.UserID,
	pj.Title,
	pj.Employer,
	pj.StartDate,
	pj.EndDate,
	pj.UserID,
	GETDATE(),
	0
FROM [dbo].[ProfileJobs] AS pj

GO


/****** Object:  Table [dbo].[KKnowledges]    Script Date: 04/04/2012 12:34:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



UPDATE [dbo].[AppSetting]
	SET [Version] = 'v25.1.1.0' -- 13930602
GO

