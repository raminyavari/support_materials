USE [EKM_App]
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

