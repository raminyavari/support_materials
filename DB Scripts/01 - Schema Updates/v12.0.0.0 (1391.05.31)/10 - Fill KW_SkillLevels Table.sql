USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



INSERT INTO [dbo].[KW_SkillLevels]([LevelID], [Name], [IsPractical], [Deleted])
VALUES (1, N'آشنایی', 0, 0)
           
INSERT INTO [dbo].[KW_SkillLevels]([LevelID], [Name], [IsPractical], [Deleted])
VALUES (2, N'شناخت عمومی', 0, 0)

INSERT INTO [dbo].[KW_SkillLevels]([LevelID], [Name], [IsPractical], [Deleted])
VALUES (3, N'آگاهی', 0, 0)

INSERT INTO [dbo].[KW_SkillLevels]([LevelID], [Name], [IsPractical], [Deleted])
VALUES (4, N'تسلط کامل', 0, 0)

INSERT INTO [dbo].[KW_SkillLevels]([LevelID], [Name], [IsPractical], [Deleted])
VALUES (5, N'مبتدی', 1, 0)
           
INSERT INTO [dbo].[KW_SkillLevels]([LevelID], [Name], [IsPractical], [Deleted])
VALUES (6, N'معمولی', 1, 0)

INSERT INTO [dbo].[KW_SkillLevels]([LevelID], [Name], [IsPractical], [Deleted])
VALUES (7, N'نیمه حرفه ای', 1, 0)

INSERT INTO [dbo].[KW_SkillLevels]([LevelID], [Name], [IsPractical], [Deleted])
VALUES (8, N'حرفه ای', 1, 0)
           
GO