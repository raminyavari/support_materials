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

