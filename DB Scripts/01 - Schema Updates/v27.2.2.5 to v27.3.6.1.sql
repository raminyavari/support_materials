USE [EKM_App]
GO


ALTER TABLE [dbo].[NodeMetrics] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[USR_FriendSuggestions] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[USR_HonorsAndAwards] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[DCT_Trees] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[CN_Nodes] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[WF_StateDataNeeds] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[DCT_TreeNodes] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[Attachments] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[CN_ContributionLimits] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[USR_PasswordsHistory] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[KWF_Statuses] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[KW_ConfidentialityLevels] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[AddedForms] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[KW_UsersConfidentialityLevels] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[WF_History] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[LG_ErrorLogs] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[SH_PostShares] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[PRVC_ConfidentialityLevels] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[KW_KnowledgeTypes] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[PRVC_Confidentialities] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[KW_Knowledges] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[USR_EmailAddresses] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[NTFN_Notifications] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[LG_Logs] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[USR_PhoneNumbers] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[CN_NodeCreators] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[KW_CreatorUsers] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[CN_Lists] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[KW_KnowledgeCards] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[CN_Services] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[CN_AdminTypeLimits] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[AccessRoles] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[CN_Extensions] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[KW_SkillLevels] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[CN_ServiceAdmins] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[KW_KnowledgeAssets] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[RV_TaggedItems] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[OrganProfile] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[KW_NodeRelatedTrees] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[NQuestions] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[DCT_FileContents] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[CN_FreeUsers] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[KW_RefrenceUsers] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[MSG_Messages] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[RV_ID2Guid] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[UserGroups] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[NTFN_MessageTemplates] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[UserGroupUsers] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[MSG_MessageDetails] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[KW_LearningMethods] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[NewsObjectTypes] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[FG_ExtendedFormElements] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[USR_TemporaryUsers] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[PersonalNews] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[TMP_KW_KnowledgeTypes] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[FG_FormOwners] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[USR_Invitations] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[KW_TripForms] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[MetricsConst] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[KW_Companies] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[CN_ListNodes] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[TMP_KW_Questions] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[FG_ElementLimits] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[KW_RelatedNodes] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[TMP_KW_TypeQuestions] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[GapColorConst] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[SH_PostTypes] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[PRVC_PrivacyType] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[KW_KnowledgeManagers] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[SH_Posts] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[WF_StateDataNeedInstances] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[KW_ExperienceHolders] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[TMP_KW_CandidateRelations] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[FG_InstanceElements] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[WK_Titles] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[Countries] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[ProfileScientific] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[KW_FeedBacks] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[WF_AutoMessages] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[ProfileJobs] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[ProfileInstitute] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[TMP_KW_QuestionAnswers] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[NTFN_Dashboards] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[ProfileEducation] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[KWF_Managers] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[RV_DeletedStates] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[SH_Comments] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[TMP_KW_History] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[CN_NodeMembers] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[FG_FormInstances] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[FG_ExtendedForms] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[KWF_Paraphs] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[KWF_Experts] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[SH_ShareLikes] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[RV_Variables] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[TMP_KW_TempKnowledgeTypeIDs] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[SH_CommentLikes] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[CN_Experts] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[WK_Paragraphs] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[TMP_KW_FeedBacks] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[WF_WorkFlowOwners] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[CN_Properties] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[CN_ExpertiseReferrals] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[KWF_Evaluators] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[WF_States] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[QA_Questions] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[WK_Changes] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[CN_NodeLikes] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[CN_NodeProperties] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[WF_WorkFlows] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[QA_Answers] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[AttachmentFiles] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[WF_StateConnections] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[PRVC_Audience] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[NGeneralQuestions] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[CN_NodeRelations] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[USR_PassResetTickets] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[EVT_Events] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[USR_Profile] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[UserGroupAccessRoles] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[WF_StateConnectionForms] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[QA_QuestionLikes] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[USR_LanguageNames] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[EVT_RelatedUsers] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[USR_UserLanguages] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[Cities] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[CN_ListAdmins] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[QA_RefNodes] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[USR_ItemVisits] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[NTFN_NotificationMessageTemplates] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[CN_Tags] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[WF_WorkFlowStates] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[EVT_RelatedNodes] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[WF_HistoryFormInstances] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[QA_RefUsers] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[USR_JobExperiences] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[RV_EmailQueue] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[USR_EmailContacts] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[NodeSetting] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[NTFN_UserMessagingActivation] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[RV_SentEmails] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[USR_Friends] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[USR_EducationalExperiences] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[CN_NodeTypes] ADD [ApplicationID] uniqueidentifier NULL 
GO
ALTER TABLE [dbo].[DCT_TreeTypes] ADD [ApplicationID] uniqueidentifier NULL 
GO


UPDATE [dbo].[AppSetting] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO

