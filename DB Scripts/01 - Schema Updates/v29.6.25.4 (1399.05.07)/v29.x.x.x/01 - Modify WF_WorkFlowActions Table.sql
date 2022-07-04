USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER TABLE [dbo].[WF_Actions]
ADD [SaveToFormElementID] [uniqueidentifier] NULL
GO


ALTER TABLE [dbo].[WF_Actions]  WITH CHECK ADD  CONSTRAINT [FK_WF_Actions_FG_ExtendedFormElements] FOREIGN KEY([SaveToFormElementID])
REFERENCES [dbo].[FG_ExtendedFormElements] ([ElementID])
GO

ALTER TABLE [dbo].[WF_Actions] CHECK CONSTRAINT [FK_WF_Actions_FG_ExtendedFormElements]
GO
