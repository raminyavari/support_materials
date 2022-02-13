use kmacademy
go

DECLARE @ApplicationID uniqueidentifier = N'08C72552-4F2C-473F-B3B0-C2DACF8CD6A9'
DECLARE @FormID uniqueidentifier = N'AA26DCF4-7E81-4E9C-A501-54F4E5130384'

--DECLARE @RaaiVanForm uniqueidentifier = N''

DECLARE @ElementIDs GuidTableType
DECLARE @InstanceIDs GuidTableType
DECLARE @OwnerIDs GuidTableType
DECLARE @Filters FormFilterTableType

DECLARE @temp TABLE (
	InstanceID								uniqueidentifier,
	OwnerID									uniqueidentifier,
	CreationDate							datetime,
	[FE6D4918-6BB7-4F52-A808-1270514E4E14]	nvarchar(max),
	[0DF266FC-5C6C-46AE-870D-3AD921412A65]	nvarchar(max),
	[721E3FA4-9FA0-48B3-9BCA-DEE583950057]	nvarchar(max),
	[6BC86A0C-8F0E-4A8C-A2BA-F7901C931C5B]	nvarchar(max),
	[B9B3C01E-25E6-436A-9040-25ACD9DE8E44]	nvarchar(max),
	[EB403BC5-A542-465C-AAB3-1A6FF13E6DFF]	nvarchar(max),
	[87B35F76-AB6B-4590-8FD9-6CE2F7C31AB0]	nvarchar(max),
	[B0AD356E-7B1A-4FA0-B760-F52C8F1F9D1E]	nvarchar(max), --number
	[36A6CB3B-5CFE-450F-93D9-5F8D109174A0]	nvarchar(max),
	[76790EE8-BAE1-4E3F-925E-0A1B28AC58BD]	nvarchar(max),
	[F9966462-0EC7-41C9-9AAA-BED21199F648]	nvarchar(max)
)

INSERT INTO @temp
EXEC dbo.FG_GetFormRecords @ApplicationID, @FormID, @ElementIDs, @InstanceIDs, @OwnerIDs, @Filters, 0, 1000000, NULL, NULL

;WITH data AS
(
	SELECT	LOWER(LTRIM(RTRIM(t.[FE6D4918-6BB7-4F52-A808-1270514E4E14]))) AS email,
			(
				SELECT TOP(1) CAST(xx.Year AS varchar(10)) + '/' + 
					(CASE WHEN xx.Month < 10 THEN '0' ELSE '' END) +
					CAST(xx.Month AS varchar(10)) + '/' + 
					(CASE WHEN xx.Day < 10 THEN '0' ELSE '' END) +
					CAST(xx.Day AS varchar(10))
				FROM dbo.GFN_Gregorian2Persian(MIN(t.[CreationDate])) AS xx
			) AS first_request_time,
			(
				SELECT TOP(1) CAST(xx.Year AS varchar(10)) + '/' + 
					(CASE WHEN xx.Month < 10 THEN '0' ELSE '' END) +
					CAST(xx.Month AS varchar(10)) + '/' + 
					(CASE WHEN xx.Day < 10 THEN '0' ELSE '' END) +
					CAST(xx.Day AS varchar(10))
				FROM dbo.GFN_Gregorian2Persian(MAX(t.[CreationDate])) AS xx
			) AS last_request_time,
			COUNT(t.InstanceID) requests_count,
			ISNULL(MAX(t.[0DF266FC-5C6C-46AE-870D-3AD921412A65]), N'') AS company,
			ISNULL(MAX(t.[721E3FA4-9FA0-48B3-9BCA-DEE583950057]), N'') AS full_name,
			ISNULL(MAX(t.[6BC86A0C-8F0E-4A8C-A2BA-F7901C931C5B]), N'') AS position,
			ISNULL(MAX(t.[B9B3C01E-25E6-436A-9040-25ACD9DE8E44]), N'') AS activity,
			ISNULL(MAX(t.[EB403BC5-A542-465C-AAB3-1A6FF13E6DFF]), N'') AS size,
			ISNULL(MAX(t.[87B35F76-AB6B-4590-8FD9-6CE2F7C31AB0]), N'') AS location,
			ISNULL(MAX(t.[B0AD356E-7B1A-4FA0-B760-F52C8F1F9D1E]), N'') AS phone_number
	FROM @temp AS t
	WHERE LTRIM(RTRIM(ISNULL(t.[FE6D4918-6BB7-4F52-A808-1270514E4E14], N''))) <> N''
	GROUP BY LOWER(LTRIM(RTRIM(t.[FE6D4918-6BB7-4F52-A808-1270514E4E14])))
),
meta AS
(
	SELECT	d.email,
			CAST(MAX(CASE
				WHEN I.FormID = N'DEC0D527-1068-4E55-A8C3-6E7F265B807C' THEN 1
				ELSE 0
			END) AS bit) AS iso_km_assessment,
			CAST(MAX(CASE
				WHEN I.FormID = N'AE54C31C-478E-4F34-9723-50BAB24325DC' OR 
					I.FormID = N'AE54C31C-478E-4F34-9723-50BAB24325DC' THEN 1
				ELSE 0
			END) AS bit) AS raaivan_demo_request,
			CAST(MAX(CASE
				WHEN I.FormID = N'92EDD0DF-C7BB-4C31-AF16-02D943373B59' THEN 1
				ELSE 0
			END) AS bit) AS llm_assessment,
			CAST(MAX(CASE
				WHEN I.FormID = N'BFB19BDF-34D3-486A-9861-3C03E3A21730' THEN 1
				ELSE 0
			END) AS bit) AS kdm_assessment,
			CAST(MAX(CASE
				WHEN I.FormID = N'8F3F31E9-185D-465B-A279-8C95952FEA1F' THEN 1
				ELSE 0
			END) AS bit) AS gkm_level1_assessment,
			CAST(MAX(CASE
				WHEN I.FormID = N'50692CE3-19E2-48DF-AA0E-E04C294CB08A' THEN 1
				ELSE 0
			END) AS bit) AS apo_maturity_assessment
	FROM data AS d 
		INNER JOIN dbo.FG_InstanceElements AS e
		ON e.RefElementID = N'FE6D4918-6BB7-4F52-A808-1270514E4E14' AND 
			LOWER(LTRIM(RTRIM(ISNULL(e.TextValue, N'')))) = d.email
		INNER JOIN [dbo].[FG_InstanceElements] AS frm
		ON frm.TextValue = CAST(e.InstanceID AS varchar(max))
		INNER JOIN dbo.FG_FormInstances AS I
		ON I.InstanceID = frm.InstanceID
	GROUP BY d.email
)
SELECT	d.*,
		ISNULL(m.raaivan_demo_request, 0) AS raaivan_demo_request,
		ISNULL(m.iso_km_assessment, 0) AS iso_km_assessment,
		ISNULL(m.llm_assessment, 0) AS llm_assessment,
		ISNULL(m.kdm_assessment, 0) AS kdm_assessment,
		ISNULL(m.gkm_level1_assessment, 0) AS gkm_level1_assessment,
		ISNULL(m.apo_maturity_assessment, 0) AS apo_maturity_assessment
FROM data AS d
	LEFT JOIN meta AS m
	ON m.email = d.email

