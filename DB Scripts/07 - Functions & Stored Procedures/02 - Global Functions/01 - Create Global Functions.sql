USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* 'GFN' stands for Global Function */

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GFN_GuidEmpty]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[GFN_GuidEmpty]
GO

CREATE FUNCTION [dbo].[GFN_GuidEmpty] ()
RETURNS uniqueidentifier
AS
BEGIN
	RETURN CAST(0x0 AS uniqueidentifier)
END

GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GFN_NewGuid]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[GFN_NewGuid]
GO

CREATE FUNCTION [dbo].[GFN_NewGuid] ()
RETURNS uniqueidentifier
AS
BEGIN
	RETURN (SELECT TOP(1) X.ID FROM [dbo].[RV_View_NewGuid] AS X)
END

GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GFN_IsSystemAdmin]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[GFN_IsSystemAdmin]
GO

CREATE FUNCTION [dbo].[GFN_IsSystemAdmin] (
	@ApplicationID	uniqueidentifier,
	@UserID			uniqueidentifier
)
RETURNS bit
AS
BEGIN
	DECLARE @Val bit = (
		SELECT CAST(1 as bit)
		WHERE EXISTS(
				SELECT TOP(1) *
				FROM [dbo].[aspnet_UsersInRoles] AS U
					INNER JOIN [dbo].[aspnet_Roles] AS R
					ON R.RoleId = U.RoleId
				WHERE (@ApplicationID IS NULL OR R.ApplicationID = @ApplicationID) AND 
					U.UserId = @UserID AND R.LoweredRoleName = N'admins'
			)
	)
	
	RETURN ISNULL(@Val, 0)
END

GO


IF  EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[GFN_StrToGuidTable]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[GFN_StrToGuidTable]
GO

CREATE FUNCTION [dbo].[GFN_StrToGuidTable]
(
	@inputString	varchar(max),
	@delimiter		char
)
RETURNS
@outputTable TABLE
(
	Value	uniqueidentifier
)
WITH ENCRYPTION
AS
BEGIN
	-- Fill the table variable with the rows for your result set
	if @inputString IS NULL OR @inputString = '' return
	
    declare @beginPos int, @pos int, @strItem varchar(100)
    set @pos = 0
    set @beginPos = @pos

	while (@pos >= @beginPos) begin
		set @beginPos = @pos + 1
		set @pos = charindex(@delimiter, @inputString, @beginPos)
		
		if @pos >= @beginPos
			set @strItem = substring(@inputString, @beginPos, @pos - 1)
		else
			set @strItem = substring(@inputString, @beginPos, 8000000)
		
		Insert @outputTable values (CAST(@strItem as uniqueidentifier))
	end
   
    RETURN 
END

GO


IF  EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[GFN_StrToGuidPairTable]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[GFN_StrToGuidPairTable]
GO

CREATE FUNCTION [dbo].[GFN_StrToGuidPairTable]
(
	@inputString	varchar(max),
	@innerDelimiter		char,
	@outerDelimiter		char
)
RETURNS
@outputTable TABLE
(
	FirstValue		uniqueidentifier,
	SecondValue		uniqueidentifier
)
WITH ENCRYPTION
AS
BEGIN
	-- Fill the table variable with the rows for your result set
	if @inputString IS NULL OR @inputString = '' return
	
    declare @beginPos int, @pos int, @strFirstItem varchar(100), @strSecondItem varchar(100)
    set @pos = 0
    set @beginPos = @pos
    
	while (@pos >= @beginPos) begin
		set @beginPos = @pos + 1
		set @pos = charindex(@innerDelimiter, @inputString, @beginPos)
		
		set @strFirstItem = substring(@inputString, @beginPos, @pos-1)
		
		set @beginPos = @pos + 1
		set @pos = charindex(@outerDelimiter, @inputString, @beginPos)
			
		if @pos >= @beginPos
			set @strSecondItem = substring(@inputString, @beginPos, @pos-1)
		else
			set @strSecondItem = substring(@inputString, @beginPos, 8000000)
		
		Insert @outputTable values (CAST(@strFirstItem as uniqueidentifier),
			CAST(@strSecondItem as uniqueidentifier))
	end
   
    RETURN 