ALTER TABLE [dbo].[AppSetting]  WITH CHECK ADD CONSTRAINT [FK_AppSetting_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[NodeMetrics]  WITH CHECK ADD CONSTRAINT [FK_NodeMetrics_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[USR_FriendSuggestions]  WITH CHECK ADD CONSTRAINT [FK_USR_FriendSuggestions_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[USR_HonorsAndAwards]  WITH CHECK ADD CONSTRAINT [FK_USR_HonorsAndAwards_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[DCT_Trees]  WITH CHECK ADD CONSTRAINT [FK_DCT_Trees_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[CN_Nodes]  WITH CHECK ADD CONSTRAINT [FK_CN_Nodes_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[WF_StateDataNeeds]  WITH CHECK ADD CONSTRAINT [FK_WF_StateDataNeeds_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[DCT_TreeNodes]  WITH CHECK ADD CONSTRAINT [FK_DCT_TreeNodes_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[Attachments]  WITH CHECK ADD CONSTRAINT [FK_Attachments_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[CN_ContributionLimits]  WITH CHECK ADD CONSTRAINT [FK_CN_ContributionLimits_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[USR_PasswordsHistory]  WITH CHECK ADD CONSTRAINT [FK_USR_PasswordsHistory_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[KWF_Statuses]  WITH CHECK ADD CONSTRAINT [FK_KWF_Statuses_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[KW_ConfidentialityLevels]  WITH CHECK ADD CONSTRAINT [FK_KW_ConfidentialityLevels_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[AddedForms]  WITH CHECK ADD CONSTRAINT [FK_AddedForms_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[KW_UsersConfidentialityLevels]  WITH CHECK ADD CONSTRAINT [FK_KW_UsersConfidentialityLevels_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[WF_History]  WITH CHECK ADD CONSTRAINT [FK_WF_History_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[LG_ErrorLogs]  WITH CHECK ADD CONSTRAINT [FK_LG_ErrorLogs_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[SH_PostShares]  WITH CHECK ADD CONSTRAINT [FK_SH_PostShares_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[PRVC_ConfidentialityLevels]  WITH CHECK ADD CONSTRAINT [FK_PRVC_ConfidentialityLevels_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[KW_KnowledgeTypes]  WITH CHECK ADD CONSTRAINT [FK_KW_KnowledgeTypes_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[PRVC_Confidentialities]  WITH CHECK ADD CONSTRAINT [FK_PRVC_Confidentialities_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[KW_Knowledges]  WITH CHECK ADD CONSTRAINT [FK_KW_Knowledges_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[USR_EmailAddresses]  WITH CHECK ADD CONSTRAINT [FK_USR_EmailAddresses_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[NTFN_Notifications]  WITH CHECK ADD CONSTRAINT [FK_NTFN_Notifications_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[LG_Logs]  WITH CHECK ADD CONSTRAINT [FK_LG_Logs_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[USR_PhoneNumbers]  WITH CHECK ADD CONSTRAINT [FK_USR_PhoneNumbers_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[CN_NodeCreators]  WITH CHECK ADD CONSTRAINT [FK_CN_NodeCreators_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[KW_CreatorUsers]  WITH CHECK ADD CONSTRAINT [FK_KW_CreatorUsers_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[CN_Lists]  WITH CHECK ADD CONSTRAINT [FK_CN_Lists_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[KW_KnowledgeCards]  WITH CHECK ADD CONSTRAINT [FK_KW_KnowledgeCards_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[CN_Services]  WITH CHECK ADD CONSTRAINT [FK_CN_Services_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[CN_AdminTypeLimits]  WITH CHECK ADD CONSTRAINT [FK_CN_AdminTypeLimits_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[AccessRoles]  WITH CHECK ADD CONSTRAINT [FK_AccessRoles_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[CN_Extensions]  WITH CHECK ADD CONSTRAINT [FK_CN_Extensions_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[KW_SkillLevels]  WITH CHECK ADD CONSTRAINT [FK_KW_SkillLevels_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[CN_ServiceAdmins]  WITH CHECK ADD CONSTRAINT [FK_CN_ServiceAdmins_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[KW_KnowledgeAssets]  WITH CHECK ADD CONSTRAINT [FK_KW_KnowledgeAssets_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[RV_TaggedItems]  WITH CHECK ADD CONSTRAINT [FK_RV_TaggedItems_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[OrganProfile]  WITH CHECK ADD CONSTRAINT [FK_OrganProfile_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[KW_NodeRelatedTrees]  WITH CHECK ADD CONSTRAINT [FK_KW_NodeRelatedTrees_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[NQuestions]  WITH CHECK ADD CONSTRAINT [FK_NQuestions_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[DCT_FileContents]  WITH CHECK ADD CONSTRAINT [FK_DCT_FileContents_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[CN_FreeUsers]  WITH CHECK ADD CONSTRAINT [FK_CN_FreeUsers_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[KW_RefrenceUsers]  WITH CHECK ADD CONSTRAINT [FK_KW_RefrenceUsers_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[MSG_Messages]  WITH CHECK ADD CONSTRAINT [FK_MSG_Messages_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[RV_ID2Guid]  WITH CHECK ADD CONSTRAINT [FK_RV_ID2Guid_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[UserGroups]  WITH CHECK ADD CONSTRAINT [FK_UserGroups_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[NTFN_MessageTemplates]  WITH CHECK ADD CONSTRAINT [FK_NTFN_MessageTemplates_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[UserGroupUsers]  WITH CHECK ADD CONSTRAINT [FK_UserGroupUsers_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[MSG_MessageDetails]  WITH CHECK ADD CONSTRAINT [FK_MSG_MessageDetails_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[KW_LearningMethods]  WITH CHECK ADD CONSTRAINT [FK_KW_LearningMethods_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[NewsObjectTypes]  WITH CHECK ADD CONSTRAINT [FK_NewsObjectTypes_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[FG_ExtendedFormElements]  WITH CHECK ADD CONSTRAINT [FK_FG_ExtendedFormElements_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[USR_TemporaryUsers]  WITH CHECK ADD CONSTRAINT [FK_USR_TemporaryUsers_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[PersonalNews]  WITH CHECK ADD CONSTRAINT [FK_PersonalNews_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[TMP_KW_KnowledgeTypes]  WITH CHECK ADD CONSTRAINT [FK_TMP_KW_KnowledgeTypes_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[FG_FormOwners]  WITH CHECK ADD CONSTRAINT [FK_FG_FormOwners_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[USR_Invitations]  WITH CHECK ADD CONSTRAINT [FK_USR_Invitations_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[KW_TripForms]  WITH CHECK ADD CONSTRAINT [FK_KW_TripForms_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[MetricsConst]  WITH CHECK ADD CONSTRAINT [FK_MetricsConst_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[KW_Companies]  WITH CHECK ADD CONSTRAINT [FK_KW_Companies_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[CN_ListNodes]  WITH CHECK ADD CONSTRAINT [FK_CN_ListNodes_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[TMP_KW_Questions]  WITH CHECK ADD CONSTRAINT [FK_TMP_KW_Questions_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[FG_ElementLimits]  WITH CHECK ADD CONSTRAINT [FK_FG_ElementLimits_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[KW_RelatedNodes]  WITH CHECK ADD CONSTRAINT [FK_KW_RelatedNodes_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[TMP_KW_TypeQuestions]  WITH CHECK ADD CONSTRAINT [FK_TMP_KW_TypeQuestions_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[GapColorConst]  WITH CHECK ADD CONSTRAINT [FK_GapColorConst_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[SH_PostTypes]  WITH CHECK ADD CONSTRAINT [FK_SH_PostTypes_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[PRVC_PrivacyType]  WITH CHECK ADD CONSTRAINT [FK_PRVC_PrivacyType_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[KW_KnowledgeManagers]  WITH CHECK ADD CONSTRAINT [FK_KW_KnowledgeManagers_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[SH_Posts]  WITH CHECK ADD CONSTRAINT [FK_SH_Posts_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[WF_StateDataNeedInstances]  WITH CHECK ADD CONSTRAINT [FK_WF_StateDataNeedInstances_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[KW_ExperienceHolders]  WITH CHECK ADD CONSTRAINT [FK_KW_ExperienceHolders_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[TMP_KW_CandidateRelations]  WITH CHECK ADD CONSTRAINT [FK_TMP_KW_CandidateRelations_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[FG_InstanceElements]  WITH CHECK ADD CONSTRAINT [FK_FG_InstanceElements_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[WK_Titles]  WITH CHECK ADD CONSTRAINT [FK_WK_Titles_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[Countries]  WITH CHECK ADD CONSTRAINT [FK_Countries_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[ProfileScientific]  WITH CHECK ADD CONSTRAINT [FK_ProfileScientific_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[KW_FeedBacks]  WITH CHECK ADD CONSTRAINT [FK_KW_FeedBacks_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[WF_AutoMessages]  WITH CHECK ADD CONSTRAINT [FK_WF_AutoMessages_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[ProfileJobs]  WITH CHECK ADD CONSTRAINT [FK_ProfileJobs_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[ProfileInstitute]  WITH CHECK ADD CONSTRAINT [FK_ProfileInstitute_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[TMP_KW_QuestionAnswers]  WITH CHECK ADD CONSTRAINT [FK_TMP_KW_QuestionAnswers_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[NTFN_Dashboards]  WITH CHECK ADD CONSTRAINT [FK_NTFN_Dashboards_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[ProfileEducation]  WITH CHECK ADD CONSTRAINT [FK_ProfileEducation_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[KWF_Managers]  WITH CHECK ADD CONSTRAINT [FK_KWF_Managers_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[RV_DeletedStates]  WITH CHECK ADD CONSTRAINT [FK_RV_DeletedStates_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[SH_Comments]  WITH CHECK ADD CONSTRAINT [FK_SH_Comments_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[TMP_KW_History]  WITH CHECK ADD CONSTRAINT [FK_TMP_KW_History_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[CN_NodeMembers]  WITH CHECK ADD CONSTRAINT [FK_CN_NodeMembers_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[FG_FormInstances]  WITH CHECK ADD CONSTRAINT [FK_FG_FormInstances_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[FG_ExtendedForms]  WITH CHECK ADD CONSTRAINT [FK_FG_ExtendedForms_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[KWF_Paraphs]  WITH CHECK ADD CONSTRAINT [FK_KWF_Paraphs_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[KWF_Experts]  WITH CHECK ADD CONSTRAINT [FK_KWF_Experts_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[SH_ShareLikes]  WITH CHECK ADD CONSTRAINT [FK_SH_ShareLikes_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[RV_Variables]  WITH CHECK ADD CONSTRAINT [FK_RV_Variables_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[TMP_KW_TempKnowledgeTypeIDs]  WITH CHECK ADD CONSTRAINT [FK_TMP_KW_TempKnowledgeTypeIDs_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[SH_CommentLikes]  WITH CHECK ADD CONSTRAINT [FK_SH_CommentLikes_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[CN_Experts]  WITH CHECK ADD CONSTRAINT [FK_CN_Experts_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[WK_Paragraphs]  WITH CHECK ADD CONSTRAINT [FK_WK_Paragraphs_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[TMP_KW_FeedBacks]  WITH CHECK ADD CONSTRAINT [FK_TMP_KW_FeedBacks_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[WF_WorkFlowOwners]  WITH CHECK ADD CONSTRAINT [FK_WF_WorkFlowOwners_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[CN_Properties]  WITH CHECK ADD CONSTRAINT [FK_CN_Properties_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[CN_ExpertiseReferrals]  WITH CHECK ADD CONSTRAINT [FK_CN_ExpertiseReferrals_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[KWF_Evaluators]  WITH CHECK ADD CONSTRAINT [FK_KWF_Evaluators_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[WF_States]  WITH CHECK ADD CONSTRAINT [FK_WF_States_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[QA_Questions]  WITH CHECK ADD CONSTRAINT [FK_QA_Questions_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[WK_Changes]  WITH CHECK ADD CONSTRAINT [FK_WK_Changes_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[CN_NodeLikes]  WITH CHECK ADD CONSTRAINT [FK_CN_NodeLikes_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[CN_NodeProperties]  WITH CHECK ADD CONSTRAINT [FK_CN_NodeProperties_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[WF_WorkFlows]  WITH CHECK ADD CONSTRAINT [FK_WF_WorkFlows_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[QA_Answers]  WITH CHECK ADD CONSTRAINT [FK_QA_Answers_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[AttachmentFiles]  WITH CHECK ADD CONSTRAINT [FK_AttachmentFiles_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[WF_StateConnections]  WITH CHECK ADD CONSTRAINT [FK_WF_StateConnections_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[PRVC_Audience]  WITH CHECK ADD CONSTRAINT [FK_PRVC_Audience_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[NGeneralQuestions]  WITH CHECK ADD CONSTRAINT [FK_NGeneralQuestions_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[CN_NodeRelations]  WITH CHECK ADD CONSTRAINT [FK_CN_NodeRelations_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[USR_PassResetTickets]  WITH CHECK ADD CONSTRAINT [FK_USR_PassResetTickets_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[EVT_Events]  WITH CHECK ADD CONSTRAINT [FK_EVT_Events_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[USR_Profile]  WITH CHECK ADD CONSTRAINT [FK_USR_Profile_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[UserGroupAccessRoles]  WITH CHECK ADD CONSTRAINT [FK_UserGroupAccessRoles_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[WF_StateConnectionForms]  WITH CHECK ADD CONSTRAINT [FK_WF_StateConnectionForms_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[QA_QuestionLikes]  WITH CHECK ADD CONSTRAINT [FK_QA_QuestionLikes_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[USR_LanguageNames]  WITH CHECK ADD CONSTRAINT [FK_USR_LanguageNames_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[EVT_RelatedUsers]  WITH CHECK ADD CONSTRAINT [FK_EVT_RelatedUsers_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[USR_UserLanguages]  WITH CHECK ADD CONSTRAINT [FK_USR_UserLanguages_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[Cities]  WITH CHECK ADD CONSTRAINT [FK_Cities_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[CN_ListAdmins]  WITH CHECK ADD CONSTRAINT [FK_CN_ListAdmins_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[QA_RefNodes]  WITH CHECK ADD CONSTRAINT [FK_QA_RefNodes_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[USR_ItemVisits]  WITH CHECK ADD CONSTRAINT [FK_USR_ItemVisits_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[NTFN_NotificationMessageTemplates]  WITH CHECK ADD CONSTRAINT [FK_NTFN_NotificationMessageTemplates_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[CN_Tags]  WITH CHECK ADD CONSTRAINT [FK_CN_Tags_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[WF_WorkFlowStates]  WITH CHECK ADD CONSTRAINT [FK_WF_WorkFlowStates_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[EVT_RelatedNodes]  WITH CHECK ADD CONSTRAINT [FK_EVT_RelatedNodes_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[WF_HistoryFormInstances]  WITH CHECK ADD CONSTRAINT [FK_WF_HistoryFormInstances_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[QA_RefUsers]  WITH CHECK ADD CONSTRAINT [FK_QA_RefUsers_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[USR_JobExperiences]  WITH CHECK ADD CONSTRAINT [FK_USR_JobExperiences_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[RV_EmailQueue]  WITH CHECK ADD CONSTRAINT [FK_RV_EmailQueue_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[USR_EmailContacts]  WITH CHECK ADD CONSTRAINT [FK_USR_EmailContacts_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[NodeSetting]  WITH CHECK ADD CONSTRAINT [FK_NodeSetting_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[NTFN_UserMessagingActivation]  WITH CHECK ADD CONSTRAINT [FK_NTFN_UserMessagingActivation_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[RV_SentEmails]  WITH CHECK ADD CONSTRAINT [FK_RV_SentEmails_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[USR_Friends]  WITH CHECK ADD CONSTRAINT [FK_USR_Friends_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[USR_EducationalExperiences]  WITH CHECK ADD CONSTRAINT [FK_USR_EducationalExperiences_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[CN_NodeTypes]  WITH CHECK ADD CONSTRAINT [FK_CN_NodeTypes_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO
ALTER TABLE [dbo].[DCT_TreeTypes]  WITH CHECK ADD CONSTRAINT [FK_DCT_TreeTypes_aspnet_Applications] FOREIGN KEY([ApplicationID]) REFERENCES [dbo].[aspnet_Applications] ([ApplicationId]) 
GO


ALTER TABLE [dbo].[AppSetting] CHECK CONSTRAINT [FK_AppSetting_aspnet_Applications] 
GO
ALTER TABLE [dbo].[NodeMetrics] CHECK CONSTRAINT [FK_NodeMetrics_aspnet_Applications] 
GO
ALTER TABLE [dbo].[USR_FriendSuggestions] CHECK CONSTRAINT [FK_USR_FriendSuggestions_aspnet_Applications] 
GO
ALTER TABLE [dbo].[USR_HonorsAndAwards] CHECK CONSTRAINT [FK_USR_HonorsAndAwards_aspnet_Applications] 
GO
ALTER TABLE [dbo].[DCT_Trees] CHECK CONSTRAINT [FK_DCT_Trees_aspnet_Applications] 
GO
ALTER TABLE [dbo].[CN_Nodes] CHECK CONSTRAINT [FK_CN_Nodes_aspnet_Applications] 
GO
ALTER TABLE [dbo].[WF_StateDataNeeds] CHECK CONSTRAINT [FK_WF_StateDataNeeds_aspnet_Applications] 
GO
ALTER TABLE [dbo].[DCT_TreeNodes] CHECK CONSTRAINT [FK_DCT_TreeNodes_aspnet_Applications] 
GO
ALTER TABLE [dbo].[Attachments] CHECK CONSTRAINT [FK_Attachments_aspnet_Applications] 
GO
ALTER TABLE [dbo].[CN_ContributionLimits] CHECK CONSTRAINT [FK_CN_ContributionLimits_aspnet_Applications] 
GO
ALTER TABLE [dbo].[USR_PasswordsHistory] CHECK CONSTRAINT [FK_USR_PasswordsHistory_aspnet_Applications] 
GO
ALTER TABLE [dbo].[KWF_Statuses] CHECK CONSTRAINT [FK_KWF_Statuses_aspnet_Applications] 
GO
ALTER TABLE [dbo].[KW_ConfidentialityLevels] CHECK CONSTRAINT [FK_KW_ConfidentialityLevels_aspnet_Applications] 
GO
ALTER TABLE [dbo].[AddedForms] CHECK CONSTRAINT [FK_AddedForms_aspnet_Applications] 
GO
ALTER TABLE [dbo].[KW_UsersConfidentialityLevels] CHECK CONSTRAINT [FK_KW_UsersConfidentialityLevels_aspnet_Applications] 
GO
ALTER TABLE [dbo].[WF_History] CHECK CONSTRAINT [FK_WF_History_aspnet_Applications] 
GO
ALTER TABLE [dbo].[LG_ErrorLogs] CHECK CONSTRAINT [FK_LG_ErrorLogs_aspnet_Applications] 
GO
ALTER TABLE [dbo].[SH_PostShares] CHECK CONSTRAINT [FK_SH_PostShares_aspnet_Applications] 
GO
ALTER TABLE [dbo].[PRVC_ConfidentialityLevels] CHECK CONSTRAINT [FK_PRVC_ConfidentialityLevels_aspnet_Applications] 
GO
ALTER TABLE [dbo].[KW_KnowledgeTypes] CHECK CONSTRAINT [FK_KW_KnowledgeTypes_aspnet_Applications] 
GO
ALTER TABLE [dbo].[PRVC_Confidentialities] CHECK CONSTRAINT [FK_PRVC_Confidentialities_aspnet_Applications] 
GO
ALTER TABLE [dbo].[KW_Knowledges] CHECK CONSTRAINT [FK_KW_Knowledges_aspnet_Applications] 
GO
ALTER TABLE [dbo].[USR_EmailAddresses] CHECK CONSTRAINT [FK_USR_EmailAddresses_aspnet_Applications] 
GO
ALTER TABLE [dbo].[NTFN_Notifications] CHECK CONSTRAINT [FK_NTFN_Notifications_aspnet_Applications] 
GO
ALTER TABLE [dbo].[LG_Logs] CHECK CONSTRAINT [FK_LG_Logs_aspnet_Applications] 
GO
ALTER TABLE [dbo].[USR_PhoneNumbers] CHECK CONSTRAINT [FK_USR_PhoneNumbers_aspnet_Applications] 
GO
ALTER TABLE [dbo].[CN_NodeCreators] CHECK CONSTRAINT [FK_CN_NodeCreators_aspnet_Applications] 
GO
ALTER TABLE [dbo].[KW_CreatorUsers] CHECK CONSTRAINT [FK_KW_CreatorUsers_aspnet_Applications] 
GO
ALTER TABLE [dbo].[CN_Lists] CHECK CONSTRAINT [FK_CN_Lists_aspnet_Applications] 
GO
ALTER TABLE [dbo].[KW_KnowledgeCards] CHECK CONSTRAINT [FK_KW_KnowledgeCards_aspnet_Applications] 
GO
ALTER TABLE [dbo].[CN_Services] CHECK CONSTRAINT [FK_CN_Services_aspnet_Applications] 
GO
ALTER TABLE [dbo].[CN_AdminTypeLimits] CHECK CONSTRAINT [FK_CN_AdminTypeLimits_aspnet_Applications] 
GO
ALTER TABLE [dbo].[AccessRoles] CHECK CONSTRAINT [FK_AccessRoles_aspnet_Applications] 
GO
ALTER TABLE [dbo].[CN_Extensions] CHECK CONSTRAINT [FK_CN_Extensions_aspnet_Applications] 
GO
ALTER TABLE [dbo].[KW_SkillLevels] CHECK CONSTRAINT [FK_KW_SkillLevels_aspnet_Applications] 
GO
ALTER TABLE [dbo].[CN_ServiceAdmins] CHECK CONSTRAINT [FK_CN_ServiceAdmins_aspnet_Applications] 
GO
ALTER TABLE [dbo].[KW_KnowledgeAssets] CHECK CONSTRAINT [FK_KW_KnowledgeAssets_aspnet_Applications] 
GO
ALTER TABLE [dbo].[RV_TaggedItems] CHECK CONSTRAINT [FK_RV_TaggedItems_aspnet_Applications] 
GO
ALTER TABLE [dbo].[OrganProfile] CHECK CONSTRAINT [FK_OrganProfile_aspnet_Applications] 
GO
ALTER TABLE [dbo].[KW_NodeRelatedTrees] CHECK CONSTRAINT [FK_KW_NodeRelatedTrees_aspnet_Applications] 
GO
ALTER TABLE [dbo].[NQuestions] CHECK CONSTRAINT [FK_NQuestions_aspnet_Applications] 
GO
ALTER TABLE [dbo].[DCT_FileContents] CHECK CONSTRAINT [FK_DCT_FileContents_aspnet_Applications] 
GO
ALTER TABLE [dbo].[CN_FreeUsers] CHECK CONSTRAINT [FK_CN_FreeUsers_aspnet_Applications] 
GO
ALTER TABLE [dbo].[KW_RefrenceUsers] CHECK CONSTRAINT [FK_KW_RefrenceUsers_aspnet_Applications] 
GO
ALTER TABLE [dbo].[MSG_Messages] CHECK CONSTRAINT [FK_MSG_Messages_aspnet_Applications] 
GO
ALTER TABLE [dbo].[RV_ID2Guid] CHECK CONSTRAINT [FK_RV_ID2Guid_aspnet_Applications] 
GO
ALTER TABLE [dbo].[UserGroups] CHECK CONSTRAINT [FK_UserGroups_aspnet_Applications] 
GO
ALTER TABLE [dbo].[NTFN_MessageTemplates] CHECK CONSTRAINT [FK_NTFN_MessageTemplates_aspnet_Applications] 
GO
ALTER TABLE [dbo].[UserGroupUsers] CHECK CONSTRAINT [FK_UserGroupUsers_aspnet_Applications] 
GO
ALTER TABLE [dbo].[MSG_MessageDetails] CHECK CONSTRAINT [FK_MSG_MessageDetails_aspnet_Applications] 
GO
ALTER TABLE [dbo].[KW_LearningMethods] CHECK CONSTRAINT [FK_KW_LearningMethods_aspnet_Applications] 
GO
ALTER TABLE [dbo].[NewsObjectTypes] CHECK CONSTRAINT [FK_NewsObjectTypes_aspnet_Applications] 
GO
ALTER TABLE [dbo].[FG_ExtendedFormElements] CHECK CONSTRAINT [FK_FG_ExtendedFormElements_aspnet_Applications] 
GO
ALTER TABLE [dbo].[USR_TemporaryUsers] CHECK CONSTRAINT [FK_USR_TemporaryUsers_aspnet_Applications] 
GO
ALTER TABLE [dbo].[PersonalNews] CHECK CONSTRAINT [FK_PersonalNews_aspnet_Applications] 
GO
ALTER TABLE [dbo].[TMP_KW_KnowledgeTypes] CHECK CONSTRAINT [FK_TMP_KW_KnowledgeTypes_aspnet_Applications] 
GO
ALTER TABLE [dbo].[FG_FormOwners] CHECK CONSTRAINT [FK_FG_FormOwners_aspnet_Applications] 
GO
ALTER TABLE [dbo].[USR_Invitations] CHECK CONSTRAINT [FK_USR_Invitations_aspnet_Applications] 
GO
ALTER TABLE [dbo].[KW_TripForms] CHECK CONSTRAINT [FK_KW_TripForms_aspnet_Applications] 
GO
ALTER TABLE [dbo].[MetricsConst] CHECK CONSTRAINT [FK_MetricsConst_aspnet_Applications] 
GO
ALTER TABLE [dbo].[KW_Companies] CHECK CONSTRAINT [FK_KW_Companies_aspnet_Applications] 
GO
ALTER TABLE [dbo].[CN_ListNodes] CHECK CONSTRAINT [FK_CN_ListNodes_aspnet_Applications] 
GO
ALTER TABLE [dbo].[TMP_KW_Questions] CHECK CONSTRAINT [FK_TMP_KW_Questions_aspnet_Applications] 
GO
ALTER TABLE [dbo].[FG_ElementLimits] CHECK CONSTRAINT [FK_FG_ElementLimits_aspnet_Applications] 
GO
ALTER TABLE [dbo].[KW_RelatedNodes] CHECK CONSTRAINT [FK_KW_RelatedNodes_aspnet_Applications] 
GO
ALTER TABLE [dbo].[TMP_KW_TypeQuestions] CHECK CONSTRAINT [FK_TMP_KW_TypeQuestions_aspnet_Applications] 
GO
ALTER TABLE [dbo].[GapColorConst] CHECK CONSTRAINT [FK_GapColorConst_aspnet_Applications] 
GO
ALTER TABLE [dbo].[SH_PostTypes] CHECK CONSTRAINT [FK_SH_PostTypes_aspnet_Applications] 
GO
ALTER TABLE [dbo].[PRVC_PrivacyType] CHECK CONSTRAINT [FK_PRVC_PrivacyType_aspnet_Applications] 
GO
ALTER TABLE [dbo].[KW_KnowledgeManagers] CHECK CONSTRAINT [FK_KW_KnowledgeManagers_aspnet_Applications] 
GO
ALTER TABLE [dbo].[SH_Posts] CHECK CONSTRAINT [FK_SH_Posts_aspnet_Applications] 
GO
ALTER TABLE [dbo].[WF_StateDataNeedInstances] CHECK CONSTRAINT [FK_WF_StateDataNeedInstances_aspnet_Applications] 
GO
ALTER TABLE [dbo].[KW_ExperienceHolders] CHECK CONSTRAINT [FK_KW_ExperienceHolders_aspnet_Applications] 
GO
ALTER TABLE [dbo].[TMP_KW_CandidateRelations] CHECK CONSTRAINT [FK_TMP_KW_CandidateRelations_aspnet_Applications] 
GO
ALTER TABLE [dbo].[FG_InstanceElements] CHECK CONSTRAINT [FK_FG_InstanceElements_aspnet_Applications] 
GO
ALTER TABLE [dbo].[WK_Titles] CHECK CONSTRAINT [FK_WK_Titles_aspnet_Applications] 
GO
ALTER TABLE [dbo].[Countries] CHECK CONSTRAINT [FK_Countries_aspnet_Applications] 
GO
ALTER TABLE [dbo].[ProfileScientific] CHECK CONSTRAINT [FK_ProfileScientific_aspnet_Applications] 
GO
ALTER TABLE [dbo].[KW_FeedBacks] CHECK CONSTRAINT [FK_KW_FeedBacks_aspnet_Applications] 
GO
ALTER TABLE [dbo].[WF_AutoMessages] CHECK CONSTRAINT [FK_WF_AutoMessages_aspnet_Applications] 
GO
ALTER TABLE [dbo].[ProfileJobs] CHECK CONSTRAINT [FK_ProfileJobs_aspnet_Applications] 
GO
ALTER TABLE [dbo].[ProfileInstitute] CHECK CONSTRAINT [FK_ProfileInstitute_aspnet_Applications] 
GO
ALTER TABLE [dbo].[TMP_KW_QuestionAnswers] CHECK CONSTRAINT [FK_TMP_KW_QuestionAnswers_aspnet_Applications] 
GO
ALTER TABLE [dbo].[NTFN_Dashboards] CHECK CONSTRAINT [FK_NTFN_Dashboards_aspnet_Applications] 
GO
ALTER TABLE [dbo].[ProfileEducation] CHECK CONSTRAINT [FK_ProfileEducation_aspnet_Applications] 
GO
ALTER TABLE [dbo].[KWF_Managers] CHECK CONSTRAINT [FK_KWF_Managers_aspnet_Applications] 
GO
ALTER TABLE [dbo].[RV_DeletedStates] CHECK CONSTRAINT [FK_RV_DeletedStates_aspnet_Applications] 
GO
ALTER TABLE [dbo].[SH_Comments] CHECK CONSTRAINT [FK_SH_Comments_aspnet_Applications] 
GO
ALTER TABLE [dbo].[TMP_KW_History] CHECK CONSTRAINT [FK_TMP_KW_History_aspnet_Applications] 
GO
ALTER TABLE [dbo].[CN_NodeMembers] CHECK CONSTRAINT [FK_CN_NodeMembers_aspnet_Applications] 
GO
ALTER TABLE [dbo].[FG_FormInstances] CHECK CONSTRAINT [FK_FG_FormInstances_aspnet_Applications] 
GO
ALTER TABLE [dbo].[FG_ExtendedForms] CHECK CONSTRAINT [FK_FG_ExtendedForms_aspnet_Applications] 
GO
ALTER TABLE [dbo].[KWF_Paraphs] CHECK CONSTRAINT [FK_KWF_Paraphs_aspnet_Applications] 
GO
ALTER TABLE [dbo].[KWF_Experts] CHECK CONSTRAINT [FK_KWF_Experts_aspnet_Applications] 
GO
ALTER TABLE [dbo].[SH_ShareLikes] CHECK CONSTRAINT [FK_SH_ShareLikes_aspnet_Applications] 
GO
ALTER TABLE [dbo].[RV_Variables] CHECK CONSTRAINT [FK_RV_Variables_aspnet_Applications] 
GO
ALTER TABLE [dbo].[TMP_KW_TempKnowledgeTypeIDs] CHECK CONSTRAINT [FK_TMP_KW_TempKnowledgeTypeIDs_aspnet_Applications] 
GO
ALTER TABLE [dbo].[SH_CommentLikes] CHECK CONSTRAINT [FK_SH_CommentLikes_aspnet_Applications] 
GO
ALTER TABLE [dbo].[CN_Experts] CHECK CONSTRAINT [FK_CN_Experts_aspnet_Applications] 
GO
ALTER TABLE [dbo].[WK_Paragraphs] CHECK CONSTRAINT [FK_WK_Paragraphs_aspnet_Applications] 
GO
ALTER TABLE [dbo].[TMP_KW_FeedBacks] CHECK CONSTRAINT [FK_TMP_KW_FeedBacks_aspnet_Applications] 
GO
ALTER TABLE [dbo].[WF_WorkFlowOwners] CHECK CONSTRAINT [FK_WF_WorkFlowOwners_aspnet_Applications] 
GO
ALTER TABLE [dbo].[CN_Properties] CHECK CONSTRAINT [FK_CN_Properties_aspnet_Applications] 
GO
ALTER TABLE [dbo].[CN_ExpertiseReferrals] CHECK CONSTRAINT [FK_CN_ExpertiseReferrals_aspnet_Applications] 
GO
ALTER TABLE [dbo].[KWF_Evaluators] CHECK CONSTRAINT [FK_KWF_Evaluators_aspnet_Applications] 
GO
ALTER TABLE [dbo].[WF_States] CHECK CONSTRAINT [FK_WF_States_aspnet_Applications] 
GO
ALTER TABLE [dbo].[QA_Questions] CHECK CONSTRAINT [FK_QA_Questions_aspnet_Applications] 
GO
ALTER TABLE [dbo].[WK_Changes] CHECK CONSTRAINT [FK_WK_Changes_aspnet_Applications] 
GO
ALTER TABLE [dbo].[CN_NodeLikes] CHECK CONSTRAINT [FK_CN_NodeLikes_aspnet_Applications] 
GO
ALTER TABLE [dbo].[CN_NodeProperties] CHECK CONSTRAINT [FK_CN_NodeProperties_aspnet_Applications] 
GO
ALTER TABLE [dbo].[WF_WorkFlows] CHECK CONSTRAINT [FK_WF_WorkFlows_aspnet_Applications] 
GO
ALTER TABLE [dbo].[QA_Answers] CHECK CONSTRAINT [FK_QA_Answers_aspnet_Applications] 
GO
ALTER TABLE [dbo].[AttachmentFiles] CHECK CONSTRAINT [FK_AttachmentFiles_aspnet_Applications] 
GO
ALTER TABLE [dbo].[WF_StateConnections] CHECK CONSTRAINT [FK_WF_StateConnections_aspnet_Applications] 
GO
ALTER TABLE [dbo].[PRVC_Audience] CHECK CONSTRAINT [FK_PRVC_Audience_aspnet_Applications] 
GO
ALTER TABLE [dbo].[NGeneralQuestions] CHECK CONSTRAINT [FK_NGeneralQuestions_aspnet_Applications] 
GO
ALTER TABLE [dbo].[CN_NodeRelations] CHECK CONSTRAINT [FK_CN_NodeRelations_aspnet_Applications] 
GO
ALTER TABLE [dbo].[USR_PassResetTickets] CHECK CONSTRAINT [FK_USR_PassResetTickets_aspnet_Applications] 
GO
ALTER TABLE [dbo].[EVT_Events] CHECK CONSTRAINT [FK_EVT_Events_aspnet_Applications] 
GO
ALTER TABLE [dbo].[USR_Profile] CHECK CONSTRAINT [FK_USR_Profile_aspnet_Applications] 
GO
ALTER TABLE [dbo].[UserGroupAccessRoles] CHECK CONSTRAINT [FK_UserGroupAccessRoles_aspnet_Applications] 
GO
ALTER TABLE [dbo].[WF_StateConnectionForms] CHECK CONSTRAINT [FK_WF_StateConnectionForms_aspnet_Applications] 
GO
ALTER TABLE [dbo].[QA_QuestionLikes] CHECK CONSTRAINT [FK_QA_QuestionLikes_aspnet_Applications] 
GO
ALTER TABLE [dbo].[USR_LanguageNames] CHECK CONSTRAINT [FK_USR_LanguageNames_aspnet_Applications] 
GO
ALTER TABLE [dbo].[EVT_RelatedUsers] CHECK CONSTRAINT [FK_EVT_RelatedUsers_aspnet_Applications] 
GO
ALTER TABLE [dbo].[USR_UserLanguages] CHECK CONSTRAINT [FK_USR_UserLanguages_aspnet_Applications] 
GO
ALTER TABLE [dbo].[Cities] CHECK CONSTRAINT [FK_Cities_aspnet_Applications] 
GO
ALTER TABLE [dbo].[CN_ListAdmins] CHECK CONSTRAINT [FK_CN_ListAdmins_aspnet_Applications] 
GO
ALTER TABLE [dbo].[QA_RefNodes] CHECK CONSTRAINT [FK_QA_RefNodes_aspnet_Applications] 
GO
ALTER TABLE [dbo].[USR_ItemVisits] CHECK CONSTRAINT [FK_USR_ItemVisits_aspnet_Applications] 
GO
ALTER TABLE [dbo].[NTFN_NotificationMessageTemplates] CHECK CONSTRAINT [FK_NTFN_NotificationMessageTemplates_aspnet_Applications] 
GO
ALTER TABLE [dbo].[CN_Tags] CHECK CONSTRAINT [FK_CN_Tags_aspnet_Applications] 
GO
ALTER TABLE [dbo].[WF_WorkFlowStates] CHECK CONSTRAINT [FK_WF_WorkFlowStates_aspnet_Applications] 
GO
ALTER TABLE [dbo].[EVT_RelatedNodes] CHECK CONSTRAINT [FK_EVT_RelatedNodes_aspnet_Applications] 
GO
ALTER TABLE [dbo].[WF_HistoryFormInstances] CHECK CONSTRAINT [FK_WF_HistoryFormInstances_aspnet_Applications] 
GO
ALTER TABLE [dbo].[QA_RefUsers] CHECK CONSTRAINT [FK_QA_RefUsers_aspnet_Applications] 
GO
ALTER TABLE [dbo].[USR_JobExperiences] CHECK CONSTRAINT [FK_USR_JobExperiences_aspnet_Applications] 
GO
ALTER TABLE [dbo].[RV_EmailQueue] CHECK CONSTRAINT [FK_RV_EmailQueue_aspnet_Applications] 
GO
ALTER TABLE [dbo].[USR_EmailContacts] CHECK CONSTRAINT [FK_USR_EmailContacts_aspnet_Applications] 
GO
ALTER TABLE [dbo].[NodeSetting] CHECK CONSTRAINT [FK_NodeSetting_aspnet_Applications] 
GO
ALTER TABLE [dbo].[NTFN_UserMessagingActivation] CHECK CONSTRAINT [FK_NTFN_UserMessagingActivation_aspnet_Applications] 
GO
ALTER TABLE [dbo].[RV_SentEmails] CHECK CONSTRAINT [FK_RV_SentEmails_aspnet_Applications] 
GO
ALTER TABLE [dbo].[USR_Friends] CHECK CONSTRAINT [FK_USR_Friends_aspnet_Applications] 
GO
ALTER TABLE [dbo].[USR_EducationalExperiences] CHECK CONSTRAINT [FK_USR_EducationalExperiences_aspnet_Applications]
GO
ALTER TABLE [dbo].[CN_NodeTypes] CHECK CONSTRAINT [FK_CN_NodeTypes_aspnet_Applications] 
GO
ALTER TABLE [dbo].[DCT_TreeTypes] CHECK CONSTRAINT [FK_DCT_TreeTypes_aspnet_Applications] 
GO


UPDATE [dbo].[NodeMetrics] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[USR_FriendSuggestions] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[USR_HonorsAndAwards] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[DCT_Trees] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[CN_Nodes] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[WF_StateDataNeeds] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[DCT_TreeNodes] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[Attachments] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[CN_ContributionLimits] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[USR_PasswordsHistory] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[KWF_Statuses] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[KW_ConfidentialityLevels] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[AddedForms] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[KW_UsersConfidentialityLevels] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[WF_History] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[LG_ErrorLogs] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[SH_PostShares] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[PRVC_ConfidentialityLevels] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[KW_KnowledgeTypes] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[PRVC_Confidentialities] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[KW_Knowledges] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[USR_EmailAddresses] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[NTFN_Notifications] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[LG_Logs] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[USR_PhoneNumbers] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[CN_NodeCreators] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[KW_CreatorUsers] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[CN_Lists] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[KW_KnowledgeCards] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[CN_Services] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[CN_AdminTypeLimits] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[AccessRoles] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[AppSetting] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[CN_Extensions] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[KW_SkillLevels] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[CN_ServiceAdmins] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[KW_KnowledgeAssets] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[RV_TaggedItems] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[OrganProfile] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[KW_NodeRelatedTrees] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[NQuestions] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[DCT_FileContents] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[CN_FreeUsers] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[KW_RefrenceUsers] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[MSG_Messages] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[RV_ID2Guid] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[UserGroups] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[NTFN_MessageTemplates] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[UserGroupUsers] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[MSG_MessageDetails] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[KW_LearningMethods] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[NewsObjectTypes] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[FG_ExtendedFormElements] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[USR_TemporaryUsers] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[PersonalNews] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[TMP_KW_KnowledgeTypes] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[FG_FormOwners] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[USR_Invitations] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[KW_TripForms] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[MetricsConst] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[KW_Companies] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[CN_ListNodes] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[TMP_KW_Questions] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[FG_ElementLimits] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[KW_RelatedNodes] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[TMP_KW_TypeQuestions] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[GapColorConst] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[SH_PostTypes] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[PRVC_PrivacyType] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[KW_KnowledgeManagers] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[SH_Posts] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[WF_StateDataNeedInstances] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[KW_ExperienceHolders] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[TMP_KW_CandidateRelations] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[FG_InstanceElements] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[WK_Titles] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[Countries] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[ProfileScientific] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[KW_FeedBacks] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[WF_AutoMessages] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[ProfileJobs] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[ProfileInstitute] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[TMP_KW_QuestionAnswers] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[NTFN_Dashboards] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[ProfileEducation] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[KWF_Managers] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[RV_DeletedStates] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[SH_Comments] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[TMP_KW_History] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[CN_NodeMembers] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[FG_FormInstances] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[FG_ExtendedForms] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[KWF_Paraphs] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[KWF_Experts] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[SH_ShareLikes] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[RV_Variables] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[TMP_KW_TempKnowledgeTypeIDs] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[SH_CommentLikes] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[CN_Experts] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[WK_Paragraphs] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[TMP_KW_FeedBacks] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[WF_WorkFlowOwners] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[CN_Properties] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[CN_ExpertiseReferrals] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[KWF_Evaluators] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[WF_States] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[QA_Questions] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[WK_Changes] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[CN_NodeLikes] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[CN_NodeProperties] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[WF_WorkFlows] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[QA_Answers] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[AttachmentFiles] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[WF_StateConnections] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[PRVC_Audience] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[NGeneralQuestions] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[CN_NodeRelations] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[USR_PassResetTickets] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[EVT_Events] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[USR_Profile] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[UserGroupAccessRoles] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[WF_StateConnectionForms] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[QA_QuestionLikes] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[USR_LanguageNames] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[EVT_RelatedUsers] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[USR_UserLanguages] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[Cities] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[CN_ListAdmins] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[QA_RefNodes] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[USR_ItemVisits] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[NTFN_NotificationMessageTemplates] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[CN_Tags] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[WF_WorkFlowStates] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[EVT_RelatedNodes] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[WF_HistoryFormInstances] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[QA_RefUsers] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[USR_JobExperiences] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[RV_EmailQueue] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[USR_EmailContacts] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[NodeSetting] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[NTFN_UserMessagingActivation] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[RV_SentEmails] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[USR_Friends] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[USR_EducationalExperiences] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[CN_NodeTypes] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO
UPDATE [dbo].[DCT_TreeTypes] SET ApplicationID = '08C72552-4F2C-473F-B3B0-C2DACF8CD6A9' 
GO




DROP TABLE [dbo].[Cities]
GO

DROP TABLE [dbo].[Countries]
GO


UPDATE [dbo].[Attachments]
	SET ObjectType = N'Node'
WHERE ObjectType = N'Knowledge'

GO


/****** Object:  Table [dbo].[CN_Tags]    Script Date: 05/15/2016 14:19:30 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER TABLE [dbo].[WF_WorkFlowStates]
DROP CONSTRAINT [FK_WF_WorkFlowStates_CN_Tags]
GO


CREATE TABLE [dbo].[TMP_CN_Tags](
	[TagID] [uniqueidentifier] NOT NULL,
	[Tag] [nvarchar](400) NOT NULL,
	[IsApproved] [bit] NOT NULL,
	[CreatorUserID] [uniqueidentifier] NULL,
	[CreationDate] [datetime] NULL,
	[CallsCount] [int] NOT NULL,
	[Deleted] [bit] NOT NULL,
	[ApplicationID] [uniqueidentifier] NULL,
 CONSTRAINT [TMP_PK_CN_Tags] PRIMARY KEY CLUSTERED 
(
	[TagID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

INSERT INTO [dbo].[TMP_CN_Tags]
SELECT *
FROM [dbo].[CN_Tags]
GO

DROP TABLE [dbo].[CN_Tags]
GO

CREATE TABLE [dbo].[CN_Tags](
	[TagID] [uniqueidentifier] NOT NULL,
	[Tag] [nvarchar](400) NOT NULL,
	[IsApproved] [bit] NOT NULL,
	[CreatorUserID] [uniqueidentifier] NULL,
	[CreationDate] [datetime] NULL,
	[CallsCount] [int] NOT NULL,
	[Deleted] [bit] NOT NULL,
	[ApplicationID] [uniqueidentifier] NULL,
 CONSTRAINT [PK_CN_Tags] PRIMARY KEY CLUSTERED 
(
	[TagID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

INSERT INTO [dbo].[CN_Tags]
SELECT *
FROM [dbo].[TMP_CN_Tags]
GO

DROP TABLE [dbo].[TMP_CN_Tags]
GO


 ALTER TABLE [dbo].[CN_Tags] ADD  CONSTRAINT [UK_CN_Tags_Tag] UNIQUE NONCLUSTERED 
(
	[ApplicationID] ASC,
	[Tag] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]

GO

ALTER TABLE [dbo].[CN_Tags]  WITH CHECK ADD  CONSTRAINT [FK_CN_Tags_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[CN_Tags] CHECK CONSTRAINT [FK_CN_Tags_aspnet_Applications]
GO

ALTER TABLE [dbo].[CN_Tags]  WITH CHECK ADD  CONSTRAINT [FK_CN_Tags_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[CN_Tags] CHECK CONSTRAINT [FK_CN_Tags_aspnet_Users_Creator]
GO


ALTER TABLE [dbo].[WF_WorkFlowStates]  WITH CHECK ADD  CONSTRAINT [FK_WF_WorkFlowStates_CN_Tags] FOREIGN KEY([TagID])
REFERENCES [dbo].[CN_Tags] ([TagID])
GO

ALTER TABLE [dbo].[WF_WorkFlowStates] CHECK CONSTRAINT [FK_WF_WorkFlowStates_CN_Tags]
GO



ALTER TABLE [dbo].[NTFN_NotificationMessageTemplates]
DROP CONSTRAINT [UK_NTFN_NotificationMessageTemplates]
GO

ALTER TABLE [dbo].[NTFN_NotificationMessageTemplates] ADD  CONSTRAINT [UK_NTFN_NotificationMessageTemplates] UNIQUE NONCLUSTERED 
(
	[ApplicationID] ASC,
	[Action] ASC,
	[SubjectType] ASC,
	[UserStatus] ASC,
	[Media] ASC,
	[Lang] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO


ALTER TABLE [dbo].[CN_Properties]
DROP CONSTRAINT [UK_Properties_Name]
GO

ALTER TABLE [dbo].[CN_Properties] ADD  CONSTRAINT [UK_CN_Properties_Name] UNIQUE NONCLUSTERED 
(
	[ApplicationID] ASC,
	[Name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO


/****** Object:  Table [dbo].[UserGroups]    Script Date: 05/16/2016 09:26:25 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[USR_UserGroups](
	[GroupID] [uniqueidentifier] NOT NULL,
	[Title] [nvarchar](256) NOT NULL,
	[Description] [nvarchar](2000) NULL,
	[CreatorUserID] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL,
	[ApplicationID] [uniqueidentifier] NULL
 CONSTRAINT [PK_USR_UserGroups] PRIMARY KEY CLUSTERED 
(
	[GroupID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[USR_UserGroups]  WITH CHECK ADD  CONSTRAINT [FK_USR_UserGroups_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[USR_UserGroups] CHECK CONSTRAINT [FK_USR_UserGroups_aspnet_Applications]
GO


ALTER TABLE [dbo].[USR_UserGroups]  WITH CHECK ADD  CONSTRAINT [FK_USR_UserGroups_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[USR_UserGroups] CHECK CONSTRAINT [FK_USR_UserGroups_aspnet_Users_Creator]
GO


ALTER TABLE [dbo].[USR_UserGroups]  WITH CHECK ADD  CONSTRAINT [FK_USR_UserGroups_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[USR_UserGroups] CHECK CONSTRAINT [FK_USR_UserGroups_aspnet_Users_Modifier]
GO


DECLARE @UID uniqueidentifier = (SELECT TOP(1) UserId FROM [dbo].[aspnet_Users] WHERE LoweredUserName = N'admin')
DECLARE @Now datetime = GETDATE()

INSERT INTO [dbo].[USR_UserGroups] (
	ApplicationID,
	GroupID,
	Title,
	[Description],
	CreatorUserID,
	CreationDate,
	Deleted
)
SELECT	G.ApplicationID,
		G.ID,
		REPLACE(REPLACE(G.Title, N'ي', N'ی'), N'ك', N'ک'),
		REPLACE(REPLACE(G.[Description], N'ي', N'ی'), N'ك', N'ک'),
		ISNULL(G.CreatorUserId, @UID),
		ISNULL(G.CreateDate, @Now),
		0
FROM [dbo].[UserGroups] AS G

GO



SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[USR_UserGroupMembers](
	[GroupID] [uniqueidentifier] NOT NULL,
	[UserID] [uniqueidentifier] NOT NULL,
	[CreatorUserID] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL,
	[ApplicationID] [uniqueidentifier] NULL
 CONSTRAINT [PK_USR_UserGroupMembers] PRIMARY KEY CLUSTERED 
(
	[GroupID] ASC,
	[UserID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[USR_UserGroupMembers]  WITH CHECK ADD  CONSTRAINT [FK_USR_UserGroupMembers_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[USR_UserGroupMembers] CHECK CONSTRAINT [FK_USR_UserGroupMembers_aspnet_Applications]
GO


ALTER TABLE [dbo].[USR_UserGroupMembers]  WITH CHECK ADD  CONSTRAINT [FK_USR_UserGroupMembers_USR_UserGroups] FOREIGN KEY([GroupID])
REFERENCES [dbo].[USR_UserGroups] ([GroupID])
GO

ALTER TABLE [dbo].[USR_UserGroupMembers] CHECK CONSTRAINT [FK_USR_UserGroupMembers_USR_UserGroups]
GO


ALTER TABLE [dbo].[USR_UserGroupMembers]  WITH CHECK ADD  CONSTRAINT [FK_USR_UserGroupMembers_aspnet_Users] FOREIGN KEY([UserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[USR_UserGroupMembers] CHECK CONSTRAINT [FK_USR_UserGroupMembers_aspnet_Users]
GO


ALTER TABLE [dbo].[USR_UserGroupMembers]  WITH CHECK ADD  CONSTRAINT [FK_USR_UserGroupMembers_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[USR_UserGroupMembers] CHECK CONSTRAINT [FK_USR_UserGroupMembers_aspnet_Users_Creator]
GO


ALTER TABLE [dbo].[USR_UserGroupMembers]  WITH CHECK ADD  CONSTRAINT [FK_USR_UserGroupMembers_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[USR_UserGroupMembers] CHECK CONSTRAINT [FK_USR_UserGroupMembers_aspnet_Users_Modifier]
GO


DECLARE @UID uniqueidentifier = (SELECT TOP(1) UserId FROM [dbo].[aspnet_Users] WHERE LoweredUserName = N'admin')
DECLARE @Now datetime = GETDATE()

INSERT INTO [dbo].[USR_UserGroupMembers] (
	ApplicationID,
	GroupID,
	UserID,
	CreatorUserID,
	CreationDate,
	Deleted
)
SELECT DISTINCT
	G.ApplicationID,
	G.UserGroupId,
	G.UserId,
	@UID,
	ISNULL(G.[Date], @Now),
	0
FROM [dbo].[UserGroupUsers] AS G

GO



SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[USR_AccessRoles](
	[RoleID] [uniqueidentifier] NOT NULL,
	[Name] [varchar](100) NOT NULL,
	[Title] [nvarchar](2000) NOT NULL,
	[ApplicationID] [uniqueidentifier] NULL
 CONSTRAINT [PK_USR_AccessRoles] PRIMARY KEY CLUSTERED 
(
	[RoleID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[USR_AccessRoles]  WITH CHECK ADD  CONSTRAINT [FK_USR_AccessRoles_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[USR_AccessRoles] CHECK CONSTRAINT [FK_USR_AccessRoles_aspnet_Applications]
GO


INSERT INTO [dbo].[USR_AccessRoles] (
	ApplicationID,
	RoleID,
	Name,
	Title
)
SELECT DISTINCT ApplicationID, ID, [Role], Title
FROM [dbo].[AccessRoles]

GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[USR_UserGroupPermissions](
	[GroupID] [uniqueidentifier] NOT NULL,
	[RoleID] [uniqueidentifier] NOT NULL,
	[CreatorUserID] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL,
	[ApplicationID] [uniqueidentifier] NULL
 CONSTRAINT [PK_USR_UserGroupPermissions] PRIMARY KEY CLUSTERED 
(
	[GroupID] ASC,
	[RoleID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[USR_UserGroupPermissions]  WITH CHECK ADD  CONSTRAINT [FK_USR_UserGroupPermissions_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[USR_UserGroupPermissions] CHECK CONSTRAINT [FK_USR_UserGroupPermissions_aspnet_Applications]
GO


ALTER TABLE [dbo].[USR_UserGroupPermissions]  WITH CHECK ADD  CONSTRAINT [FK_USR_UserGroupPermissions_USR_UserGroups] FOREIGN KEY([GroupID])
REFERENCES [dbo].[USR_UserGroups] ([GroupID])
GO

ALTER TABLE [dbo].[USR_UserGroupPermissions] CHECK CONSTRAINT [FK_USR_UserGroupPermissions_USR_UserGroups]
GO


ALTER TABLE [dbo].[USR_UserGroupPermissions]  WITH CHECK ADD  CONSTRAINT [FK_USR_UserGroupPermissions_USR_AccessRoles] FOREIGN KEY([RoleID])
REFERENCES [dbo].[USR_AccessRoles] ([RoleID])
GO

ALTER TABLE [dbo].[USR_UserGroupPermissions] CHECK CONSTRAINT [FK_USR_UserGroupPermissions_USR_AccessRoles]
GO


ALTER TABLE [dbo].[USR_UserGroupPermissions]  WITH CHECK ADD  CONSTRAINT [FK_USR_UserGroupPermissions_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[USR_UserGroupPermissions] CHECK CONSTRAINT [FK_USR_UserGroupPermissions_aspnet_Users_Creator]
GO


ALTER TABLE [dbo].[USR_UserGroupPermissions]  WITH CHECK ADD  CONSTRAINT [FK_USR_UserGroupPermissions_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[USR_UserGroupPermissions] CHECK CONSTRAINT [FK_USR_UserGroupPermissions_aspnet_Users_Modifier]
GO


DECLARE @UID uniqueidentifier = (SELECT TOP(1) UserId FROM [dbo].[aspnet_Users] WHERE LoweredUserName = N'admin')
DECLARE @Now datetime = GETDATE()

INSERT INTO [dbo].[USR_UserGroupPermissions] (
	ApplicationID,
	GroupID,
	RoleID,
	CreatorUserID,
	CreationDate,
	Deleted
)
SELECT DISTINCT
	G.ApplicationID,
	G.UserGroupId,
	G.AccessRoleId,
	@UID,
	ISNULL(G.[Date], @Now),
	0
FROM [dbo].[UserGroupAccessRoles] AS G

GO



DROP TABLE [dbo].[UserGroupAccessRoles]
GO

DROP TABLE [dbo].[UserGroupUsers]
GO

DROP TABLE [dbo].[UserGroups]
GO

DROP TABLE [dbo].[AccessRoles]
GO



DROP TABLE [dbo].[GapColorConst]
GO

DROP TABLE [dbo].[MetricsConst]
GO

DROP TABLE [dbo].[PersonalNews]
GO

DROP TABLE [dbo].[NewsObjectTypes]
GO

DROP TABLE [dbo].[NGeneralQuestions]
GO

DROP TABLE [dbo].[NQuestions]
GO

DROP TABLE [dbo].[NodeMetrics]
GO

DROP TABLE [dbo].[NodeSetting]
GO

DROP TABLE [dbo].[OrganProfile]
GO



ALTER TABLE [dbo].[DCT_Trees]
DROP CONSTRAINT FK_DCT_Trees_DCT_TreeTypes
GO

ALTER TABLE [dbo].[DCT_Trees]
DROP COLUMN TreeTypeID
GO

DROP TABLE [dbo].[DCT_TreeTypes]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



UPDATE [dbo].[AppSetting]
	SET [Version] = 'v27.3.6.1' -- 13950227
GO