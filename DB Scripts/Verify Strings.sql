USE [EKM_App]
GO

SET ANSI_PADDING ON
GO



UPDATE [dbo].[CN_Lists]
	SET Name = [dbo].[GFN_VerifyString](Name),
		[Description] = [dbo].[GFN_VerifyString]([Description])
GO


UPDATE [dbo].[CN_NodeTypes]
	SET Name = [dbo].[GFN_VerifyString](Name),
		[Description] = [dbo].[GFN_VerifyString]([Description])
GO


UPDATE [dbo].[CN_Nodes]
	SET Name = [dbo].[GFN_VerifyString](Name),
		[Description] = [dbo].[GFN_VerifyString]([Description]),
		Tags = [dbo].[GFN_VerifyString](Tags)
GO


UPDATE [dbo].[CN_Services]
	SET [ServiceTitle] = [dbo].[GFN_VerifyString]([ServiceTitle]),
		[ServiceDescription] = [dbo].[GFN_VerifyString]([ServiceDescription])
GO


UPDATE [dbo].[CN_Properties]
	SET Name = [dbo].[GFN_VerifyString](Name),
		[Description] = [dbo].[GFN_VerifyString]([Description])
GO


UPDATE [dbo].[CN_Tags]
	SET Tag = [dbo].[GFN_VerifyString](Tag)
GO


UPDATE [dbo].[DCT_Trees]
	SET Name = [dbo].[GFN_VerifyString](Name),
		[Description] = [dbo].[GFN_VerifyString]([Description])
GO


UPDATE [dbo].[EVT_Events]
	SET Title = [dbo].[GFN_VerifyString](Title),
		[Description] = [dbo].[GFN_VerifyString]([Description])
GO


UPDATE [dbo].[KW_ConfidentialityLevels]
	SET Title = [dbo].[GFN_VerifyString](Title)
GO


UPDATE [dbo].[KW_KnowledgeCards]
	SET Title = [dbo].[GFN_VerifyString](Title),
		[Description] = [dbo].[GFN_VerifyString]([Description])
GO


UPDATE [dbo].[KW_KnowledgeTypes]
	SET Name = [dbo].[GFN_VerifyString](Name),
		[Description] = [dbo].[GFN_VerifyString]([Description])
GO


UPDATE [dbo].[KWF_Statuses]
	SET Name = [dbo].[GFN_VerifyString](Name),
		[Description] = [dbo].[GFN_VerifyString]([Description]),
		PersianName = [dbo].[GFN_VerifyString](PersianName)
GO


UPDATE [dbo].[QA_Answers]
	SET AnswerBody = [dbo].[GFN_VerifyString](AnswerBody)
GO


UPDATE [dbo].[QA_Questions]
	SET Title = [dbo].[GFN_VerifyString](Title),
		[Description] = [dbo].[GFN_VerifyString]([Description])
GO


UPDATE [dbo].[SH_Comments]
	SET [Description] = [dbo].[GFN_VerifyString]([Description])
GO


UPDATE [dbo].[SH_Posts]
	SET [Description] = [dbo].[GFN_VerifyString]([Description])
GO


UPDATE [dbo].[SH_PostShares]
	SET [Description] = [dbo].[GFN_VerifyString]([Description])
GO


UPDATE [dbo].[SH_PostTypes]
	SET Name = [dbo].[GFN_VerifyString](Name),
		PersianName = [dbo].[GFN_VerifyString](PersianName)
GO


UPDATE [dbo].[WK_Titles]
	SET Title = [dbo].[GFN_VerifyString](Title)
GO


UPDATE [dbo].[WK_Paragraphs]
	SET Title = [dbo].[GFN_VerifyString](Title),
		BodyText = [dbo].[GFN_VerifyString](BodyText)
GO


UPDATE [dbo].[WK_Changes]
	SET Title = [dbo].[GFN_VerifyString](Title),
		BodyText = [dbo].[GFN_VerifyString](BodyText)
GO


UPDATE [dbo].[USR_Profile]
	SET FirstName = [dbo].[GFN_VerifyString](FirstName),
		LastName = [dbo].[GFN_VerifyString](LastName)
GO


UPDATE [dbo].[WF_States]
	SET Title = [dbo].[GFN_VerifyString](Title)
GO


UPDATE [dbo].[WF_WorkFlows]
	SET Name = [dbo].[GFN_VerifyString](Name),
		[Description] = [dbo].[GFN_VerifyString]([Description])
GO


UPDATE [dbo].[WF_WorkFlowStates]
	SET [Description] = [dbo].[GFN_VerifyString]([Description]),
		[DataNeedsDescription] = [dbo].[GFN_VerifyString]([DataNeedsDescription])
GO


UPDATE [dbo].[WF_StateConnections]
	SET [Label] = [dbo].[GFN_VerifyString](Label),
		[NodeTypeDescription] = [dbo].[GFN_VerifyString](NodeTypeDescription),
		[AttachmentTitle] = [dbo].[GFN_VerifyString](AttachmentTitle)
GO


UPDATE [dbo].[WF_StateDataNeeds]
	SET [Description] = [dbo].[GFN_VerifyString]([Description])
GO


UPDATE [dbo].[WF_StateConnectionForms]
	SET [Description] = [dbo].[GFN_VerifyString]([Description])
GO


UPDATE [dbo].[WF_AutoMessages]
	SET [BodyText] = [dbo].[GFN_VerifyString]([BodyText])
GO


UPDATE [dbo].[WF_History]
	SET [Description] = [dbo].[GFN_VerifyString]([Description])
GO



SET ANSI_PADDING OFF
GO