END

GO


IF  EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[GFN_StrToGuidTripleTable]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[GFN_StrToGuidTripleTable]
GO

CREATE FUNCTION [dbo].[GFN_StrToGuidTripleTable]
(
	@inputString	varchar(max),
	@innerDelimiter		char,
	@outerDelimiter		char
)
RETURNS
@outputTable TABLE
(
	FirstValue		uniqueidentifier,
	SecondValue		uniqueidentifier,
	ThirdValue		uniqueidentifier
)
WITH ENCRYPTION
AS
BEGIN
	-- Fill the table variable with the rows for your result set
	if @inputString IS NULL OR @inputString = '' return
	
    declare @beginPos int, @pos int, 
		@strFirstItem varchar(100), @strSecondItem varchar(100), @strThirdItem varchar(100)
    set @pos = 0
    set @beginPos = @pos
    
	while (@pos >= @beginPos) begin
		set @beginPos = @pos + 1
		set @pos = charindex(@innerDelimiter, @inputString, @beginPos)
		
		set @strFirstItem = substring(@inputString, @beginPos, @pos-1)
		
		set @beginPos = @pos + 1
		set @pos = charindex(@innerDelimiter, @inputString, @beginPos)
		
		set @strSecondItem = substring(@inputString, @beginPos, @pos-1)
		
		set @beginPos = @pos + 1
		set @pos = charindex(@outerDelimiter, @inputString, @beginPos)
		
		if @pos >= @beginPos
			set @strThirdItem = substring(@inputString, @beginPos, @pos-1)
		else
			set @strThirdItem = substring(@inputString, @beginPos, 8000000)
		
		Insert @outputTable values (CAST(@strFirstItem as uniqueidentifier),
			CAST(@strSecondItem as uniqueidentifier),
			CAST(@strThirdItem as uniqueidentifier))
	end
   
    RETURN 
END

GO


IF  EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[GFN_StrToBigIntTable]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[GFN_StrToBigIntTable]
GO

CREATE FUNCTION [dbo].[GFN_StrToBigIntTable]
(
	@inputString	varchar(max),
	@delimiter		char
)
RETURNS
@outputTable TABLE
(
	Value	bigint
)
WITH ENCRYPTION
AS
BEGIN
	-- Fill the table variable with the rows for your result set
	if @inputString IS NULL OR @inputString = '' return
	
    declare @beginPos int, @pos int, @strItem varchar(100)
    set @pos = 0
    set @beginPos = @pos

	while (@pos >= @beginPos) begin
		set @beginPos = @pos + 1
		set @pos = charindex(@delimiter, @inputString, @beginPos)
		
		if @pos >= @beginPos
			set @strItem = substring(@inputString, @beginPos, @pos-@beginPos)
		else
			set @strItem = substring(@inputString, @beginPos, 8000000)
		
		Insert @outputTable values (CAST(@strItem as bigint))
	end
   
    RETURN 
END

GO


IF  EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[GFN_StrToStringTable]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[GFN_StrToStringTable]
GO

