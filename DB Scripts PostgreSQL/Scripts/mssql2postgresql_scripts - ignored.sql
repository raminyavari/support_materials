
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



/*
DROP PROCEDURE IF EXISTS cn_i_am_expert;

CREATE PROCEDURE cn_i_am_expert
	vr_application_id							UUID,
	vr_user_id									UUID,
	vr_expertise_domain					 VARCHAR(255),
	vr_now								 TIMESTAMP,
	vr_default_min_acceptable_referrals_count	 INTEGER,
	vr_default_min_acceptable_confirms_percentage INTEGER
WITH ENCRYPTION
AS
BEGIN TRANSACTION
	SET NOCOUNT ON
	
	SET vr_expertise_domain = gfn_verify_string(vr_expertise_domain)
	
	DECLARE vr_nodeTypeID UUID = cn_fn_get_expertise_node_type_id(vr_application_id)
	
	DECLARE vr_node_id UUID = (
		SELECT TOP(1) NodeID 
		FROM cn_nodes 
		WHERE ApplicationID = vr_application_id AND 
			NodeTypeID = vr_nodeTypeID AND Name = vr_expertise_domain
	)
	
	DECLARE vr__result INTEGER, vr__error_message varchar(1000)
	
	IF vr_node_id IS NULL BEGIN
		SET vr_node_id = gen_random_uuid()
		
		EXEC cn_p_add_node vr_application_id, vr_node_id, NULL, vr_nodeTypeID, 
			NULL, NULL, NULL, vr_expertise_domain, NULL, NULL, 0, vr_user_id, vr_now, NULL, 
			NULL, NULL, vr__result output, vr__error_message output
			
		IF vr__result <= 0 BEGIN
			SELECT -1
			ROLLBACK TRANSACTION
			RETURN
		END
	END
	
	IF EXISTS(SELECT TOP(1) * FROM cn_experts
		WHERE NodeID = vr_node_id AND UserID = vr_user_id) BEGIN
	
		EXEC cn_p_calculate_social_expertise vr_application_id, vr_node_id, vr_user_id, 
			vr_default_min_acceptable_referrals_count, vr_default_min_acceptable_confirms_percentage, 
			vr__result output
	END
	ELSE BEGIN
		INSERT INTO cn_experts(
			ApplicationID,
			NodeID,
			UserID,
			Approved,
			ReferralsCount,
			ConfirmsPercentage,
			SocialApproved,
			UniqueID
		)
		VALUES(
			vr_application_id,
			vr_node_id,
			vr_user_id,
			0,
			0,
			0,
			0,
			gen_random_uuid()
		)
		
		SET vr__result = @vr_rowcount
	END
	
	IF vr__result <= 0 SELECT NULL
	ELSE SELECT vr_node_id
COMMIT TRANSACTION;
*/

-- User Groups

DROP PROCEDURE IF EXISTS usr_create_user_group;

