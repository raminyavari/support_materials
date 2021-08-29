
/* 'GFN' stands for Global Function */

DROP FUNCTION IF EXISTS gfn_str_to_guid_table;

CREATE FUNCTION gfn_str_to_guid_table
(
	vr_input_string	varchar(max),
	vr_delimiter		char
)
RETURNS
vr_output_table TABLE
(
	Value	UUID
)
WITH ENCRYPTION
AS
BEGIN
	-- Fill the table variable with the rows for your result set
	if vr_input_string IS NULL OR vr_input_string = '' return
	
    declare vr_begin_pos INTEGER, vr_pos INTEGER, vr_str_item varchar(100)
    set vr_pos = 0
    set vr_begin_pos = vr_pos

	while (vr_pos >= vr_begin_pos) begin
		set vr_begin_pos = vr_pos + 1
		set vr_pos = charindex(vr_delimiter, vr_input_string, vr_begin_pos)
		
		if vr_pos >= vr_begin_pos
			set vr_str_item = substring(vr_input_string, vr_begin_pos, vr_pos - 1)
		else
			set vr_str_item = substring(vr_input_string, vr_begin_pos, 8000000)
		
		Insert vr_output_table values (CAST(vr_str_item AS uuid))
	end
   
    RETURN 
END;


DROP FUNCTION IF EXISTS gfn_str_to_guid_pair_table;

CREATE FUNCTION gfn_str_to_guid_pair_table
(
	vr_input_string	varchar(max),
	vr_inner_delimiter		char,
	vr_outer_delimiter		char
)
RETURNS
vr_output_table TABLE
(
	FirstValue		UUID,
	SecondValue		UUID
)
WITH ENCRYPTION
AS
BEGIN
	-- Fill the table variable with the rows for your result set
	if vr_input_string IS NULL OR vr_input_string = '' return
	
    declare vr_begin_pos INTEGER, vr_pos INTEGER, vr_str_first_item varchar(100), vr_str_second_item varchar(100)
    set vr_pos = 0
    set vr_begin_pos = vr_pos
    
	while (vr_pos >= vr_begin_pos) begin
		set vr_begin_pos = vr_pos + 1
		set vr_pos = charindex(vr_inner_delimiter, vr_input_string, vr_begin_pos)
		
		set vr_str_first_item = substring(vr_input_string, vr_begin_pos, vr_pos-1)
		
		set vr_begin_pos = vr_pos + 1
		set vr_pos = charindex(vr_outer_delimiter, vr_input_string, vr_begin_pos)
			
		if vr_pos >= vr_begin_pos
			set vr_str_second_item = substring(vr_input_string, vr_begin_pos, vr_pos-1)
		else
			set vr_str_second_item = substring(vr_input_string, vr_begin_pos, 8000000)
		
		Insert vr_output_table values (CAST(vr_str_first_item AS uuid),
			CAST(vr_str_second_item AS uuid))
	end
   
    RETURN 
END;


DROP FUNCTION IF EXISTS gfn_str_to_guid_triple_table;

CREATE FUNCTION gfn_str_to_guid_triple_table
(
	vr_input_string	varchar(max),
	vr_inner_delimiter		char,
	vr_outer_delimiter		char
)
RETURNS
vr_output_table TABLE
(
	FirstValue		UUID,
	SecondValue		UUID,
	ThirdValue		UUID
)
WITH ENCRYPTION
AS
BEGIN
	-- Fill the table variable with the rows for your result set
	if vr_input_string IS NULL OR vr_input_string = '' return
	
    declare vr_begin_pos INTEGER, vr_pos INTEGER, 
		vr_str_first_item varchar(100), vr_str_second_item varchar(100), vr_str_third_item varchar(100)
    set vr_pos = 0
    set vr_begin_pos = vr_pos
    
	while (vr_pos >= vr_begin_pos) begin
		set vr_begin_pos = vr_pos + 1
		set vr_pos = charindex(vr_inner_delimiter, vr_input_string, vr_begin_pos)
		
		set vr_str_first_item = substring(vr_input_string, vr_begin_pos, vr_pos-1)
		
		set vr_begin_pos = vr_pos + 1
		set vr_pos = charindex(vr_inner_delimiter, vr_input_string, vr_begin_pos)
		
		set vr_str_second_item = substring(vr_input_string, vr_begin_pos, vr_pos-1)
		
		set vr_begin_pos = vr_pos + 1
		set vr_pos = charindex(vr_outer_delimiter, vr_input_string, vr_begin_pos)
		
		if vr_pos >= vr_begin_pos
			set vr_str_third_item = substring(vr_input_string, vr_begin_pos, vr_pos-1)
		else
			set vr_str_third_item = substring(vr_input_string, vr_begin_pos, 8000000)
		
		Insert vr_output_table values (CAST(vr_str_first_item AS uuid),
			CAST(vr_str_second_item AS uuid),
			CAST(vr_str_third_item AS uuid))
	end
   
    RETURN 
