USE [EKM_APP]
GO


IF EXISTS(select * FROM sys.views where name = 'PRVC_View_Confidentialities')
DROP VIEW [dbo].[PRVC_View_Confidentialities]
GO

DROP TABLE [dbo].[PRVC_PrivacyType]
GO