CREATE FUNCTION [dbo].[GFN_StrToStringTable]
(
	@inputString	nvarchar(max),
	@delimiter		char
)
RETURNS
@outputTable TABLE
(
	Value	nvarchar(max)
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @XML xml =
		CONVERT(xml,'<root><s>' + REPLACE(@inputString,@delimiter,'</s><s>') + '</s></root>')
	
	INSERT INTO @outputTable
	SELECT LTRIM(RTRIM(T.c.value('.','nvarchar(max)')))
	FROM @XML.nodes('/root/s') T(c)
	
	DELETE @outputTable
	WHERE Value = N''
	
    RETURN 
END

GO


IF  EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[GFN_StrToStringPairTable]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[GFN_StrToStringPairTable]
GO

CREATE FUNCTION [dbo].[GFN_StrToStringPairTable]
(
	@inputString	nvarchar(max),
	@innerDelimiter	char,
	@outerDelimiter char
)
RETURNS
@outputTable TABLE
(
	FirstValue	nvarchar(max),
	SecondValue	nvarchar(max)
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @XML xml =
		CONVERT(xml,'<root><s>' + REPLACE(@inputString,@outerDelimiter,'</s><s>') + '</s></root>')
	
	DECLARE @S Table(ID int IDENTITY(1,1), Val nvarchar(4000))
	
	INSERT INTO @S (Val)
	SELECT T.c.value('.','varchar(max)')
	FROM @XML.nodes('/root/s') T(c)
	
	DECLARE @CNT int = (SELECT COUNT(*) FROM @S)
	WHILE (@CNT > 0) BEGIN
		DECLARE @Str nvarchar(4000) = (SELECT Val FROM @S WHERE ID = @CNT)
		DECLARE @Pos int = charindex(@innerDelimiter, @Str, 0)
		
		INSERT INTO @outputTable (FirstValue, SecondValue)
		VALUES(substring(@Str, 0, @pos), substring(@Str, @pos + 1, 4000))
		
		SET @CNT = @CNT - 1
	END
	
	DELETE @outputTable
	WHERE SecondValue = N''
	
    RETURN 
END

GO


IF  EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[GFN_StrToFloatStringTable]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[GFN_StrToFloatStringTable]
GO

CREATE FUNCTION [dbo].[GFN_StrToFloatStringTable]
(
	@inputString	varchar(max),
	@innerDelimiter	char,
	@outerDelimiter char
)
RETURNS
@outputTable TABLE
(
	FirstValue	float,
	SecondValue	varchar(max)
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @XML xml =
		CONVERT(xml,'<root><s>' + REPLACE(@inputString,@outerDelimiter,'</s><s>') + '</s></root>')
	
	DECLARE @S Table(ID int IDENTITY(1,1), Val nvarchar(4000))
	
	INSERT INTO @S (Val)
	SELECT T.c.value('.','varchar(max)')
	FROM @XML.nodes('/root/s') T(c)
	
	DECLARE @CNT int = (SELECT COUNT(*) FROM @S)
	WHILE (@CNT > 0) BEGIN
		DECLARE @Str nvarchar(4000) = (SELECT Val FROM @S WHERE ID = @CNT)
		DECLARE @Pos int = charindex(@innerDelimiter, @Str, 0)
		
		INSERT INTO @outputTable (FirstValue, SecondValue)
		VALUES(CAST(substring(@Str, 0, @pos) AS float), 
			substring(@Str, @pos + 1, 4000))
		
		SET @CNT = @CNT - 1
	END
	
	DELETE @outputTable
	WHERE SecondValue = N''
	
    RETURN 
END

GO



IF  EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[GFN_VerifyString]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[GFN_VerifyString]
GO

CREATE FUNCTION [dbo].[GFN_VerifyString]
(
	@inputString	nvarchar(max)
)
RETURNS nvarchar(max)
WITH ENCRYPTION
AS
BEGIN
	IF @inputString IS NULL RETURN NULL
    RETURN REPLACE(REPLACE(REPLACE(REPLACE(@inputString, N'ي', N'ی'), N'ك', N'ک'), 0x0000, N''), 0x0002, N'')
END

GO


IF  EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[GFN_Base64Encode]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[GFN_Base64Encode]
GO

CREATE FUNCTION [dbo].[GFN_Base64Encode]
(
	@input	nvarchar(max)
)
RETURNS nvarchar(max)
WITH ENCRYPTION
AS
BEGIN
	IF @input IS NULL OR @input = N'' RETURN @input

	RETURN (
		SELECT CAST(N'' AS XML).value('xs:base64Binary(xs:hexBinary(sql:column("bin")))', 'NVARCHAR(MAX)')
		FROM (
			SELECT CAST(@input AS VARBINARY(MAX)) AS bin
		) AS x
	)
END

GO


IF  EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[GFN_Base64Decode]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[GFN_Base64Decode]
GO

CREATE FUNCTION [dbo].[GFN_Base64Decode]
(
	@input	nvarchar(max)
)
RETURNS nvarchar(max)
WITH ENCRYPTION
AS
BEGIN
	IF @input IS NULL OR @input = N'' RETURN @input

	RETURN CAST((
		SELECT CAST(N'' AS XML).value('xs:base64Binary(sql:column("val"))', 'VARBINARY(MAX)')
		FROM (
			SELECT @input AS val
		) AS x
	) AS NVARCHAR(MAX))
END

GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GFN_GetSearchText]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[GFN_GetSearchText]
GO

CREATE FUNCTION [dbo].[GFN_GetSearchText]
(
	@input	nvarchar(max)
)
RETURNS nvarchar(max)
WITH ENCRYPTION
AS
BEGIN
	IF @input IS NULL OR @input = N'' RETURN @input
	
	DECLARE @Words TABLE(ID int IDENTITY(1, 1) primary key clustered, Word nvarchar(1000))
	
	INSERT INTO @Words (Word)
	SELECT LTRIM(RTRIM(Ref.Value))
	FROM [dbo].[GFN_StrToStringTable](@input, N' ') AS Ref
	WHERE LTRIM(RTRIM(Ref.Value)) <> N'' AND LEN(ISNULL(LTRIM(RTRIM(Ref.Value)), N'')) > 2
	
	DECLARE @Count int = (SELECT COUNT(*) FROM @Words)
	DECLARE @I int =  1
	
	IF @Count = 0 RETURN NULL
	
	DECLARE @RetStr nvarchar(max) = N'ISABOUT('
	
	WHILE @I <= @Count BEGIN
		DECLARE @Str nvarchar(1000) = (SELECT Ref.Word FROM @Words AS Ref WHERE Ref.ID = @I)
		
		IF @I > 1 SET @RetStr = @RetStr + N','
		
		SET @RetStr = @RetStr + N'"' + @Str + N'*" WEIGHT(' +
			CAST(
				(CASE
					WHEN @I > 5 THEN 0.1
					ELSE 1 - ((@I - 1) * 0.2)
				END)
				AS nvarchar(100)
			) +
			N')'
		
		SET @I = @I + 1
	END
	
	RETURN @RetStr + N')'
END

GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GFN_LikeMatch]') 
	AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[GFN_LikeMatch]
GO

CREATE FUNCTION [dbo].[GFN_LikeMatch]
(
	@Input nvarchar(2000),
	@StringItems StringTableType readonly,
	@Or bit,
	@Exact bit
)
RETURNS bit
WITH ENCRYPTION
AS
BEGIN
	DECLARE @RetVal bit = 0
	
	DECLARE @Count int = (SELECT COUNT(*) FROM @StringItems)
	
	DECLARE @str nvarchar(10) = CASE WHEN @Exact = 1 THEN N'' ELSE N'%' END
	
	DECLARE @MatchCount int  = (
		SELECT COUNT(*)
		FROM @StringItems AS SI
		WHERE @Input LIKE (@str + ISNULL(SI.Value, N'') + @str)
	)
	
	IF @Or = 1 RETURN CASE WHEN @MatchCount > 0 THEN 1 ELSE 0 END
	ELSE RETURN CASE WHEN @MatchCount = @Count THEN 1 ELSE 0 END
	
	RETURN 0
END

GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GFN_Persian2Julian]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[GFN_Persian2Julian]
GO