END;


DROP FUNCTION IF EXISTS gfn_str_to_big_int_table;

CREATE FUNCTION gfn_str_to_big_int_table
(
	vr_input_string	varchar(max),
	vr_delimiter		char
)
RETURNS
vr_output_table TABLE
(
	Value	bigint
)
WITH ENCRYPTION
AS
BEGIN
	-- Fill the table variable with the rows for your result set
	if vr_input_string IS NULL OR vr_input_string = '' return
	
    declare vr_begin_pos INTEGER, vr_pos INTEGER, vr_str_item varchar(100)
    set vr_pos = 0
    set vr_begin_pos = vr_pos

	while (vr_pos >= vr_begin_pos) begin
		set vr_begin_pos = vr_pos + 1
		set vr_pos = charindex(vr_delimiter, vr_input_string, vr_begin_pos)
		
		if vr_pos >= vr_begin_pos
			set vr_str_item = substring(vr_input_string, vr_begin_pos, vr_pos-vr_begin_pos)
		else
			set vr_str_item = substring(vr_input_string, vr_begin_pos, 8000000)
		
		Insert vr_output_table values (CAST(vr_str_item AS bigint))
	end
   
    RETURN 
END;


DROP FUNCTION IF EXISTS gfn_str_to_string_table;

CREATE FUNCTION gfn_str_to_string_table
(
	vr_input_string VARCHAR(max),
	vr_delimiter		char
)
RETURNS
vr_output_table TABLE
(
	Value VARCHAR(max)
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE vr_xml xml =
		CONVERT(xml,'<root><s>' + REPLACE(vr_input_string,vr_delimiter,'</s><s>') + '</s></root>')
	
	INSERT INTO vr_output_table
	SELECT LTRIM(RTRIM(t.c.value('.','nvarchar(max)')))
	FROM vr_xml.nodes('/root/s') T(c)
	
	DELETE vr_output_table
	WHERE Value = N''
	
    RETURN 
END;


DROP FUNCTION IF EXISTS gfn_str_to_string_pair_table;

CREATE FUNCTION gfn_str_to_string_pair_table
(
	vr_input_string VARCHAR(max),
	vr_inner_delimiter	char,
	vr_outer_delimiter char
)
RETURNS
vr_output_table TABLE
(
	FirstValue VARCHAR(max),
	SecondValue VARCHAR(max)
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE vr_xml xml =
		CONVERT(xml,'<root><s>' + REPLACE(vr_input_string,vr_outer_delimiter,'</s><s>') + '</s></root>')
	
	DECLARE vr_s Table(ID INTEGER IDENTITY(1,1), Val VARCHAR(4000))
	
	INSERT INTO vr_s (Val)
	SELECT t.c.value('.','varchar(max)')
	FROM vr_xml.nodes('/root/s') T(c)
	
	DECLARE vr_cnt INTEGER = (SELECT COUNT(*) FROM vr_s)
	WHILE (vr_cnt > 0) BEGIN
		DECLARE vr_str VARCHAR(4000) = (SELECT Val FROM vr_s WHERE ID = vr_cnt)
		DECLARE vr_pos INTEGER = charindex(vr_inner_delimiter, vr_str, 0)
		
		INSERT INTO vr_output_table (FirstValue, SecondValue)
		VALUES(substring(vr_str, 0, vr_pos), substring(vr_str, vr_pos + 1, 4000))
		
		SET vr_cnt = vr_cnt - 1
	END
	
	DELETE vr_output_table
	WHERE SecondValue = N''
	
    RETURN 
END;


DROP FUNCTION IF EXISTS gfn_str_to_float_string_table;

CREATE FUNCTION gfn_str_to_float_string_table
(
	vr_input_string	varchar(max),
	vr_inner_delimiter	char,
	vr_outer_delimiter char
)
RETURNS
vr_output_table TABLE
(
	FirstValue	float,
	SecondValue	varchar(max)
)
WITH ENCRYPTION
AS
BEGIN
	DECLARE vr_xml xml =
		CONVERT(xml,'<root><s>' + REPLACE(vr_input_string,vr_outer_delimiter,'</s><s>') + '</s></root>')
	
	DECLARE vr_s Table(ID INTEGER IDENTITY(1,1), Val VARCHAR(4000))
	
	INSERT INTO vr_s (Val)
	SELECT t.c.value('.','varchar(max)')
	FROM vr_xml.nodes('/root/s') T(c)
	
	DECLARE vr_cnt INTEGER = (SELECT COUNT(*) FROM vr_s)
	WHILE (vr_cnt > 0) BEGIN
		DECLARE vr_str VARCHAR(4000) = (SELECT Val FROM vr_s WHERE ID = vr_cnt)
		DECLARE vr_pos INTEGER = charindex(vr_inner_delimiter, vr_str, 0)
		
		INSERT INTO vr_output_table (FirstValue, SecondValue)
		VALUES(CAST(substring(vr_str, 0, vr_pos) AS float), 
			substring(vr_str, vr_pos + 1, 4000))
		
		SET vr_cnt = vr_cnt - 1
	END
	
	DELETE vr_output_table
	WHERE SecondValue = N''
	
    RETURN 
END;


DROP FUNCTION IF EXISTS gfn_get_search_text;

CREATE FUNCTION gfn_get_search_text
(
	vr_input VARCHAR(max)
)
RETURNS VARCHAR(max)
WITH ENCRYPTION
AS
BEGIN
	IF vr_input IS NULL OR vr_input = N'' RETURN vr_input
	
	DECLARE vr_words TABLE(ID INTEGER IDENTITY(1, 1) primary key clustered, Word VARCHAR(1000))
	
	INSERT INTO vr_words (Word)
	SELECT LTRIM(RTRIM(ref.value))
	FROM gfn_str_to_string_table(vr_input, N' ') AS ref
	WHERE LTRIM(RTRIM(ref.value)) <> N'' AND LEN(COALESCE(LTRIM(RTRIM(ref.value)), N'')) > 2
	
	DECLARE vr_count INTEGER = (SELECT COUNT(*) FROM vr_words)
	DECLARE vr_i INTEGER =  1
	
	IF vr_count = 0 RETURN NULL
	
	DECLARE vr_ret_str VARCHAR(max) = N'ISABOUT('
	
	WHILE vr_i <= vr_count BEGIN
		DECLARE vr_str VARCHAR(1000) = (SELECT ref.word FROM vr_words AS ref WHERE ref.id = vr_i)
		
		IF vr_i > 1 SET vr_ret_str = vr_ret_str + N','
		
		SET vr_ret_str = vr_ret_str + N'"' + vr_str + N'*" WEIGHT(' +
			CAST(
				(CASE
					WHEN vr_i > 5 THEN 0.1
					ELSE 1 - ((vr_i - 1) * 0.2)
				END)
			 AS varchar(100)
			) +
			N')'
		
		SET vr_i = vr_i + 1
	END
	
	RETURN vr_ret_str + N')'
END;


DROP FUNCTION IF EXISTS gfn_persian2_julian;

CREATE FUNCTION gfn_persian2_julian(vr_i_year INTEGER, vr_i_month INTEGER, vr_i_day INTEGER)
RETURNS bigint
AS
BEGIN
 
	Declare vr_persian_epoch  AS integer
	Declare vr_epbase AS bigint
	Declare vr_epyear AS bigint
	Declare vr_mdays AS bigint
	Declare vr_jofst  AS numeric(18,2)
	Declare vr_jdn bigint
	 
	Set vr_persian_epoch=1948321
	Set vr_jofst=2415020.5
	 
	If vr_i_year>=0 
		Begin
			Set vr_epbase=vr_iyear-474 
		End
	Else
		Begin
			Set vr_epbase = vr_i_year - 473 
		End
		set vr_epyear=474 + (vr_epbase%2820) 
	If vr_i_month<=7
		Begin
			Set vr_mdays=(Convert(bigint,(vr_i_month) - 1) * 31)
		End
	Else
		Begin
			Set vr_mdays=(Convert(bigint,(vr_i_month) - 1) * 30+6)
		End
		Set vr_jdn =Convert(int,vr_iday) + vr_mdays+ Cast(((vr_epyear * 682) - 110) / 2816 AS integer)  + (vr_epyear - 1) * 365 + Cast(vr_epbase / 2820 AS integer) * 1029983 + (vr_persian_epoch - 1) 
		RETURN vr_jdn
	End;


DROP FUNCTION IF EXISTS gfn_gregorian2_persian;

Create Function dbo.g_fn_gregorian2_persian (vr_date TIMESTAMP)
Returns VARCHAR(50)
as
Begin
    Declare vr_depoch AS bigint
    Declare vr_cycle  AS bigint
    Declare vr_cyear  AS bigint
    Declare vr_ycycle AS bigint
    Declare vr_aux1 AS bigint
    Declare vr_aux2 AS bigint
    Declare vr_yday AS bigint
    Declare vr_jofst  AS numeric(18,2)
    Declare vr_jdn bigint
 
    Declare vr_i_year   AS integer
    Declare vr_i_month  AS integer
    Declare vr_i_day    AS integer
 
    Set vr_jofst=2415020.5
    Set vr_jdn=Round(Cast(vr_date AS integer)+ vr_jofst,0)
 
    Set vr_depoch = vr_jdn - gfn_persian2_julian(475, 1, 1) 
    Set vr_cycle = Cast(vr_depoch / 1029983 AS integer) 
    Set vr_cyear = vr_depoch%1029983 
 
    If vr_cyear = 1029982
       Begin
         Set vr_ycycle = 2820 
       End
    Else
       Begin
        Set vr_aux1 = Cast(vr_cyear / 366 AS integer) 
        Set vr_aux2 = vr_cyear%366 
        Set vr_ycycle = Cast(((2134 * vr_aux1) + (2816 * vr_aux2) + 2815) / 1028522 AS integer) + vr_aux1 + 1 
      End
 
    Set vr_i_year = vr_ycycle + (2820 * vr_cycle) + 474 
 
    If vr_i_year <= 0
      Begin 
        Set vr_i_year = vr_i_year - 1 
      End
    Set vr_yday = (vr_jdn - gfn_persian2_julian(vr_i_year, 1, 1)) + 1 
    If vr_yday <= 186 
       Begin
         Set vr_i_month = CEILING(Convert(Numeric(18,4),vr_yday) / 31) 
       End
    Else
       Begin
          Set vr_i_month = CEILING((Convert(Numeric(18,4),vr_yday) - 6) / 30)  
       End
       Set vr_i_day = (vr_jdn - gfn_persian2_julian(vr_i_year, vr_i_month, 1)) + 1 
 
      Return Convert(nvarchar(50),vr_i_day) + '-' +   Convert(nvarchar(50),vr_i_month) +'-' + Convert(nvarchar(50),vr_i_year)
End;


DROP FUNCTION IF EXISTS gfn_julian2_gregorian;

CREATE FUNCTION gfn_julian2_gregorian (vr_jdn bigint)
RETURNS VARCHAR(11)
AS
BEGIN
    DECLARE vr_jofst AS numeric(18,2)
    SET vr_jofst=2415020.5
    RETURN Convert(nvarchar(11),Convert(datetime,(vr_jdn- vr_jofst),113),110)
END;


DROP FUNCTION IF EXISTS gfn_persian2_gregorian;

CREATE FUNCTION gfn_persian2_gregorian (vr_year INTEGER, vr_month INTEGER, vr_day INTEGER)
RETURNS TIMESTAMP
AS
BEGIN
    RETURN gfn_julian2_gregorian(gfn_persian2_julian(vr_year, vr_month, vr_day))
END;


DROP FUNCTION IF EXISTS gfn_is_jalali_leap_year;

CREATE FUNCTION gfn_is_jalali_leap_year (vr_year INTEGER)
RETURNS BOOLEAN
AS
BEGIN
    DECLARE vr_a float = 0.025
    DECLARE vr_b float = 266
    
    DECLARE vr_leap_days0 float = 0, vr_leap_days1 float = 0
    
    IF COALESCE(vr_year, 0) = 0 RETURN 0
    ELSE IF vr_year > 0 BEGIN
		SET vr_leap_days0 = (((vr_year + 38) % 2820) * 0.24219) + vr_a
		SET vr_leap_days1 = (((vr_year + 39) % 2820) * 0.24219) + vr_a
    END
    ELSE BEGIN
		SET vr_leap_days0 = (((vr_year + 39) % 2820) * 0.24219) + vr_a
		SET vr_leap_days1 = (((vr_year + 40) % 2820) * 0.24219) + vr_a
    END
    
    DECLARE vr_frac0 INTEGER = CAST((vr_leap_days0 - CAST(vr_leap_days0 AS integer)) * 1000 AS integer)
    DECLARE vr_frac1 INTEGER = CAST((vr_leap_days1 - CAST(vr_leap_days1 AS integer)) * 1000 AS integer)
    
    IF vr_frac0 <= vr_b AND vr_frac1 > vr_b RETURN 1
    ELSE RETURN 0
    
    RETURN 1
END;

