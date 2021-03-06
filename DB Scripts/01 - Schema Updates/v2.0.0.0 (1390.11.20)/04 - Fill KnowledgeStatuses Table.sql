USE [EKM_APP]
GO

INSERT INTO [dbo].[KWF_Statuses]
           ([StatusID], [Name], [PersianName])
     VALUES
           (1, 'Personal', 'شخصی')
GO

INSERT INTO [dbo].[KWF_Statuses]
           ([StatusID], [Name], [PersianName])
     VALUES
           (2, 'ManagerEvaluation', 'در حال بررسی توسط مدیر دپارتمان')
GO

INSERT INTO [dbo].[KWF_Statuses]
           ([StatusID], [Name], [PersianName])
     VALUES
           (3, 'SentBackForRevision', 'ارجاع برای اصلاح')
GO

INSERT INTO [dbo].[KWF_Statuses]
           ([StatusID], [Name], [PersianName])
     VALUES
           (4, 'ExpertEvaluation', 'در حال بررسی توسط خبره ها')
GO

INSERT INTO [dbo].[KWF_Statuses]
           ([StatusID], [Name], [PersianName])
     VALUES
           (5, 'Rejected', 'رد شده')
GO

INSERT INTO [dbo].[KWF_Statuses]
           ([StatusID], [Name], [PersianName])
     VALUES
           (6, 'Accepted', 'تایید شده')
GO

INSERT INTO [dbo].[KWF_Statuses]
           ([StatusID], [Name], [PersianName])
     VALUES
           (7, 'ConditionalAccept', 'تایید مشروط')
GO