CREATE FUNCTION [dbo].[GFN_Persian2Julian](@iYear int, @iMonth int, @iDay int)
RETURNS bigint
AS
BEGIN
 
	Declare @PERSIAN_EPOCH  as int
	Declare @epbase as bigint
	Declare @epyear as bigint
	Declare @mdays as bigint
	Declare @Jofst  as Numeric(18,2)
	Declare @jdn bigint
	 
	Set @PERSIAN_EPOCH=1948321
	Set @Jofst=2415020.5
	 
	If @iYear>=0 
		Begin
			Set @epbase=@iyear-474 
		End
	Else
		Begin
			Set @epbase = @iYear - 473 
		End
		set @epyear=474 + (@epbase%2820) 
	If @iMonth<=7
		Begin
			Set @mdays=(Convert(bigint,(@iMonth) - 1) * 31)
		End
	Else
		Begin
			Set @mdays=(Convert(bigint,(@iMonth) - 1) * 30+6)
		End
		Set @jdn =Convert(int,@iday) + @mdays+ Cast(((@epyear * 682) - 110) / 2816 as int)  + (@epyear - 1) * 365 + Cast(@epbase / 2820 as int) * 1029983 + (@PERSIAN_EPOCH - 1) 
		RETURN @jdn
	End

GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GFN_Gregorian2Persian]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[GFN_Gregorian2Persian]
GO

