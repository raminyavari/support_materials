USE [EKM_App]
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