CREATE PROCEDURE usr_create_user_group
	vr_application_id	UUID,
	vr_group_id		UUID,
	vr_title		 VARCHAR(512),
	vr_description VARCHAR(2000),
	vr_creator_user_id	UUID,
	vr_now		 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_title = gfn_verify_string(vr_title)
	SET vr_description = gfn_verify_string(vr_description)
	
	INSERT usr_user_groups (
		ApplicationID,
		GroupID,
		Title,
		description,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	VALUES (
		vr_application_id,
		vr_group_id,
		vr_title,
		vr_description,
		vr_creator_user_id,
		vr_now,
		0
	)
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_modify_user_group;

CREATE PROCEDURE usr_modify_user_group
	vr_application_id		UUID,
	vr_group_id			UUID,
	vr_title			 VARCHAR(512),
	vr_description	 VARCHAR(2000),
	vr_last_modifier_user_id	UUID,
	vr_now			 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	SET vr_title = gfn_verify_string(vr_title)
	SET vr_description = gfn_verify_string(vr_description)
	
	UPDATE usr_user_groups
		SET Title = vr_title,
			description = vr_description,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND GroupID = vr_group_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_remove_user_group;

CREATE PROCEDURE usr_remove_user_group
	vr_application_id		UUID,
	vr_group_id			UUID,
	vr_last_modifier_user_id	UUID,
	vr_now			 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE usr_user_groups
		SET deleted = TRUE,
			LastModifierUserID = vr_last_modifier_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND GroupID = vr_group_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_add_user_group_members;

CREATE PROCEDURE usr_add_user_group_members
	vr_application_id		UUID,
	vr_group_id			UUID,
	vr_strUserIDs			varchar(max),
	vr_delimiter			char,
	vr_current_user_id		UUID,
	vr_now			 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType
	
	INSERT INTO vr_user_ids (Value)
	SELECT DISTINCT ref.value
	FROM gfn_str_to_guid_table(vr_strUserIDs, vr_delimiter) AS ref
	
	DECLARE vr_changed_count INTEGER = 0
	
	UPDATE M
		SET deleted = FALSE,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	FROM vr_user_ids AS u
		INNER JOIN usr_user_group_members AS m
		ON m.user_id = u.value
	WHERE m.application_id = vr_application_id AND m.group_id = vr_group_id
		
	SET vr_changed_count = @vr_rowcount
	
	INSERT INTO usr_user_group_members (
		ApplicationID,
		GroupID,
		UserID,
		CreatorUserID,
		CreationDate,
		Deleted
	)
	SELECT vr_application_id, vr_group_id, u.value, vr_current_user_id, vr_now, 0
	FROM vr_user_ids AS u
		LEFT JOIN usr_user_group_members AS m
		ON m.application_id = vr_application_id AND m.group_id = vr_group_id AND m.user_id = u.value
	WHERE m.group_id IS NULL
	
	SELECT @vr_rowcount + vr_changed_count
END;


DROP PROCEDURE IF EXISTS usr_remove_user_group_members;

CREATE PROCEDURE usr_remove_user_group_members
	vr_application_id		UUID,
	vr_group_id			UUID,
	vr_strUserIDs			varchar(max),
	vr_delimiter			char,
	vr_current_user_id		UUID,
	vr_now			 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids GuidTableType
	
	INSERT INTO vr_user_ids (Value)
	SELECT DISTINCT ref.value
	FROM gfn_str_to_guid_table(vr_strUserIDs, vr_delimiter) AS ref
	
	DECLARE vr_changed_count INTEGER = 0
	
	UPDATE M
		SET deleted = TRUE,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	FROM vr_user_ids AS u
		INNER JOIN usr_user_group_members AS m
		ON m.user_id = u.value
	WHERE m.application_id = vr_application_id AND m.group_id = vr_group_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_set_user_group_permission;

CREATE PROCEDURE usr_set_user_group_permission
	vr_application_id		UUID,
	vr_group_id			UUID,
	vr_role_id				UUID,
	vr_current_user_id		UUID,
	vr_now			 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(
		SELECT TOP(1) *
		FROM usr_user_group_permissions
		WHERE ApplicationID = vr_application_id AND GroupID = vr_group_id AND RoleID = vr_role_id
	) BEGIN
		UPDATE usr_user_group_permissions
			SET deleted = FALSE,
				LastModifierUserID = vr_current_user_id,
				LastModificationDate = vr_now
		WHERE ApplicationID = vr_application_id AND GroupID = vr_group_id AND RoleID = vr_role_id
	END
	ELSE BEGIN
		INSERT INTO usr_user_group_permissions (
			ApplicationID,
			GroupID,
			RoleID,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES (
			vr_application_id,
			vr_group_id,
			vr_role_id,
			vr_current_user_id,
			vr_now,
			0
		)
	END
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_unset_user_group_permission;

CREATE PROCEDURE usr_unset_user_group_permission
	vr_application_id		UUID,
	vr_group_id			UUID,
	vr_role_id				UUID,
	vr_current_user_id		UUID,
	vr_now			 TIMESTAMP
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE usr_user_group_permissions
		SET deleted = TRUE,
			LastModifierUserID = vr_current_user_id,
			LastModificationDate = vr_now
	WHERE ApplicationID = vr_application_id AND GroupID = vr_group_id AND RoleID = vr_role_id
	
	SELECT @vr_rowcount
END;


DROP PROCEDURE IF EXISTS usr_get_user_groups;

CREATE PROCEDURE usr_get_user_groups
	vr_application_id		UUID,
	vr_strGroupIDs		varchar(max),
	vr_delimiter			char
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_group_ids GuidTableType
	
	INSERT INTO vr_group_ids (Value)
	SELECT DISTINCT ref.value
	FROM gfn_str_to_guid_table(vr_strGroupIDs, vr_delimiter) AS ref
	
	DECLARE vr_groups_count INTEGER = (SELECT COUNT(*) FROM vr_group_ids)
	
	SELECT	g.group_id,
			g.title,
			g.description
	FROM usr_user_groups AS g
	WHERE g.application_id = vr_application_id AND 
		(vr_groups_count = 0 OR g.group_id IN (SELECT ref.value FROM vr_group_ids AS ref)) AND
		g.deleted = FALSE
END;


DROP PROCEDURE IF EXISTS usr_get_user_group_members;

CREATE PROCEDURE usr_get_user_group_members
	vr_application_id		UUID,
	vr_group_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_user_ids KeyLessGuidTableType
	
	INSERT INTO vr_user_ids (Value)
	SELECT DISTINCT m.user_id
	FROM usr_user_groups AS g
		INNER JOIN usr_user_group_members AS m
		ON m.application_id = vr_application_id AND m.group_id = g.group_id
		INNER JOIN users_normal AS un
		ON un.application_id = vr_application_id AND un.user_id = m.user_id
	WHERE g.application_id = vr_application_id AND g.group_id = vr_group_id AND
		m.deleted = FALSE AND un.is_approved = TRUE
		
	EXEC usr_p_get_users_by_ids vr_application_id, vr_user_ids
END;


DROP PROCEDURE IF EXISTS usr_p_get_access_roles_by_ids;

CREATE PROCEDURE usr_p_get_access_roles_by_ids
	vr_application_id	UUID,
	vr_role_idsTemp	GuidTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_role_ids GuidTableType
	INSERT INTO vr_role_ids SELECT * FROM vr_role_idsTemp
	
	SELECT a.role_id, a.name, a.title
	FROM vr_role_ids AS r
		INNER JOIN usr_access_roles AS a
		ON a.role_id = r.value
	WHERE a.application_id = vr_application_id
END;


DROP PROCEDURE IF EXISTS usr_get_access_roles;

CREATE PROCEDURE usr_get_access_roles
	vr_application_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_role_ids GuidTableType
	
	INSERT INTO vr_role_ids (Value)
	SELECT RoleID
	FROM usr_access_roles
	WHERE ApplicationID = vr_application_id
	
	EXEC usr_p_get_access_roles_by_ids vr_application_id, vr_role_ids
END;


DROP PROCEDURE IF EXISTS usr_get_user_group_access_roles;

CREATE PROCEDURE usr_get_user_group_access_roles
	vr_application_id		UUID,
	vr_group_id			UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_role_ids GuidTableType
	
	INSERT INTO vr_role_ids (Value)
	SELECT DISTINCT r.role_id
	FROM usr_user_groups AS g
		INNER JOIN usr_user_group_permissions AS p
		ON p.application_id = vr_application_id AND p.group_id = g.group_id
		INNER JOIN usr_access_roles AS r
		ON r.application_id = vr_application_id AND r.role_id = p.role_id
	WHERE g.application_id = vr_application_id AND g.group_id = vr_group_id 
		AND g.deleted = FALSE AND p.deleted = FALSE
	
	EXEC usr_p_get_access_roles_by_ids vr_application_id, vr_role_ids
END;


DROP PROCEDURE IF EXISTS usr_check_user_group_permissions;

CREATE PROCEDURE usr_check_user_group_permissions
	vr_application_id		UUID,
	vr_user_id				UUID,
	vr_permissions_temp	StringTableType readonly
WITH ENCRYPTION, RECOMPILE
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE vr_permissions StringTableType
	INSERT INTO vr_permissions SELECT * FROM vr_permissions_temp
	
	SELECT DISTINCT r.name AS value
	FROM usr_user_group_members AS m
		INNER JOIN usr_user_groups AS g
		ON g.application_id = vr_application_id AND g.group_id = m.group_id
		INNER JOIN usr_user_group_permissions AS p
		ON p.application_id = vr_application_id AND p.group_id = g.group_id
		INNER JOIN usr_access_roles AS r
		ON r.application_id = vr_application_id AND r.role_id = p.role_id
	WHERE m.application_id = vr_application_id AND m.user_id = vr_user_id AND 
		(LOWER(r.name) IN (SELECT LOWER(ref.value) FROM vr_permissions AS ref)) AND
		m.deleted = FALSE AND g.deleted = FALSE AND p.deleted = FALSE
END;

-- end of User Groups


DROP PROCEDURE IF EXISTS prvc_refine_access_roles;

CREATE PROCEDURE prvc_refine_access_roles
	vr_application_id		UUID
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
    DECLARE vr_tbl Table(ID INTEGER identity(1,1) primary key clustered, 
	OldValue varchar(1000), NewValue varchar(1000), Title VARCHAR(1000), UQID UUID)

	INSERT INTO vr_tbl (OldValue, NewValue, Title)
	VALUES	('AssignUsersAsExpert','', N''),
			('AssignUsersToDepartments','', N''),
			('AssignUsersToProcesses','', N''),
			('AssignUsersToProjects','', N''),
			('CopCreation','', N''),
			('DefaultContentRegistration','', N''),
			('DepartmentsManipulation','', N''),
			('KDsManagement','', N''),
			('ManageDepartmentGroups','', N''),
			('OrganizationalProperties','', N''),
			('ProcessesManagement','', N''),
			('ProjectsManagement','', N''),
			('Navigation','', N''),
			('VisualKMap','', N''),
			('AssignUsersToClassifications','ManageConfidentialityLevels', N'مدیریت سطوح محرمانگی'),
			('ContentsManagement','ContentsManagement', N'مديريت مستندات'),
			('DepsAndUsersImport','DataImport', N'ورود اطلاعات از طریق XML'),
			('ManagementSystem','ManagementSystem', N'مديريت سيستم'),
			('ManageOntology','ManageOntology', N'پیکربندی نقشه'),
			('Reports','Reports', N'گزارشات'),
			('UserGroupsManagement','UserGroupsManagement', N'مدیران سامانه'),
			('UsersManagement','UsersManagement', N'کاربران'),
			('ManageWorkflow','ManageWorkflow', N'جریان های کاری'),
			('ManageForms','ManageForms', N'فرم ها'),
			('ManagePolls','ManagePolls', N'نظرسنجی ها'),
			('KnowledgeAdmin','KnowledgeAdmin', N'فرآیندهای ارزیابی دانش'),
			('SMSEMailNotifier','SMSEMailNotifier', N'پیام کوتاه و پست الکترونیکی'),
			('','ManageQA', N'پرسش و پاسخ'),
			('','RemoteServers', N'سرورهای راه دور')
			
	UPDATE AR
		SET ar.name = t.new_value
	FROM vr_tbl AS t
		INNER JOIN usr_access_roles AS ar
		ON ar.application_id = vr_application_id AND LOWER(ar.name) = LOWER(t.old_value)
		
	DELETE UAR
	FROM usr_user_group_permissions AS uar
		INNER JOIN usr_access_roles AS ar
		ON ar.application_id = vr_application_id AND ar.role_id = Uar.role_id
	WHERE uar.application_id = vr_application_id AND 
		ar.name NOT IN (SELECT NewValue FROM vr_tbl AS t WHERE t.new_value <> '')
	
	DELETE AR
	FROM usr_access_roles AS ar
	WHERE ar.application_id = vr_application_id AND 
		ar.name NOT IN (SELECT NewValue FROM vr_tbl AS t WHERE t.new_value <> '')

	DELETE vr_tbl
	WHERE NewValue = ''

	INSERT INTO usr_access_roles (ApplicationID, RoleID, Name, Title)
	SELECT vr_application_id, gen_random_uuid(), t.new_value, N''
	FROM vr_tbl AS t
	WHERE t.new_value <> '' AND
		LOWER(t.new_value) NOT IN (
			SELECT LOWER(Name) 
			FROM usr_access_roles
			WHERE ApplicationID = vr_application_id
		)

	UPDATE AR
		SET Title = REPLACE(REPLACE(t.title, N'ي', N'ی'), N'ك', N'ک')
	FROM vr_tbl AS t
		INNER JOIN usr_access_roles AS ar
		ON LOWER(ar.name) = LOWER(t.new_value)
	WHERE ar.application_id = vr_application_id
		
	UPDATE T
		SET UQID = ar.role_id
	FROM vr_tbl AS t
		INNER JOIN usr_access_roles AS ar
		ON LOWER(ar.name) = LOWER(t.new_value)
	WHERE ar.application_id = vr_application_id
	
	DELETE UGP
	FROM usr_user_group_permissions AS ugp
		INNER JOIN (
			SELECT	ROW_NUMBER() OVER 
						(PARTITION BY uar.group_id, t.uqid ORDER BY uar.role_id ASC) AS row_number,
					uar.group_id, 
					uar.role_id, 
					t.uqid
			FROM vr_tbl AS t
				INNER JOIN usr_user_group_permissions AS uar
				INNER JOIN usr_access_roles AS ar
				ON ar.application_id = vr_application_id AND ar.role_id = Uar.role_id
				ON uar.application_id = vr_application_id AND LOWER(ar.name) = LOWER(t.new_value)
		) AS r
		ON r.group_id = ugp.group_id AND r.role_id = ugp.role_id
	WHERE r.row_number > 1
	
	UPDATE UAR
		SET RoleID = t.uqid
	FROM vr_tbl AS t
		INNER JOIN usr_user_group_permissions AS uar
		INNER JOIN usr_access_roles AS ar
		ON ar.application_id = vr_application_id AND ar.role_id = Uar.role_id
		ON uar.application_id = vr_application_id AND LOWER(ar.name) = LOWER(t.new_value)

	DELETE usr_access_roles
	WHERE ApplicationID = vr_application_id AND 
		RoleID NOT IN (SELECT UQID FROM vr_tbl)
    
    RETURN 1
END;