CREATE Function dbo.[GFN_Gregorian2Persian] (@date datetime)
RETURNS @outputTable TABLE (
	[Year]	INT NOT NULL,
	[Month]	INT NOT NULL,
	[Day]	INT NOT NULL
)
AS
BEGIN
	SET @date = CAST(CAST(DATEPART(YEAR, @date) as varchar(10)) + '-' + 
	CAST(DATEPART(MONTH, @date) as varchar(10)) + '-' + CAST(DATEPART(DAY, @date) as varchar(10)) + ' 00:00:00.000' AS datetime)

    Declare @depoch as bigint
    Declare @cycle  as bigint
    Declare @cyear  as bigint
    Declare @ycycle as bigint
    Declare @aux1 as bigint
    Declare @aux2 as bigint
    Declare @yday as bigint
    Declare @Jofst  as Numeric(18,2)
    Declare @jdn bigint
 
    Declare @iYear   As Integer
    Declare @iMonth  As Integer
    Declare @iDay    As Integer
 
    Set @Jofst=2415020.5
    Set @jdn=Round(Cast(@date as int)+ @Jofst,0)
 
    Set @depoch = @jdn - [dbo].[GFN_Persian2Julian](475, 1, 1) 
    Set @cycle = Cast(@depoch / 1029983 as int) 
    Set @cyear = @depoch%1029983 
 
    If @cyear = 1029982
       Begin
         Set @ycycle = 2820 
       End
    Else
       Begin
        Set @aux1 = Cast(@cyear / 366 as int) 
        Set @aux2 = @cyear%366 
        Set @ycycle = Cast(((2134 * @aux1) + (2816 * @aux2) + 2815) / 1028522 as int) + @aux1 + 1 
      End
 
    Set @iYear = @ycycle + (2820 * @cycle) + 474 
 
    If @iYear <= 0
      Begin 
        Set @iYear = @iYear - 1 
      End
    Set @yday = (@jdn - [dbo].[GFN_Persian2Julian](@iYear, 1, 1)) + 1 
    If @yday <= 186 
       Begin
         Set @iMonth = CEILING(Convert(Numeric(18,4),@yday) / 31) 
       End
    Else
       Begin
          Set @iMonth = CEILING((Convert(Numeric(18,4),@yday) - 6) / 30)  
       End
       Set @iDay = (@jdn - [dbo].[GFN_Persian2Julian](@iYear, @iMonth, 1)) + 1 
 
	INSERT INTO @outputTable ([Year], [Month], [Day])
	VALUES (ISNULL(@iYear, 0), ISNULL(@iMonth, 0), ISNULL(@iDay, 0))

	RETURN
End
 
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GFN_Julian2Gregorian]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[GFN_Julian2Gregorian]
GO

CREATE FUNCTION [dbo].[GFN_Julian2Gregorian] (@jdn bigint)
RETURNS datetime
AS
BEGIN
    DECLARE @Jofst AS numeric(18,2)
    SET @Jofst=2415020.5
    RETURN CAST(Convert(nvarchar(11),Convert(datetime,(@jdn- @Jofst),113),110) AS datetime)
END

GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GFN_Persian2Gregorian]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[GFN_Persian2Gregorian]
GO

CREATE FUNCTION [dbo].[GFN_Persian2Gregorian] (@Year int, @Month int, @Day int)
RETURNS datetime
AS
BEGIN
    RETURN [dbo].[GFN_Julian2Gregorian]([dbo].[GFN_Persian2Julian](@Year, @Month, @Day))
END

GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GFN_Gregorian2Persian_String]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[GFN_Gregorian2Persian_String]
GO

CREATE Function [dbo].[GFN_Gregorian2Persian_String] (@date datetime)
RETURNS nvarchar(10)
AS
BEGIN
	RETURN (
		SELECT TOP(1)	CAST(X.[Year] AS nvarchar(10)) + N'/' + 
						CAST(X.[Month] AS nvarchar(10)) + N'/' + 
						CAST(X.[Day] AS nvarchar(10))
		FROM [dbo].[GFN_Gregorian2Persian](@date) AS X
	)
End
 
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GFN_IsJalaliLeapYear]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[GFN_IsJalaliLeapYear]
GO

CREATE FUNCTION [dbo].[GFN_IsJalaliLeapYear] (@Year int)
RETURNS bit
AS
BEGIN
    DECLARE @A float = 0.025
    DECLARE @B float = 266
    
    DECLARE @LeapDays0 float = 0, @LeapDays1 float = 0
    
    IF ISNULL(@Year, 0) = 0 RETURN 0
    ELSE IF @Year > 0 BEGIN
		SET @LeapDays0 = (((@Year + 38) % 2820) * 0.24219) + @A
		SET @LeapDays1 = (((@Year + 39) % 2820) * 0.24219) + @A
    END
    ELSE BEGIN
		SET @LeapDays0 = (((@Year + 39) % 2820) * 0.24219) + @A
		SET @LeapDays1 = (((@Year + 40) % 2820) * 0.24219) + @A
    END
    
    DECLARE @Frac0 int = CAST((@LeapDays0 - CAST(@LeapDays0 AS int)) * 1000 AS int)
    DECLARE @Frac1 int = CAST((@LeapDays1 - CAST(@LeapDays1 AS int)) * 1000 AS int)
    
    IF @Frac0 <= @B AND @Frac1 > @B RETURN 1
    ELSE RETURN 0
    
    RETURN 1
END

GO



IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[GFN_GetTimePeriod]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[GFN_GetTimePeriod]
GO

CREATE FUNCTION [dbo].[GFN_GetTimePeriod] (@Date datetime, @Period varchar(50), @CalendarType varchar(50))
RETURNS	int
AS
BEGIN
	SET @Period = LOWER(LTRIM(RTRIM(ISNULL(@Period, ''))))
	SET @CalendarType = LOWER(LTRIM(RTRIM(ISNULL(@CalendarType, ''))))

	DECLARE @Year int = 0
	DECLARE @Month int = 0

	IF @CalendarType = 'jalali' BEGIN
		SELECT TOP(1)
			@Year = X.[Year],
			@Month = X.[Month]
		FROM [dbo].[GFN_Gregorian2Persian](@Date) AS X
	END
	ELSE BEGIN
		SET @Year = ISNULL(DATEPART(YEAR, @Date), 0)
		SET @Month = ISNULL(DATEPART(MONTH, @Date), 0)
	END

    RETURN (
		CASE
			WHEN @Period = 'year' THEN @Year
			WHEN @Period = 'season' THEN 
				CAST((CAST(@Year AS varchar(10)) + CAST((
					CASE
						WHEN (@Month % 3) = 0 THEN (@Month / 3) - 1
						ELSE @Month / 3
					END + 1
				) AS varchar(10))) AS int)
			WHEN @Period = 'month' THEN 
				CAST((CAST(@Year AS varchar(10)) + (CASE WHEN @Month < 10 THEN '0' ELSE '' END) + CAST(@Month AS varchar(10))) AS int)
			ELSE 0
		END
	)
END

GO


