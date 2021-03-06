USE [EKM_App]
GO

/****** Object:  View [dbo].[CN_View_Nodes_Normal]    Script Date: 06/22/2012 13:03:22 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


IF EXISTS(select * FROM sys.views where name = 'CN_View_Nodes_Normal')
DROP VIEW [dbo].[CN_View_Nodes_Normal]
GO


-- Functions

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CN_FN_GetListTypeID]') 
    AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[CN_FN_GetListTypeID]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CN_FN_GetDepartmentGroupListTypeID]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[CN_FN_GetDepartmentGroupListTypeID]
GO

-- end of Functions

-- Views

IF EXISTS(select * FROM sys.views where name = 'CN_View_Lists')
DROP VIEW [dbo].[CN_View_Lists]
GO

-- end of Views

-- CN

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_GetNodeHirarchyAdminIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_GetNodeHirarchyAdminIDs]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetNodeHirarchyAdminIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetNodeHirarchyAdminIDs]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_GetNodeHirarchy]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_GetNodeHirarchy]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_GetNodeHirarchy]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_GetNodeHirarchy]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_P_AddNodeCreators]') AND
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_P_AddNodeCreators]
GO

-- end of CN

-- DataExchange

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[DE_UpdateUsers]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[DE_UpdateUsers]
GO

-- end of DataExchange

-- USR

IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[DoAspnet_userAfterCascadeDelete]'))
DROP TRIGGER [dbo].[DoAspnet_userAfterCascadeDelete]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_CreateProfile]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_CreateProfile]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_P_SetGeneralInfo]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_P_SetGeneralInfo]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[USR_SetGeneralInfo]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[USR_SetGeneralInfo]
GO

-- end of USR

-- WF

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[WF_SetStateShowOwnerName]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[WF_SetStateShowOwnerName]
GO

-- end of WF

-- WF Reports

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[WF_NodeCreatorsReport]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[WF_NodeCreatorsReport]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[WF_UserCreatedNodesReport]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[WF_UserCreatedNodesReport]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[WF_NodesCreatedNodesReport]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[WF_NodesCreatedNodesReport]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[WF_NodeCreatedNodesReport]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[WF_NodeCreatedNodesReport]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[WF_AddService]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[WF_AddService]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[WF_ModifyService]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[WF_ModifyService]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[WF_RemoveService]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[WF_RemoveService]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[WF_P_GetServicesByIDs]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[WF_P_GetServicesByIDs]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[WF_GetServices]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[WF_GetServices]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[WF_GetService]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[WF_GetService]
GO

-- end of WF Reports


-- User Defined Types

IF EXISTS (SELECT * FROM sys.types WHERE is_table_type = 1 AND name = 'NodesHirarchyTableType')
DROP TYPE dbo.NodesHirarchyTableType
GO

IF EXISTS (SELECT * FROM sys.types WHERE is_table_type = 1 AND name = 'ExchangeUserTableType')
DROP TYPE dbo.ExchangeUserTableType
GO

-- User Defined Types


CREATE TABLE [dbo].[USR_EmailAddresses](
	[EmailID] [uniqueidentifier] NOT NULL,
	[UserID] [uniqueidentifier] NOT NULL,
	[EmailAddress] [varchar] (100) NOT NULL,
	[CreatorUserID] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL
 CONSTRAINT [PK_USR_EmailAddresses] PRIMARY KEY CLUSTERED 
(
	[EmailID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[USR_EmailAddresses]  WITH CHECK ADD  CONSTRAINT [FK_USR_EmailAddresses_USR_Profile] FOREIGN KEY(UserID)
REFERENCES [dbo].[aspnet_Users] (UserId)
GO

ALTER TABLE [dbo].[USR_EmailAddresses] CHECK CONSTRAINT [FK_USR_EmailAddresses_USR_Profile]
GO

ALTER TABLE [dbo].[USR_EmailAddresses]  WITH CHECK ADD  CONSTRAINT [FK_USR_EmailAddresses_USR_Profile_Creator] FOREIGN KEY(CreatorUserID)
REFERENCES [dbo].[aspnet_Users] (UserId)
GO

ALTER TABLE [dbo].[USR_EmailAddresses] CHECK CONSTRAINT [FK_USR_EmailAddresses_USR_Profile_Creator]
GO

ALTER TABLE [dbo].[USR_EmailAddresses]  WITH CHECK ADD  CONSTRAINT [FK_USR_EmailAddresses_USR_Profile_Modifier] FOREIGN KEY(LastModifierUserID)
REFERENCES [dbo].[aspnet_Users] (UserId)
GO

ALTER TABLE [dbo].[USR_EmailAddresses] CHECK CONSTRAINT [FK_USR_EmailAddresses_USR_Profile_Modifier]
GO


CREATE TABLE [dbo].[USR_PhoneNumbers](
	[NumberID]				UNIQUEIDENTIFIER NOT NULL,
	[UserID]				UNIQUEIDENTIFIER NOT NULL,
	[PhoneNumber]			VARCHAR (50) NOT NULL,
	[PhoneType]				VARCHAR	(20) NOT NULL,
	[CreatorUserID]			UNIQUEIDENTIFIER NOT NULL,
	[CreationDate]			DATETIME NOT NULL,
	[LastModifierUserID]	UNIQUEIDENTIFIER NULL,
	[LastModificationDate]	DATETIME NULL,
	[Deleted]				BIT NOT NULL
 CONSTRAINT [PK_USR_PhoneNumbers] PRIMARY KEY CLUSTERED 
(
	[NumberID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[USR_PhoneNumbers]  WITH CHECK ADD  CONSTRAINT [FK_USR_PhoneNumbers_USR_Profile] FOREIGN KEY(UserID)
REFERENCES [dbo].[aspnet_Users] (UserId)
GO

ALTER TABLE [dbo].[USR_PhoneNumbers] CHECK CONSTRAINT [FK_USR_PhoneNumbers_USR_Profile]
GO

ALTER TABLE [dbo].[USR_PhoneNumbers]  WITH CHECK ADD  CONSTRAINT [FK_USR_PhoneNumbers_USR_Profile_Creator] FOREIGN KEY(CreatorUserID)
REFERENCES [dbo].[aspnet_Users] (UserId)
GO

ALTER TABLE [dbo].[USR_PhoneNumbers] CHECK CONSTRAINT [FK_USR_PhoneNumbers_USR_Profile_Creator]
GO

ALTER TABLE [dbo].[USR_PhoneNumbers]  WITH CHECK ADD  CONSTRAINT [FK_USR_PhoneNumbers_USR_Profile_Modifier] FOREIGN KEY(LastModifierUserID)
REFERENCES [dbo].[aspnet_Users] (UserId)
GO

ALTER TABLE [dbo].[USR_PhoneNumbers] CHECK CONSTRAINT [FK_USR_PhoneNumbers_USR_Profile_Modifier]
GO



IF EXISTS(select * FROM sys.views where name = 'Users_Normal')
DROP VIEW [dbo].[Users_Normal]
GO


ALTER TABLE [dbo].[USR_Profile]
DROP COLUMN [Phone], [Mobile], [Email]
GO


ALTER TABLE [dbo].[USR_Profile]
ADD [MainPhoneID] uniqueidentifier null,
	[MainEmailID] uniqueidentifier null,
	[EmploymentType] varchar(50) null,
	[Lang] varchar(20) null
GO


ALTER TABLE [dbo].[USR_Profile]  WITH CHECK ADD  CONSTRAINT [FK_USR_Profile_USR_EmailAddresses] FOREIGN KEY(MainEmailID)
REFERENCES [dbo].[USR_EmailAddresses] (EmailID)
GO

ALTER TABLE [dbo].[USR_Profile] CHECK CONSTRAINT [FK_USR_Profile_USR_EmailAddresses]
GO

ALTER TABLE [dbo].[USR_Profile]  WITH CHECK ADD  CONSTRAINT [FK_USR_Profile_USR_PhoneNumbers] FOREIGN KEY(MainPhoneID)
REFERENCES [dbo].[USR_PhoneNumbers] (NumberID)
GO

ALTER TABLE [dbo].[USR_Profile] CHECK CONSTRAINT [FK_USR_Profile_USR_PhoneNumbers]
GO


/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER TABLE [dbo].[CN_NodeTypes]
DROP COLUMN [FormID]
GO


/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[CN_Services](
	[NodeTypeID] [uniqueidentifier] NOT NULL,
	[ServiceTitle] [nvarchar](512) NULL,
	[ServiceDescription] [nvarchar](4000) NULL,
	[SuccessMessage] [nvarchar] (4000) NULL,
	[EnableContribution] [bit] NOT NULL,
	[AdminType] [varchar](20) NULL,
	[AdminNodeID] [uniqueidentifier] NULL,
	[SequenceNumber] [int] NOT NULL,
	[MaxAcceptableAdminLevel] [int] NULL,
	[LimitAttachedFilesTo] [varchar](2000) NULL,
	[MaxAttachedFileSize] [int] NULL,
	[MaxAttachedFilesCount] [int] NULL,
	[EditableForAdmin] [bit] NOT NULL,
	[EditableForCreator] [bit] NOT NULL,
	[EditableForOwners] [bit] NOT NULL,
	[EditableForExperts] [bit] NOT NULL,
	[EditableForMembers] [bit] NOT NULL,
	[Deleted] [bit] NOT NULL
 CONSTRAINT [PK_CN_Services] PRIMARY KEY CLUSTERED 
(
	[NodeTypeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


ALTER TABLE [dbo].[CN_Services]  WITH CHECK ADD  CONSTRAINT [FK_CN_Services_CN_NodeTypes] FOREIGN KEY([NodeTypeID])
REFERENCES [dbo].[CN_NodeTypes] ([NodeTypeID])
GO

ALTER TABLE [dbo].[CN_Services] CHECK CONSTRAINT [FK_CN_Services_CN_NodeTypes]
GO

ALTER TABLE [dbo].[CN_Services]  WITH CHECK ADD  CONSTRAINT [FK_CN_Services_CN_Nodes] FOREIGN KEY([AdminNodeID])
REFERENCES [dbo].[CN_Nodes] ([NodeID])
GO

ALTER TABLE [dbo].[CN_Services] CHECK CONSTRAINT [FK_CN_Services_CN_Nodes]
GO

/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[CN_AdminTypeLimits](
	[NodeTypeID] [uniqueidentifier] NOT NULL,
	[LimitNodeTypeID] [uniqueidentifier] NOT NULL,
	[CreatorUserID] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL
 CONSTRAINT [PK_CN_AdminTypeLimits] PRIMARY KEY CLUSTERED 
(
	[NodeTypeID] ASC,
	[LimitNodeTypeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


ALTER TABLE [dbo].[CN_AdminTypeLimits]  WITH CHECK ADD  CONSTRAINT [FK_CN_AdminTypeLimits_CN_NodeTypes] FOREIGN KEY([NodeTypeID])
REFERENCES [dbo].[CN_NodeTypes] ([NodeTypeID])
GO

ALTER TABLE [dbo].[CN_AdminTypeLimits] CHECK CONSTRAINT [FK_CN_AdminTypeLimits_CN_NodeTypes]
GO

ALTER TABLE [dbo].[CN_AdminTypeLimits]  WITH CHECK ADD  CONSTRAINT [FK_CN_AdminTypeLimits_CN_NodeTypes_Limit] FOREIGN KEY([LimitNodeTypeID])
REFERENCES [dbo].[CN_NodeTypes] ([NodeTypeID])
GO

ALTER TABLE [dbo].[CN_AdminTypeLimits] CHECK CONSTRAINT [FK_CN_AdminTypeLimits_CN_NodeTypes_Limit]
GO

ALTER TABLE [dbo].[CN_AdminTypeLimits]  WITH CHECK ADD  CONSTRAINT [FK_CN_AdminTypeLimits_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[CN_AdminTypeLimits] CHECK CONSTRAINT [FK_CN_AdminTypeLimits_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[CN_AdminTypeLimits]  WITH CHECK ADD  CONSTRAINT [FK_CN_AdminTypeLimits_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[CN_AdminTypeLimits] CHECK CONSTRAINT [FK_CN_AdminTypeLimits_aspnet_Users_Modifier]
GO

/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[CN_Extensions](
	[OwnerID] [uniqueidentifier] NOT NULL,
	[Extension] [varchar](50) NOT NULL, -- Wiki, Form, Posts, Experts, Members, Group, Events, Timeline
	[Title] [nvarchar](100) NULL,
	[SequenceNumber] [int] NOT NULL,
	[CreatorUserID] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL
 CONSTRAINT [PK_CN_Extensions] PRIMARY KEY CLUSTERED 
(
	[OwnerID] ASC,
	[Extension] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


ALTER TABLE [dbo].[CN_Extensions]  WITH CHECK ADD  CONSTRAINT [FK_CN_Extensions_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[CN_Extensions] CHECK CONSTRAINT [FK_CN_Extensions_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[CN_Extensions]  WITH CHECK ADD  CONSTRAINT [FK_CN_Extensions_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[CN_Extensions] CHECK CONSTRAINT [FK_CN_Extensions_aspnet_Users_Modifier]
GO


/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[CN_ServiceAdmins](
	[NodeTypeID] [uniqueidentifier] NOT NULL,
	[UserID] [uniqueidentifier] NOT NULL,
	[CreatorUserID] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL
 CONSTRAINT [PK_CN_ServiceAdmins] PRIMARY KEY CLUSTERED 
(
	[NodeTypeID] ASC,
	[UserID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


ALTER TABLE [dbo].[CN_ServiceAdmins]  WITH CHECK ADD  CONSTRAINT [FK_CN_ServiceAdmins_CN_NodeTypes] FOREIGN KEY([NodeTypeID])
REFERENCES [dbo].[CN_NodeTypes] ([NodeTypeID])
GO

ALTER TABLE [dbo].[CN_ServiceAdmins] CHECK CONSTRAINT [FK_CN_ServiceAdmins_CN_NodeTypes]
GO

ALTER TABLE [dbo].[CN_ServiceAdmins]  WITH CHECK ADD  CONSTRAINT [FK_CN_ServiceAdmins_aspnet_Users] FOREIGN KEY([UserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[CN_ServiceAdmins] CHECK CONSTRAINT [FK_CN_ServiceAdmins_aspnet_Users]
GO

ALTER TABLE [dbo].[CN_ServiceAdmins]  WITH CHECK ADD  CONSTRAINT [FK_CN_ServiceAdmins_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[CN_ServiceAdmins] CHECK CONSTRAINT [FK_CN_ServiceAdmins_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[CN_ServiceAdmins]  WITH CHECK ADD  CONSTRAINT [FK_CN_ServiceAdmins_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[CN_ServiceAdmins] CHECK CONSTRAINT [FK_CN_ServiceAdmins_aspnet_Users_Modifier]
GO


/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[CN_FreeUsers](
	[NodeTypeID] [uniqueidentifier] NOT NULL,
	[UserID] [uniqueidentifier] NOT NULL,
	[CreatorUserID] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL
 CONSTRAINT [PK_CN_FreeUsers] PRIMARY KEY CLUSTERED 
(
	[NodeTypeID] ASC,
	[UserID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


ALTER TABLE [dbo].[CN_FreeUsers]  WITH CHECK ADD  CONSTRAINT [FK_CN_FreeUsers_CN_NodeTypes] FOREIGN KEY([NodeTypeID])
REFERENCES [dbo].[CN_NodeTypes] ([NodeTypeID])
GO

ALTER TABLE [dbo].[CN_FreeUsers] CHECK CONSTRAINT [FK_CN_FreeUsers_CN_NodeTypes]
GO

ALTER TABLE [dbo].[CN_FreeUsers]  WITH CHECK ADD  CONSTRAINT [FK_CN_FreeUsers_aspnet_Users] FOREIGN KEY([UserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[CN_FreeUsers] CHECK CONSTRAINT [FK_CN_FreeUsers_aspnet_Users]
GO

ALTER TABLE [dbo].[CN_FreeUsers]  WITH CHECK ADD  CONSTRAINT [FK_CN_FreeUsers_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[CN_FreeUsers] CHECK CONSTRAINT [FK_CN_FreeUsers_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[CN_FreeUsers]  WITH CHECK ADD  CONSTRAINT [FK_CN_FreeUsers_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[CN_FreeUsers] CHECK CONSTRAINT [FK_CN_FreeUsers_aspnet_Users_Modifier]
GO


/****** Object:  Table [dbo].[WF_StateConnectionAudience]    Script Date: 06/10/2013 09:30:24 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO


CREATE TABLE [dbo].[NTFN_MessageTemplates](
	[TemplateID] [uniqueidentifier] NOT NULL,
	[OwnerID] [uniqueidentifier] NOT NULL,
	[BodyText] [nvarchar](max) NOT NULL,
	[AudienceType] [varchar](20) NULL,
	[AudienceRefOwnerID] [uniqueidentifier] NULL,
	[AudienceNodeID] [uniqueidentifier] NULL,
	[AudienceNodeAdmin] [bit] NOT NULL,
	[CreatorUserID] [uniqueidentifier] NULL,
	[CreationDate] [datetime] NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL,
 CONSTRAINT [PK_NTFN_MessageTemplates] PRIMARY KEY CLUSTERED 
(
	[TemplateID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


ALTER TABLE [dbo].[NTFN_MessageTemplates]  WITH CHECK ADD  CONSTRAINT [FK_NTFN_MessageTemplates_CN_Nodes] FOREIGN KEY([AudienceNodeID])
REFERENCES [dbo].[CN_Nodes] ([NodeID])
GO

ALTER TABLE [dbo].[NTFN_MessageTemplates] CHECK CONSTRAINT [FK_NTFN_MessageTemplates_CN_Nodes]
GO

ALTER TABLE [dbo].[NTFN_MessageTemplates]  WITH CHECK ADD  CONSTRAINT [FK_NTFN_MessageTemplates_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[NTFN_MessageTemplates] CHECK CONSTRAINT [FK_NTFN_MessageTemplates_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[NTFN_MessageTemplates]  WITH CHECK ADD  CONSTRAINT [FK_NTFN_MessageTemplates_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[NTFN_MessageTemplates] CHECK CONSTRAINT [FK_NTFN_MessageTemplates_aspnet_Users_Modifier]
GO




ALTER TABLE [dbo].[FG_ExtendedFormElements]
ADD [Necessary] [bit] NULL

GO



CREATE TABLE [dbo].[FG_FormOwners](
	[OwnerID] [uniqueidentifier] NOT NULL,
	[FormID] [uniqueidentifier] NOT NULL,
	[CreatorUserID] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL
 CONSTRAINT [PK_FG_FormOwners] PRIMARY KEY CLUSTERED 
(
	[OwnerID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


ALTER TABLE [dbo].[FG_FormOwners]  WITH CHECK ADD  CONSTRAINT [FK_FG_FormOwners_FG_ExtendedForms] FOREIGN KEY([FormID])
REFERENCES [dbo].[FG_ExtendedForms] ([FormID])
GO

ALTER TABLE [dbo].[FG_FormOwners] CHECK CONSTRAINT [FK_FG_FormOwners_FG_ExtendedForms]
GO

ALTER TABLE [dbo].[FG_FormOwners]  WITH CHECK ADD  CONSTRAINT [FK_FG_FormOwners_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[FG_FormOwners] CHECK CONSTRAINT [FK_FG_FormOwners_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[FG_FormOwners]  WITH CHECK ADD  CONSTRAINT [FK_FG_FormOwners_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[FG_FormOwners] CHECK CONSTRAINT [FK_FG_FormOwners_aspnet_Users_Modifier]
GO


CREATE TABLE [dbo].[FG_ElementLimits](
	[OwnerID] [uniqueidentifier] NOT NULL,
	[ElementID] [uniqueidentifier] NOT NULL,
	[Necessary] [bit] NOT NULL,
	[CreatorUserID] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL
 CONSTRAINT [PK_FG_ElementLimits] PRIMARY KEY CLUSTERED 
(
	[OwnerID] ASC,
	[ElementID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


ALTER TABLE [dbo].[FG_ElementLimits]  WITH CHECK ADD  CONSTRAINT [FK_FG_ElementLimits_FG_FormOwners] FOREIGN KEY([OwnerID])
REFERENCES [dbo].[FG_FormOwners] ([OwnerID])
GO

ALTER TABLE [dbo].[FG_ElementLimits] CHECK CONSTRAINT [FK_FG_ElementLimits_FG_FormOwners]
GO

ALTER TABLE [dbo].[FG_ElementLimits]  WITH CHECK ADD  CONSTRAINT [FK_FG_ElementLimits_FG_ExtendedFormElements] FOREIGN KEY([ElementID])
REFERENCES [dbo].[FG_ExtendedFormElements] ([ElementID])
GO

ALTER TABLE [dbo].[FG_ElementLimits] CHECK CONSTRAINT [FK_FG_ElementLimits_FG_ExtendedFormElements]
GO

ALTER TABLE [dbo].[FG_ElementLimits]  WITH CHECK ADD  CONSTRAINT [FK_FG_ElementLimits_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[FG_ElementLimits] CHECK CONSTRAINT [FK_FG_ElementLimits_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[FG_ElementLimits]  WITH CHECK ADD  CONSTRAINT [FK_FG_ElementLimits_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[FG_ElementLimits] CHECK CONSTRAINT [FK_FG_ElementLimits_aspnet_Users_Modifier]
GO


ALTER TABLE [dbo].[PRVC_Audience]
ADD [PrivacyType] [varchar](50) NULL
GO


CREATE TABLE [dbo].[PRVC_PrivacyType](
	[ObjectID] [uniqueidentifier] NOT NULL,
	[PrivacyType] [varchar](20) NOT NULL,
	[CreatorUserID] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL
 CONSTRAINT [PK_PRVC_PrivacyType] PRIMARY KEY CLUSTERED 
(
	[ObjectID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


ALTER TABLE [dbo].[PRVC_PrivacyType]  WITH CHECK ADD  CONSTRAINT [FK_PRVC_PrivacyType_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[PRVC_PrivacyType] CHECK CONSTRAINT [FK_PRVC_PrivacyType_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[PRVC_PrivacyType]  WITH CHECK ADD  CONSTRAINT [FK_PRVC_PrivacyType_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[PRVC_PrivacyType] CHECK CONSTRAINT [FK_PRVC_PrivacyType_aspnet_Users_Modifier]
GO

/****** Object:  Table [dbo].[FG_InstanceElements]    Script Date: 04/30/2014 18:41:19 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[FG_TMPInstanceElements](
	[ElementID] [uniqueidentifier] NOT NULL,
	[InstanceID] [uniqueidentifier] NOT NULL,
	[RefElementID] [uniqueidentifier] NULL,
	[Title] [nvarchar](2000) NOT NULL,
	[SequenceNumber] [int] NOT NULL,
	[Type] [varchar](20) NOT NULL,
	[Info] [nvarchar](4000) NULL,
	[TextValue] [nvarchar](max) NULL,
	[FloatValue] [float] NULL,
	[BitValue] [bit] NULL,
	[DateValue] [datetime] NULL,
	[GuidValue] [uniqueidentifier] NULL,
	[CreatorUserID] [uniqueidentifier] NULL,
	[CreationDate] [datetime] NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL,
 CONSTRAINT [PK_FG_TMPInstanceElements] PRIMARY KEY CLUSTERED 
(
	[ElementID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


INSERT INTO [dbo].[FG_TMPInstanceElements]([ElementID], [InstanceID], [RefElementID], 
	[Title], [SequenceNumber], [Type], [Info], [TextValue], [CreatorUserID], 
	[CreationDate], [LastModifierUserID], [LastModificationDate], [Deleted]
)
SELECT ElementID, InstanceID, RefElementID, Title, SequenceNumber, [Type], Info, BodyText, 
	CreatorUserID, CreationDate, LastModifierUserID, LastModificationDate, Deleted
FROM [dbo].[FG_InstanceElements]

GO


DROP TABLE [dbo].[FG_InstanceElements]
GO


CREATE TABLE [dbo].[FG_InstanceElements](
	[ElementID] [uniqueidentifier] NOT NULL,
	[InstanceID] [uniqueidentifier] NOT NULL,
	[RefElementID] [uniqueidentifier] NULL,
	[Title] [nvarchar](2000) NOT NULL,
	[SequenceNumber] [int] NOT NULL,
	[Type] [varchar](20) NOT NULL,
	[Info] [nvarchar](4000) NULL,
	[TextValue] [nvarchar](max) NULL,
	[FloatValue] [float] NULL,
	[BitValue] [bit] NULL,
	[DateValue] [datetime] NULL,
	[GuidValue] [uniqueidentifier] NULL,
	[CreatorUserID] [uniqueidentifier] NULL,
	[CreationDate] [datetime] NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL,
 CONSTRAINT [PK_FG_InstanceElements] PRIMARY KEY CLUSTERED 
(
	[ElementID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[FG_InstanceElements]  WITH CHECK ADD  CONSTRAINT [FK_FG_InstanceElements_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[FG_InstanceElements] CHECK CONSTRAINT [FK_FG_InstanceElements_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[FG_InstanceElements]  WITH CHECK ADD  CONSTRAINT [FK_FG_InstanceElements_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[FG_InstanceElements] CHECK CONSTRAINT [FK_FG_InstanceElements_aspnet_Users_Modifier]
GO

ALTER TABLE [dbo].[FG_InstanceElements]  WITH CHECK ADD  CONSTRAINT [FK_FG_InstanceElements_FG_ExtendedFormElements] FOREIGN KEY([RefElementID])
REFERENCES [dbo].[FG_ExtendedFormElements] ([ElementID])
GO

ALTER TABLE [dbo].[FG_InstanceElements] CHECK CONSTRAINT [FK_FG_InstanceElements_FG_ExtendedFormElements]
GO

ALTER TABLE [dbo].[FG_InstanceElements]  WITH CHECK ADD  CONSTRAINT [FK_FG_InstanceElements_FG_FormInstances] FOREIGN KEY([InstanceID])
REFERENCES [dbo].[FG_FormInstances] ([InstanceID])
GO

ALTER TABLE [dbo].[FG_InstanceElements] CHECK CONSTRAINT [FK_FG_InstanceElements_FG_FormInstances]
GO


INSERT INTO [dbo].[FG_InstanceElements]
SELECT *
FROM [dbo].[FG_TMPInstanceElements]
GO

DROP TABLE [dbo].[FG_TMPInstanceElements]
GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[FG_SaveFormInstanceElements]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[FG_SaveFormInstanceElements]
GO

DROP TYPE [dbo].[FormElementTableType]
GO

/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[NTFN_Dashboards](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[UserID] [uniqueidentifier] NOT NULL,
	[NodeID] [uniqueidentifier] NOT NULL,
	[RefItemID] [uniqueidentifier] NOT NULL,
	[Type] [varchar](20) NOT NULL,
	[Info] [nvarchar](max) NULL,
	[Removable] [bit] NOT NULL,
	[SenderUserID] [uniqueidentifier] NULL,
	[SendDate] [datetime] NOT NULL,
	[ExpirationDate] [datetime] NULL,
	[Seen] [bit] NOT NULL,
	[ViewDate] [datetime] NULL,
	[Done] [bit] NOT NULL,
	[ActionDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL
 CONSTRAINT [PK_NTFN_Dashboards] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


ALTER TABLE [dbo].[NTFN_Dashboards]  WITH CHECK ADD  CONSTRAINT [FK_NTFN_Dashboards_aspnet_Users] FOREIGN KEY([UserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[NTFN_Dashboards] CHECK CONSTRAINT [FK_NTFN_Dashboards_aspnet_Users]
GO


/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER TABLE [dbo].[CN_Nodes]
ADD [AreaID] [uniqueidentifier] NULL
GO


ALTER TABLE [dbo].[CN_Nodes]  WITH CHECK ADD  CONSTRAINT [FK_CN_Nodes_CN_Nodes_Area] FOREIGN KEY([AreaID])
REFERENCES [dbo].[CN_Nodes] ([NodeID])
GO

ALTER TABLE [dbo].[CN_Nodes] CHECK CONSTRAINT [FK_CN_Nodes_CN_Nodes_Area]
GO

/****** Object:  Table [dbo].[FG_FormInstances]    Script Date: 05/14/2014 18:19:54 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

ALTER TABLE [dbo].[FG_InstanceElements] 
DROP CONSTRAINT [FK_FG_InstanceElements_FG_FormInstances]
GO

CREATE TABLE [dbo].[FG_TMPFormInstances](
	[InstanceID] [uniqueidentifier] NOT NULL,
	[FormID] [uniqueidentifier] NOT NULL,
	[OwnerID] [uniqueidentifier] NOT NULL,
	[OwnerType] [varchar](20) NULL,
	[DirectorID] [uniqueidentifier] NULL,
	[Admin] [bit] NOT NULL,
	[Filled] [bit] NOT NULL,
	[FillingDate] [datetime] NULL,
	[CreatorUserID] [uniqueidentifier] NULL,
	[CreationDate] [datetime] NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL
 CONSTRAINT [PK_FG_TMPFormInstances] PRIMARY KEY CLUSTERED 
(
	[InstanceID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


INSERT INTO [dbo].[FG_TMPFormInstances](InstanceID, FormID, OwnerID, OwnerType,
	DirectorID, [Admin], Filled, FillingDate, CreatorUserID, CreationDate,
	LastModifierUserID, LastModificationDate, Deleted)
SELECT InstanceID, FormID, OwnerID, OwnerType, DirectorID, [Admin], Filled, FillingDate, 
	CreatorUserID, CreationDate, LastModifierUserID, LastModificationDate, Deleted
FROM [dbo].[FG_FormInstances]

GO

DROP TABLE [dbo].[FG_FormInstances]
GO

CREATE TABLE [dbo].[FG_FormInstances](
	[InstanceID] [uniqueidentifier] NOT NULL,
	[FormID] [uniqueidentifier] NOT NULL,
	[OwnerID] [uniqueidentifier] NOT NULL,
	[OwnerType] [varchar](20) NULL,
	[DirectorID] [uniqueidentifier] NULL,
	[Admin] [bit] NOT NULL,
	[Filled] [bit] NOT NULL,
	[FillingDate] [datetime] NULL,
	[CreatorUserID] [uniqueidentifier] NULL,
	[CreationDate] [datetime] NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL
 CONSTRAINT [PK_FG_FormInstances] PRIMARY KEY CLUSTERED 
(
	[InstanceID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


ALTER TABLE [dbo].[FG_FormInstances]  WITH CHECK ADD  CONSTRAINT [FK_FG_FormInstances_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[FG_FormInstances] CHECK CONSTRAINT [FK_FG_FormInstances_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[FG_FormInstances]  WITH CHECK ADD  CONSTRAINT [FK_FG_FormInstances_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[FG_FormInstances] CHECK CONSTRAINT [FK_FG_FormInstances_aspnet_Users_Modifier]
GO

ALTER TABLE [dbo].[FG_FormInstances]  WITH CHECK ADD  CONSTRAINT [FK_FG_FormInstances_FG_ExtendedForms] FOREIGN KEY([FormID])
REFERENCES [dbo].[FG_ExtendedForms] ([FormID])
GO

ALTER TABLE [dbo].[FG_FormInstances] CHECK CONSTRAINT [FK_FG_FormInstances_FG_ExtendedForms]
GO



INSERT INTO [dbo].[FG_FormInstances]
SELECT * FROM [dbo].[FG_TMPFormInstances]

GO

DROP TABLE [dbo].[FG_TMPFormInstances]
GO


ALTER TABLE [dbo].[FG_InstanceElements]  WITH CHECK ADD  CONSTRAINT [FK_FG_InstanceElements_FG_FormInstances] FOREIGN KEY([InstanceID])
REFERENCES [dbo].[FG_FormInstances] ([InstanceID])
GO

ALTER TABLE [dbo].[FG_InstanceElements] CHECK CONSTRAINT [FK_FG_InstanceElements_FG_FormInstances]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[WF_WorkFlowOwners](
	[ID] [uniqueidentifier] NOT NULL,
	[NodeTypeID] [uniqueidentifier] NOT NULL,
	[WorkFlowID] [uniqueidentifier] NOT NULL,
	[CreatorUserID] [uniqueidentifier] NULL,
	[CreationDate] [datetime] NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL,
 CONSTRAINT [PK_WF_WorkFlowOwners] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


ALTER TABLE [dbo].[WF_WorkFlowOwners] ADD  CONSTRAINT [UK_WF_WorkFlowOwners_NodeTypeID_WorkFlowID] UNIQUE NONCLUSTERED 
(
	[NodeTypeID] ASC,
	[WorkFlowID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO


ALTER TABLE [dbo].[WF_WorkFlowOwners]  WITH CHECK ADD  CONSTRAINT [FK_WF_WorkFlowOwners_CN_NodeTypes_NodeTypeID] FOREIGN KEY([NodeTypeID])
REFERENCES [dbo].[CN_NodeTypes] ([NodeTypeID])
GO

ALTER TABLE [dbo].[WF_WorkFlowOwners] CHECK CONSTRAINT [FK_WF_WorkFlowOwners_CN_NodeTypes_NodeTypeID]
GO

ALTER TABLE [dbo].[WF_WorkFlowOwners]  WITH CHECK ADD  CONSTRAINT [FK_WF_WorkFlowOwners_WF_WorkFlows_WorkFlowID] FOREIGN KEY([WorkFlowID])
REFERENCES [dbo].[WF_WorkFlows] ([WorkFlowID])
GO

ALTER TABLE [dbo].[WF_WorkFlowOwners] CHECK CONSTRAINT [FK_WF_WorkFlowOwners_WF_WorkFlows_WorkFlowID]
GO

ALTER TABLE [dbo].[WF_WorkFlowOwners]  WITH CHECK ADD  CONSTRAINT [FK_WF_WorkFlowOwners_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[WF_WorkFlowOwners] CHECK CONSTRAINT [FK_WF_WorkFlowOwners_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[WF_WorkFlowOwners]  WITH CHECK ADD  CONSTRAINT [FK_WF_WorkFlowOwners_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[WF_WorkFlowOwners] CHECK CONSTRAINT [FK_WF_WorkFlowOwners_aspnet_Users_Modifier]
GO


INSERT INTO [dbo].[WF_WorkFlowOwners](
	ID,
	NodeTypeID,
	WorkFlowID,
	CreatorUserID,
	CreationDate,
	LastModifierUserID,
	LastModificationDate,
	Deleted
)
SELECT	ServiceID,
		NodeTypeID,
		WorkFlowID,
		CreatorUserID,
		CreationDate,
		LastModifierUserID,
		LastModificationDate,
		Deleted
FROM [dbo].[WF_Services] 

GO

/****** Object:  Table [dbo].[WF_StateConnections]    Script Date: 05/30/2014 13:05:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[WF_TMPStateConnections](
	[ID] [uniqueidentifier] NOT NULL,
	[WorkFlowID] [uniqueidentifier] NOT NULL,
	[InStateID] [uniqueidentifier] NOT NULL,
	[OutStateID] [uniqueidentifier] NOT NULL,
	[SequenceNumber] [int] NOT NULL,
	[Label] [nvarchar](255) NOT NULL,
	[AttachmentRequired] [bit] NOT NULL,
	[AttachmentTitle] [nvarchar](255) NULL,
	[NodeRequired] [bit] NOT NULL,
	[NodeTypeID] [uniqueidentifier] NULL,
	[NodeTypeDescription] [nvarchar](2000) NULL,
	[CreatorUserID] [uniqueidentifier] NULL,
	[CreationDate] [datetime] NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL,
 CONSTRAINT [PK_WF_TMPStateConnections] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


INSERT INTO [dbo].[WF_TMPStateConnections](
	ID, WorkFlowID, InStateID, OutStateID, SequenceNumber, Label, AttachmentRequired,
	AttachmentTitle, NodeRequired, NodeTypeID, NodeTypeDescription, CreatorUserID,
	CreationDate, LastModifierUserID, LastModificationDate, Deleted
)
SELECT PattAttachmentID, WorkFlowID, InStateID, OutStateID, SequenceNumber, Label,
	AttachmentRequired, AttachmentTitle, NodeRequired, NodeTypeID, NodeTypeDescription,
	CreatorUserID, CreationDate, LastModifierUserID, LastModificationDate, Deleted
FROM [dbo].[WF_StateConnections]

GO


DROP TABLE [dbo].[WF_StateConnections]
GO


CREATE TABLE [dbo].[WF_StateConnections](
	[ID] [uniqueidentifier] NOT NULL,
	[WorkFlowID] [uniqueidentifier] NOT NULL,
	[InStateID] [uniqueidentifier] NOT NULL,
	[OutStateID] [uniqueidentifier] NOT NULL,
	[SequenceNumber] [int] NOT NULL,
	[Label] [nvarchar](255) NOT NULL,
	[AttachmentRequired] [bit] NOT NULL,
	[AttachmentTitle] [nvarchar](255) NULL,
	[NodeRequired] [bit] NOT NULL,
	[NodeTypeID] [uniqueidentifier] NULL,
	[NodeTypeDescription] [nvarchar](2000) NULL,
	[CreatorUserID] [uniqueidentifier] NULL,
	[CreationDate] [datetime] NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL,
 CONSTRAINT [PK_WF_StateConnections] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


ALTER TABLE [dbo].[WF_StateConnections] ADD  CONSTRAINT [UK_WF_StateConnections] UNIQUE NONCLUSTERED 
(
	[WorkFlowID] ASC,
	[InStateID] ASC,
	[OutStateID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO


ALTER TABLE [dbo].[WF_StateConnections]  WITH CHECK ADD  CONSTRAINT [FK_WF_StateConnections_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[WF_StateConnections] CHECK CONSTRAINT [FK_WF_StateConnections_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[WF_StateConnections]  WITH CHECK ADD  CONSTRAINT [FK_WF_StateConnections_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[WF_StateConnections] CHECK CONSTRAINT [FK_WF_StateConnections_aspnet_Users_Modifier]
GO

ALTER TABLE [dbo].[WF_StateConnections]  WITH CHECK ADD  CONSTRAINT [FK_WF_StateConnections_CN_NodeTypes] FOREIGN KEY([NodeTypeID])
REFERENCES [dbo].[CN_NodeTypes] ([NodeTypeID])
GO

ALTER TABLE [dbo].[WF_StateConnections] CHECK CONSTRAINT [FK_WF_StateConnections_CN_NodeTypes]
GO

ALTER TABLE [dbo].[WF_StateConnections]  WITH CHECK ADD  CONSTRAINT [FK_WF_StateConnections_WF_States_In] FOREIGN KEY([InStateID])
REFERENCES [dbo].[WF_States] ([StateID])
GO

ALTER TABLE [dbo].[WF_StateConnections] CHECK CONSTRAINT [FK_WF_StateConnections_WF_States_In]
GO

ALTER TABLE [dbo].[WF_StateConnections]  WITH CHECK ADD  CONSTRAINT [FK_WF_StateConnections_WF_States_Out] FOREIGN KEY([OutStateID])
REFERENCES [dbo].[WF_States] ([StateID])
GO

ALTER TABLE [dbo].[WF_StateConnections] CHECK CONSTRAINT [FK_WF_StateConnections_WF_States_Out]
GO

ALTER TABLE [dbo].[WF_StateConnections]  WITH CHECK ADD  CONSTRAINT [FK_WF_StateConnections_WF_WorkFlows] FOREIGN KEY([WorkFlowID])
REFERENCES [dbo].[WF_WorkFlows] ([WorkFlowID])
GO

ALTER TABLE [dbo].[WF_StateConnections] CHECK CONSTRAINT [FK_WF_StateConnections_WF_WorkFlows]
GO



INSERT INTO [dbo].[WF_StateConnections]
SELECT *
FROM [dbo].[WF_TMPStateConnections]
GO


DROP TABLE [dbo].[WF_TMPStateConnections]
GO



INSERT INTO [dbo].[NTFN_MessageTemplates](
	TemplateID,
	OwnerID,
	BodyText,
	AudienceType,
	AudienceRefOwnerID,
	AudienceNodeID,
	AudienceNodeAdmin,
	CreatorUserID,
	CreationDate,
	LastModifierUserID,
	LastModificationDate,
	Deleted
)
SELECT	AutoMessageID,
		OwnerID,
		BodyText,
		AudienceType,
		RefStateID,
		NodeID,
		[Admin],
		CreatorUserID,
		CreationDate,
		LastModifierUserID,
		LastModificationDate,
		Deleted
FROM [dbo].[WF_AutoMessages]

GO


UPDATE [dbo].[NTFN_MessageTemplates]
	SET AudienceType = N'Creator'
WHERE AudienceType = N'SendToOwner'

GO

UPDATE [dbo].[NTFN_MessageTemplates]
	SET AudienceType = N'RefOwner'
WHERE AudienceType = N'RefState'

GO



INSERT INTO [dbo].[LG_Logs](
	UserID,
	[Action],
	[Date],
	Info,
	ModuleIdentifier
)
SELECT UserId, N'Search', [Date], SearchText, N'SRCH'
FROM [dbo].[UserSearchLogs]

GO


DROP TABLE [dbo].[UserSearchLogs]
GO


/****** Object:  Table [dbo].[WF_WorkFlowStates]    Script Date: 06/04/2014 12:52:50 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[WF_TMPWorkFlowStates](
	[ID] [uniqueidentifier] NOT NULL,
	[WorkFlowID] [uniqueidentifier] NOT NULL,
	[StateID] [uniqueidentifier] NOT NULL,
	[ResponseType] [varchar](20) NULL,
	[RefStateID] [uniqueidentifier] NULL,
	[NodeID] [uniqueidentifier] NULL,
	[Admin] [bit] NOT NULL,
	[Description] [nvarchar](2000) NULL,
	[DescriptionNeeded] [bit] NOT NULL,
	[HideOwnerName] [bit] NOT NULL,
	[EditPermission] [bit] NOT NULL,
	[DataNeedsType] [varchar](20) NULL,
	[RefDataNeedsStateID] [uniqueidentifier] NULL,
	[DataNeedsDescription] [nvarchar](2000) NULL,
	[FreeDataNeedRequests] [bit] NOT NULL,
	[TagID] [uniqueidentifier] NULL,
	[MaxAllowedRejections] [int] NULL,
	[RejectionTitle] [nvarchar](255) NULL,
	[RejectionRefStateID] [uniqueidentifier] NULL,
	[CreatorUserID] [uniqueidentifier] NULL,
	[CreationDate] [datetime] NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL
 CONSTRAINT [PK_WF_TMPWorkFlowStates] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


INSERT INTO [dbo].[WF_TMPWorkFlowStates](
	[ID], [WorkFlowID], [StateID], [ResponseType], [RefStateID], [NodeID], [Admin],
	[Description], [DescriptionNeeded], [HideOwnerName], [EditPermission], [DataNeedsType],
	[RefDataNeedsStateID], [DataNeedsDescription], [FreeDataNeedRequests], [TagID],
	[MaxAllowedRejections], [RejectionTitle], [RejectionRefStateID], [CreatorUserID],
	[CreationDate], [LastModifierUserID], [LastModificationDate], [Deleted]
)
SELECT NEWID(), WorkFlowID, StateID, ResponseType, RefStateID, NodeID, [Admin],
	[Description], DescriptionNeeded, 
	CASE WHEN ShowOwnerName = 1 THEN 0 ELSE 1 END, 0, DataNeedsType,
	RefDataNeedsStateID, DataNeedsDescription, FreeDataNeedRequests, TagID,
	MaxAllowedRejections, RejectionTitle, RejectionRefStateID, CreatorUserID,
	CreationDate, LastModifierUserID, LastModificationDate, Deleted
FROM [dbo].[WF_WorkFlowStates]

GO


INSERT INTO [dbo].[FG_FormOwners](
	OwnerID, FormID, CreatorUserID, CreationDate, 
	LastModifierUserID, LastModificationDate, Deleted
)
SELECT  T.ID, WS.FormID, T.CreatorUserID, T.CreationDate,
		T.LastModifierUserID, T.LastModificationDate, 0
FROM [dbo].[WF_WorkFlowStates] AS WS
	INNER JOIN [dbo].[WF_TMPWorkFlowStates] AS T
	ON WS.WorkFlowID = T.WorkFlowID AND WS.StateID = T.StateID
WHERE WS.FormID IS NOT NULL

GO


DROP TABLE [dbo].[WF_WorkFlowStates]
GO


CREATE TABLE [dbo].[WF_WorkFlowStates](
	[ID] [uniqueidentifier] NOT NULL,
	[WorkFlowID] [uniqueidentifier] NOT NULL,
	[StateID] [uniqueidentifier] NOT NULL,
	[ResponseType] [varchar](20) NULL,
	[RefStateID] [uniqueidentifier] NULL,
	[NodeID] [uniqueidentifier] NULL,
	[Admin] [bit] NOT NULL,
	[Description] [nvarchar](2000) NULL,
	[DescriptionNeeded] [bit] NOT NULL,
	[HideOwnerName] [bit] NOT NULL,
	[EditPermission] [bit] NOT NULL,
	[DataNeedsType] [varchar](20) NULL,
	[RefDataNeedsStateID] [uniqueidentifier] NULL,
	[DataNeedsDescription] [nvarchar](2000) NULL,
	[FreeDataNeedRequests] [bit] NOT NULL,
	[TagID] [uniqueidentifier] NULL,
	[MaxAllowedRejections] [int] NULL,
	[RejectionTitle] [nvarchar](255) NULL,
	[RejectionRefStateID] [uniqueidentifier] NULL,
	[CreatorUserID] [uniqueidentifier] NULL,
	[CreationDate] [datetime] NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL
 CONSTRAINT [PK_WF_WorkFlowStates] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


ALTER TABLE [dbo].[WF_WorkFlowStates] ADD  CONSTRAINT [UK_WF_WorkFlowStates] UNIQUE NONCLUSTERED 
(
	[WorkFlowID] ASC,
	[StateID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO


ALTER TABLE [dbo].[WF_WorkFlowStates]  WITH CHECK ADD  CONSTRAINT [FK_WF_WorkFlowStates_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[WF_WorkFlowStates] CHECK CONSTRAINT [FK_WF_WorkFlowStates_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[WF_WorkFlowStates]  WITH CHECK ADD  CONSTRAINT [FK_WF_WorkFlowStates_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[WF_WorkFlowStates] CHECK CONSTRAINT [FK_WF_WorkFlowStates_aspnet_Users_Modifier]
GO

ALTER TABLE [dbo].[WF_WorkFlowStates]  WITH CHECK ADD  CONSTRAINT [FK_WF_WorkFlowStates_CN_Nodes] FOREIGN KEY([NodeID])
REFERENCES [dbo].[CN_Nodes] ([NodeID])
GO

ALTER TABLE [dbo].[WF_WorkFlowStates] CHECK CONSTRAINT [FK_WF_WorkFlowStates_CN_Nodes]
GO

ALTER TABLE [dbo].[WF_WorkFlowStates]  WITH CHECK ADD  CONSTRAINT [FK_WF_WorkFlowStates_CN_Tags] FOREIGN KEY([TagID])
REFERENCES [dbo].[CN_Tags] ([TagID])
GO

ALTER TABLE [dbo].[WF_WorkFlowStates] CHECK CONSTRAINT [FK_WF_WorkFlowStates_CN_Tags]
GO

ALTER TABLE [dbo].[WF_WorkFlowStates]  WITH CHECK ADD  CONSTRAINT [FK_WF_WorkFlowStates_WF_States] FOREIGN KEY([StateID])
REFERENCES [dbo].[WF_States] ([StateID])
GO

ALTER TABLE [dbo].[WF_WorkFlowStates] CHECK CONSTRAINT [FK_WF_WorkFlowStates_WF_States]
GO

ALTER TABLE [dbo].[WF_WorkFlowStates]  WITH CHECK ADD  CONSTRAINT [FK_WF_WorkFlowStates_WF_States_DataNeeds] FOREIGN KEY([RefDataNeedsStateID])
REFERENCES [dbo].[WF_States] ([StateID])
GO

ALTER TABLE [dbo].[WF_WorkFlowStates] CHECK CONSTRAINT [FK_WF_WorkFlowStates_WF_States_DataNeeds]
GO

ALTER TABLE [dbo].[WF_WorkFlowStates]  WITH CHECK ADD  CONSTRAINT [FK_WF_WorkFlowStates_WF_States_Ref] FOREIGN KEY([RefStateID])
REFERENCES [dbo].[WF_States] ([StateID])
GO

ALTER TABLE [dbo].[WF_WorkFlowStates] CHECK CONSTRAINT [FK_WF_WorkFlowStates_WF_States_Ref]
GO

ALTER TABLE [dbo].[WF_WorkFlowStates]  WITH CHECK ADD  CONSTRAINT [FK_WF_WorkFlowStates_WF_States_Rejection] FOREIGN KEY([RejectionRefStateID])
REFERENCES [dbo].[WF_States] ([StateID])
GO

ALTER TABLE [dbo].[WF_WorkFlowStates] CHECK CONSTRAINT [FK_WF_WorkFlowStates_WF_States_Rejection]
GO

ALTER TABLE [dbo].[WF_WorkFlowStates]  WITH CHECK ADD  CONSTRAINT [FK_WF_WorkFlowStates_WF_WorkFlows_WorkFlow] FOREIGN KEY([WorkFlowID])
REFERENCES [dbo].[WF_WorkFlows] ([WorkFlowID])
GO

ALTER TABLE [dbo].[WF_WorkFlowStates] CHECK CONSTRAINT [FK_WF_WorkFlowStates_WF_WorkFlows_WorkFlow]
GO


INSERT INTO [dbo].[WF_WorkFlowStates]
SELECT *
FROM [dbo].[WF_TMPWorkFlowStates]
GO


DROP TABLE [dbo].[WF_TMPWorkFlowStates]
GO

/****** Object:  Table [dbo].[WF_WorkFlowStates]    Script Date: 06/04/2014 12:52:50 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[WF_TMPStateDataNeeds](
	[ID] [uniqueidentifier] NOT NULL,
	[WorkFlowID] [uniqueidentifier] NOT NULL,
	[StateID] [uniqueidentifier] NOT NULL,
	[NodeTypeID] [uniqueidentifier] NOT NULL,
	[Description] [nvarchar](2000) NULL,
	[MultipleSelect] [bit] NOT NULL,
	[Admin] [bit] NOT NULL,
	[Necessary] [bit] NOT NULL,
	[CreatorUserID] [uniqueidentifier] NULL,
	[CreationDate] [datetime] NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL
 CONSTRAINT [PK_WF_TMPStateDataNeeds] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


INSERT INTO [dbo].[WF_TMPStateDataNeeds](
	[ID], [WorkFlowID], [StateID], [NodeTypeID], [Description], [MultipleSelect],
	[Admin], [Necessary], [CreatorUserID], [CreationDate], [LastModifierUserID],
	[LastModificationDate], [Deleted]
)
SELECT NEWID(), WorkFlowID, StateID, NodeTypeID, [Description], [MultipleSelect], 
	[Admin], Necessary, CreatorUserID, CreationDate, LastModifierUserID, 
	LastModificationDate, Deleted
FROM [dbo].[WF_StateDataNeeds]

GO


INSERT INTO [dbo].[FG_FormOwners](
	OwnerID, FormID, CreatorUserID, CreationDate, 
	LastModifierUserID, LastModificationDate, Deleted
)
SELECT  T.ID, SD.FormID, T.CreatorUserID, T.CreationDate,
		T.LastModifierUserID, T.LastModificationDate, 0
FROM [dbo].[WF_StateDataNeeds] AS SD
	INNER JOIN [dbo].[WF_TMPStateDataNeeds] AS T
	ON SD.WorkFlowID = T.WorkFlowID AND SD.StateID = T.StateID AND SD.NodeTypeID = T.NodeTypeID
WHERE SD.FormID IS NOT NULL

GO


DROP TABLE [dbo].[WF_StateDataNeeds]
GO


CREATE TABLE [dbo].[WF_StateDataNeeds](
	[ID] [uniqueidentifier] NOT NULL,
	[WorkFlowID] [uniqueidentifier] NOT NULL,
	[StateID] [uniqueidentifier] NOT NULL,
	[NodeTypeID] [uniqueidentifier] NOT NULL,
	[Description] [nvarchar](2000) NULL,
	[MultipleSelect] [bit] NOT NULL,
	[Admin] [bit] NOT NULL,
	[Necessary] [bit] NOT NULL,
	[CreatorUserID] [uniqueidentifier] NULL,
	[CreationDate] [datetime] NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL
 CONSTRAINT [PK_WF_StateDataNeeds] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


ALTER TABLE [dbo].[WF_StateDataNeeds] ADD  CONSTRAINT [UK_WF_StateDataNeeds] UNIQUE NONCLUSTERED 
(
	[WorkFlowID] ASC,
	[StateID] ASC,
	[NodeTypeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO


ALTER TABLE [dbo].[WF_StateDataNeeds]  WITH CHECK ADD  CONSTRAINT [FK_WF_StateDataNeeds_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[WF_StateDataNeeds] CHECK CONSTRAINT [FK_WF_StateDataNeeds_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[WF_StateDataNeeds]  WITH CHECK ADD  CONSTRAINT [FK_WF_StateDataNeeds_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[WF_StateDataNeeds] CHECK CONSTRAINT [FK_WF_StateDataNeeds_aspnet_Users_Modifier]
GO

ALTER TABLE [dbo].[WF_StateDataNeeds]  WITH CHECK ADD  CONSTRAINT [FK_WF_StateDataNeeds_CN_NodeTypes] FOREIGN KEY([NodeTypeID])
REFERENCES [dbo].[CN_NodeTypes] ([NodeTypeID])
GO

ALTER TABLE [dbo].[WF_StateDataNeeds] CHECK CONSTRAINT [FK_WF_StateDataNeeds_CN_NodeTypes]
GO

ALTER TABLE [dbo].[WF_StateDataNeeds]  WITH CHECK ADD  CONSTRAINT [FK_WF_StateDataNeeds_WF_States] FOREIGN KEY([StateID])
REFERENCES [dbo].[WF_States] ([StateID])
GO

ALTER TABLE [dbo].[WF_StateDataNeeds] CHECK CONSTRAINT [FK_WF_StateDataNeeds_WF_States]
GO

ALTER TABLE [dbo].[WF_StateDataNeeds]  WITH CHECK ADD  CONSTRAINT [FK_WF_StateDataNeeds_WF_WorkFlows] FOREIGN KEY([WorkFlowID])
REFERENCES [dbo].[WF_WorkFlows] ([WorkFlowID])
GO

ALTER TABLE [dbo].[WF_StateDataNeeds] CHECK CONSTRAINT [FK_WF_StateDataNeeds_WF_WorkFlows]
GO


INSERT INTO [dbo].[WF_StateDataNeeds]
SELECT *
FROM [dbo].[WF_TMPStateDataNeeds]
GO


DROP TABLE [dbo].[WF_TMPStateDataNeeds]
GO


/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[CN_ContributionLimits](
	[NodeTypeID] [uniqueidentifier] NOT NULL,
	[LimitNodeTypeID] [uniqueidentifier] NOT NULL,
	[CreatorUserID] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL
 CONSTRAINT [PK_CN_ContributionLimits] PRIMARY KEY CLUSTERED 
(
	[NodeTypeID] ASC,
	[LimitNodeTypeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


ALTER TABLE [dbo].[CN_ContributionLimits]  WITH CHECK ADD  CONSTRAINT [FK_CN_ContributionLimits_CN_NodeTypes] FOREIGN KEY([NodeTypeID])
REFERENCES [dbo].[CN_NodeTypes] ([NodeTypeID])
GO

ALTER TABLE [dbo].[CN_ContributionLimits] CHECK CONSTRAINT [FK_CN_ContributionLimits_CN_NodeTypes]
GO

ALTER TABLE [dbo].[CN_ContributionLimits]  WITH CHECK ADD  CONSTRAINT [FK_CN_ContributionLimits_CN_NodeTypes_Limit] FOREIGN KEY([LimitNodeTypeID])
REFERENCES [dbo].[CN_NodeTypes] ([NodeTypeID])
GO

ALTER TABLE [dbo].[CN_ContributionLimits] CHECK CONSTRAINT [FK_CN_ContributionLimits_CN_NodeTypes_Limit]
GO

ALTER TABLE [dbo].[CN_ContributionLimits]  WITH CHECK ADD  CONSTRAINT [FK_CN_ContributionLimits_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[CN_ContributionLimits] CHECK CONSTRAINT [FK_CN_ContributionLimits_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[CN_ContributionLimits]  WITH CHECK ADD  CONSTRAINT [FK_CN_ContributionLimits_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[CN_ContributionLimits] CHECK CONSTRAINT [FK_CN_ContributionLimits_aspnet_Users_Modifier]
GO


/****** Object:  View [dbo].[CN_View_Nodes_Normal]    Script Date: 06/22/2012 13:03:22 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

DECLARE @UserID uniqueidentifier = (SELECT TOP(1) UserId FROM [dbo].[aspnet_Users] WHERE LoweredUserName = N'admin')

INSERT INTO [dbo].[CN_NodeTypes](
	NodeTypeID,
	AdditionalID,
	Name,
	CreatorUserID,
	CreationDate,
	Deleted
)
VALUES(
	NEWID(),
	7,
	N'تخصص',
	@UserID,
	GETDATE(),
	0
)

GO



/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[PRVC_ConfidentialityLevels](
	[ID] [uniqueidentifier] NOT NULL,
	[LevelID] [int] NOT NULL,
	[Title] [nvarchar](512) NOT NULL,
	[CreatorUserID] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL
 CONSTRAINT [PK_PRVC_ConfidentialityLevels] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


ALTER TABLE [dbo].[PRVC_ConfidentialityLevels]  WITH CHECK ADD  CONSTRAINT [FK_PRVC_ConfidentialityLevels_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[PRVC_ConfidentialityLevels] CHECK CONSTRAINT [FK_PRVC_ConfidentialityLevels_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[PRVC_ConfidentialityLevels]  WITH CHECK ADD  CONSTRAINT [FK_PRVC_ConfidentialityLevels_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[PRVC_ConfidentialityLevels] CHECK CONSTRAINT [FK_PRVC_ConfidentialityLevels_aspnet_Users_Modifier]
GO


/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[PRVC_Confidentialities](
	[LevelID] [uniqueidentifier] NOT NULL,
	[ItemID] [uniqueidentifier] NOT NULL,
	[CreatorUserID] [uniqueidentifier] NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL
 CONSTRAINT [PK_PRVC_Confidentialities] PRIMARY KEY CLUSTERED 
(
	[LevelID] ASC,
	[ItemID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


ALTER TABLE [dbo].[PRVC_Confidentialities]  WITH CHECK ADD  CONSTRAINT [FK_PRVC_Confidentialities_PRVC_ConfidentialityLevels] FOREIGN KEY([LevelID])
REFERENCES [dbo].[PRVC_ConfidentialityLevels] ([ID])
GO

ALTER TABLE [dbo].[PRVC_Confidentialities] CHECK CONSTRAINT [FK_PRVC_Confidentialities_PRVC_ConfidentialityLevels]
GO

ALTER TABLE [dbo].[PRVC_Confidentialities]  WITH CHECK ADD  CONSTRAINT [FK_PRVC_Confidentialities_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[PRVC_Confidentialities] CHECK CONSTRAINT [FK_PRVC_Confidentialities_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[PRVC_Confidentialities]  WITH CHECK ADD  CONSTRAINT [FK_PRVC_Confidentialities_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[PRVC_Confidentialities] CHECK CONSTRAINT [FK_PRVC_Confidentialities_aspnet_Users_Modifier]
GO



/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

DELETE [dbo].[PRVC_ConfidentialityLevels]
GO

DECLARE @UserID uniqueidentifier = (SELECT TOP(1) UserId FROM [dbo].[aspnet_Users]
	WHERE LoweredUserName = N'admin')

INSERT INTO [dbo].[PRVC_ConfidentialityLevels](ID, LevelID, Title, 
	CreatorUserID, CreationDate, Deleted)
SELECT NEWID(), LevelID, Title, @UserID, GETDATE(), 0
FROM [dbo].[KW_ConfidentialityLevels]

GO


DECLARE @UserID uniqueidentifier = (SELECT TOP(1) UserId FROM [dbo].[aspnet_Users]
	WHERE LoweredUserName = N'admin')

INSERT INTO [dbo].[PRVC_Confidentialities](LevelID, ItemID, CreatorUserID, CreationDate, Deleted)
SELECT L.ID, UserID, @UserID, GETDATE(), 0
FROM [dbo].[KW_UsersConfidentialityLevels] AS U
	INNER JOIN [dbo].[PRVC_ConfidentialityLevels] AS L
	ON U.LevelID = L.LevelID
	
INSERT INTO [dbo].[PRVC_Confidentialities](LevelID, ItemID, CreatorUserID, CreationDate, Deleted)
SELECT L.ID, KnowledgeID, @UserID, GETDATE(), 0
FROM [dbo].[KW_Knowledges] AS U
	INNER JOIN [dbo].[PRVC_ConfidentialityLevels] AS L
	ON U.ConfidentialityLevelID = L.LevelID

GO


/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER TABLE [dbo].[CN_Nodes]
DROP COLUMN [Status]
GO

IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_CN_Nodes_CN_Lists]') AND parent_object_id = OBJECT_ID(N'[dbo].[CN_Nodes]'))
ALTER TABLE [dbo].[CN_Nodes] DROP CONSTRAINT [FK_CN_Nodes_CN_Lists]
GO

ALTER TABLE [dbo].[CN_Nodes]
DROP COLUMN [DepartmentGroupID]
GO

ALTER TABLE [dbo].[CN_Nodes]
ADD [Searchable] [bit] NULL
GO

/****** Object:  Table [dbo].[TMP_CN_Lists]    Script Date: 02/10/2014 11:02:07 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO


IF EXISTS(select * FROM sys.views where name = 'CN_View_Lists')
DROP VIEW [dbo].[CN_View_Lists]
GO

IF EXISTS(select * FROM sys.views where name = 'CN_View_NodeMembers')
DROP VIEW [dbo].[CN_View_NodeMembers]
GO

IF EXISTS(select * FROM sys.views where name = 'CN_View_ListMembers')
DROP VIEW [dbo].[CN_View_ListMembers]
GO

IF EXISTS(select * FROM sys.views where name = 'CN_View_ListExperts')
DROP VIEW [dbo].[CN_View_ListExperts]
GO


CREATE TABLE [dbo].[TMP_CN_Lists](
	[ListID] [uniqueidentifier] NOT NULL,
	[NodeTypeID] [uniqueidentifier] NOT NULL,
	[AdditionalID] [nvarchar](50) NULL,
	[ParentListID] [uniqueidentifier] NULL,
	[Name] [nvarchar](255) NOT NULL,
	[Description] [nvarchar](2000) NULL,
	[OwnerID] [uniqueidentifier] NULL,
	[OwnerType] [varchar](20) NULL,
	[CreatorUserID] [uniqueidentifier] NULL,
	[CreationDate] [datetime] NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL
 CONSTRAINT [PK_TMP_CN_Lists] PRIMARY KEY CLUSTERED 
(
	[ListID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[TMP_CN_Lists]  WITH CHECK ADD  CONSTRAINT [FK_TMP_CN_Lists_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[TMP_CN_Lists] CHECK CONSTRAINT [FK_TMP_CN_Lists_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[TMP_CN_Lists]  WITH CHECK ADD  CONSTRAINT [FK_TMP_CN_Lists_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[TMP_CN_Lists] CHECK CONSTRAINT [FK_TMP_CN_Lists_aspnet_Users_Modifier]
GO

ALTER TABLE [dbo].[TMP_CN_Lists]  WITH CHECK ADD  CONSTRAINT [FK_TMP_CN_Lists_TMP_CN_Lists] FOREIGN KEY([ParentListID])
REFERENCES [dbo].[TMP_CN_Lists] ([ListID])
GO

ALTER TABLE [dbo].[TMP_CN_Lists] CHECK CONSTRAINT [FK_TMP_CN_Lists_TMP_CN_Lists]
GO

ALTER TABLE [dbo].[TMP_CN_Lists]  WITH CHECK ADD  CONSTRAINT [FK_TMP_CN_Lists_CN_NodeTypes] FOREIGN KEY([NodeTypeID])
REFERENCES [dbo].[CN_NodeTypes] ([NodeTypeID])
GO

ALTER TABLE [dbo].[TMP_CN_Lists] CHECK CONSTRAINT [FK_TMP_CN_Lists_CN_NodeTypes]
GO


DECLARE @DepTypeID uniqueidentifier = [dbo].[CN_FN_GetDepartmentNodeTypeID]()

INSERT INTO [dbo].[TMP_CN_Lists](
	[ListID],
	[NodeTypeID],
	[AdditionalID],
	[ParentListID],
	[Name],
	[Description],
	[OwnerID],
	[OwnerType],
	[CreatorUserID],
	[CreationDate],
	[LastModifierUserID],
	[LastModificationDate],
	[Deleted]
)
SELECT L.ListID, @DepTypeID, LT.AdditionalID, L.ParentListID,
	L.Name, LT.Name, L.OwnerID, L.OwnerType, L.CreatorUserID, L.CreationDate,
	L.LastModifierUserID, L.LastModificationDate, L.Deleted
FROM [dbo].[CN_Lists] AS L
	INNER JOIN [dbo].[CN_ListTypes] AS LT
	ON L.ListTypeID = LT.ListTypeID
	
GO


ALTER TABLE [dbo].[CN_ListNodes]
DROP CONSTRAINT [FK_CN_ListNodes_CN_Lists]
GO

ALTER TABLE [dbo].[CN_Lists]
DROP CONSTRAINT [FK_CN_Lists_CN_Lists]
GO

ALTER TABLE [dbo].[KW_KnowledgeManagers]
DROP CONSTRAINT [FK_KW_KnowledgeManagers_CN_Lists]
GO


DROP TABLE [dbo].[CN_Lists]
GO

DROP TABLE [dbo].[CN_ListTypes]
GO


CREATE TABLE [dbo].[CN_Lists](
	[ListID] [uniqueidentifier] NOT NULL,
	[NodeTypeID] [uniqueidentifier] NOT NULL,
	[AdditionalID] [nvarchar](50) NULL,
	[ParentListID] [uniqueidentifier] NULL,
	[Name] [nvarchar](255) NOT NULL,
	[Description] [nvarchar](2000) NULL,
	[OwnerID] [uniqueidentifier] NULL,
	[OwnerType] [varchar](20) NULL,
	[CreatorUserID] [uniqueidentifier] NULL,
	[CreationDate] [datetime] NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL
 CONSTRAINT [PK_CN_Lists] PRIMARY KEY CLUSTERED 
(
	[ListID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[CN_Lists]  WITH CHECK ADD  CONSTRAINT [FK_CN_Lists_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[CN_Lists] CHECK CONSTRAINT [FK_CN_Lists_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[CN_Lists]  WITH CHECK ADD  CONSTRAINT [FK_CN_Lists_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[CN_Lists] CHECK CONSTRAINT [FK_CN_Lists_aspnet_Users_Modifier]
GO

ALTER TABLE [dbo].[CN_Lists]  WITH CHECK ADD  CONSTRAINT [FK_CN_Lists_CN_Lists] FOREIGN KEY([ParentListID])
REFERENCES [dbo].[CN_Lists] ([ListID])
GO

ALTER TABLE [dbo].[CN_Lists] CHECK CONSTRAINT [FK_CN_Lists_CN_Lists]
GO

ALTER TABLE [dbo].[CN_Lists]  WITH CHECK ADD  CONSTRAINT [FK_CN_Lists_CN_NodeTypes] FOREIGN KEY([NodeTypeID])
REFERENCES [dbo].[CN_NodeTypes] ([NodeTypeID])
GO

ALTER TABLE [dbo].[CN_Lists] CHECK CONSTRAINT [FK_CN_Lists_CN_NodeTypes]
GO


INSERT INTO [dbo].[CN_Lists]
SELECT * 
FROM [dbo].[TMP_CN_Lists]

GO

DROP TABLE [dbo].[TMP_CN_Lists]
GO

ALTER TABLE [dbo].[CN_ListNodes]  WITH CHECK ADD  CONSTRAINT [FK_CN_ListNodes_CN_Lists] FOREIGN KEY([ListID])
REFERENCES [dbo].[CN_Lists] ([ListID])
GO

ALTER TABLE [dbo].[CN_ListNodes] CHECK CONSTRAINT [FK_CN_ListNodes_CN_Lists]
GO

/****** Object:  Table [dbo].[CN_Lists]    Script Date: 02/10/2014 11:02:07 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[CN_ListAdmins](
	[ListID] [uniqueidentifier] NOT NULL,
	[UserID] [uniqueidentifier] NOT NULL,
	[CreatorUserID] [uniqueidentifier] NULL,
	[CreationDate] [datetime] NULL,
	[LastModifierUserID] [uniqueidentifier] NULL,
	[LastModificationDate] [datetime] NULL,
	[Deleted] [bit] NOT NULL
 CONSTRAINT [PK_CN_ListAdmins] PRIMARY KEY CLUSTERED 
(
	[ListID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[CN_ListAdmins]  WITH CHECK ADD  CONSTRAINT [FK_CN_ListAdmins_CN_Lists] FOREIGN KEY([ListID])
REFERENCES [dbo].[CN_Lists] ([ListID])
GO

ALTER TABLE [dbo].[CN_ListAdmins] CHECK CONSTRAINT [FK_CN_ListAdmins_CN_Lists]
GO

ALTER TABLE [dbo].[CN_ListAdmins]  WITH CHECK ADD  CONSTRAINT [FK_CN_ListAdmins_aspnet_Users] FOREIGN KEY([UserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[CN_ListAdmins] CHECK CONSTRAINT [FK_CN_ListAdmins_aspnet_Users]
GO

ALTER TABLE [dbo].[CN_ListAdmins]  WITH CHECK ADD  CONSTRAINT [FK_CN_ListAdmins_aspnet_Users_Creator] FOREIGN KEY([CreatorUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[CN_ListAdmins] CHECK CONSTRAINT [FK_CN_ListAdmins_aspnet_Users_Creator]
GO

ALTER TABLE [dbo].[CN_ListAdmins]  WITH CHECK ADD  CONSTRAINT [FK_CN_ListAdmins_aspnet_Users_Modifier] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[CN_ListAdmins] CHECK CONSTRAINT [FK_CN_ListAdmins_aspnet_Users_Modifier]
GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_InitializeService]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_InitializeService]
GO

CREATE PROCEDURE [dbo].[CN_InitializeService]
	@NodeTypeID		uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(SELECT TOP(1) * FROM [dbo].[CN_Services] WHERE NodeTypeID = @NodeTypeID) BEGIN
		UPDATE [dbo].[CN_Services]
			SET Deleted = 0
		WHERE NodeTypeID = @NodeTypeID
	END
	ELSE BEGIN
		DECLARE @SeqNo int = 
			ISNULL((SELECT MAX(SequenceNumber) FROM [dbo].[CN_Services]), 0) + 1
		
		INSERT INTO [dbo].[CN_Services](
			NodeTypeID,
			EnableContribution,
			EditableForAdmin,
			SequenceNumber,
			EditableForCreator,
			EditableForOwners,
			EditableForExperts,
			EditableForMembers,
			Deleted
		)
		VALUES(
			@NodeTypeID,
			0,
			1,
			@SeqNo,
			1,
			1,
			1,
			0,
			0
		)
	END
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_SetServiceTitle]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_SetServiceTitle]
GO

CREATE PROCEDURE [dbo].[CN_SetServiceTitle]
	@NodeTypeID		uniqueidentifier,
	@Title			nvarchar(512)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[CN_Services]
		SET ServiceTitle = [dbo].[GFN_VerifyString](@Title)
	WHERE NodeTypeID = @NodeTypeID
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[FG_SetFormOwner]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[FG_SetFormOwner]
GO

CREATE PROCEDURE [dbo].[FG_SetFormOwner]
	@OwnerID		uniqueidentifier,
	@FormID			uniqueidentifier,
	@CreatorUserID	uniqueidentifier,
	@CreationDate	datetime
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(SELECT TOP(1) * FROM [dbo].[FG_FormOwners]
		WHERE OwnerID = @OwnerID) BEGIN
		UPDATE [dbo].[FG_FormOwners]
			SET FormID = @FormID,
				Deleted = 0,
				LastModifierUserID = @CreatorUserID,
				LastModificationDate = @CreationDate
		WHERE OwnerID = @OwnerID
	END
	ELSE BEGIN
		INSERT INTO [dbo].[FG_FormOwners](
			OwnerID,
			FormID,
			CreatorUserID,
			CreationDate,
			Deleted
		)
		VALUES(
			@OwnerID,
			@FormID,
			@CreatorUserID,
			@CreationDate,
			0
		)
	END
	
	SELECT @@ROWCOUNT
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_SetServiceDescription]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_SetServiceDescription]
GO

CREATE PROCEDURE [dbo].[CN_SetServiceDescription]
	@NodeTypeID		uniqueidentifier,
	@Description	nvarchar(4000)
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	UPDATE [dbo].[CN_Services]
		SET ServiceDescription = [dbo].[GFN_VerifyString](@Description)
	WHERE NodeTypeID = @NodeTypeID
	
	SELECT @@ROWCOUNT
END

GO




DECLARE @UserID uniqueidentifier = (SELECT UserId FROM [dbo].[aspnet_Users] WHERE LoweredUserName = N'admin')

DECLARE @NodeTypeIDs Table (ID int identity(1,1) primary key clustered, 
	NodeTypeID uniqueidentifier)
INSERT INTO @NodeTypeIDs (NodeTypeID)
SELECT DISTINCT NodeTypeID
FROM [dbo].[WF_Services]
WHERE Deleted = 0

DECLARE @Count int = (SELECT COUNT(*) FROM @NodeTypeIDs)

WHILE @Count > 0 BEGIN
	DECLARE @NTID uniqueidentifier = (SELECT NodeTypeID FROM @NodeTypeIDs WHERE ID = @Count)
	DECLARE @Title nvarchar(2000), @Description nvarchar(2000), @FormID uniqueidentifier,
		@Now datetime = GETDATE()
	
	SELECT TOP(1) @Title = Title, @Description  = [Description], @FormID = FormID
	FROM [dbo].[WF_Services]
	WHERE NodeTypeID = @NTID
	
	EXEC [dbo].[CN_InitializeService] @NTID
	
	EXEC [dbo].[CN_SetServiceTitle] @NTID, @Title
	
	EXEC [dbo].[CN_SetServiceDescription] @NTID, @Description
	
	IF @FormID IS NOT NULL EXEC [dbo].[FG_SetFormOwner] @NTID, @FormID, @UserID, @Now
	
	SET @Count = @Count - 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_InitializeService]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_InitializeService]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_SetServiceTitle]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_SetServiceTitle]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[FG_SetFormOwner]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[FG_SetFormOwner]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[CN_SetServiceDescription]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[CN_SetServiceDescription]
GO


DROP TABLE [dbo].[WF_Services]
GO



SET NUMERIC_ROUNDABORT OFF;
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT,
    QUOTED_IDENTIFIER, ANSI_NULLS ON;


IF EXISTS(select * FROM sys.views where name = 'Users_Normal')
DROP VIEW [dbo].[Users_Normal]
GO


CREATE VIEW [dbo].[Users_Normal] WITH SCHEMABINDING, ENCRYPTION
AS
SELECT  U.UserId AS UserID, 
		U.UserName AS UserName, 
		P.FirstName AS FirstName, 
		P.LastName AS LastName, 
		P.BirthDay AS BirthDay,
		P.JobTitle AS JobTitle,
		P.EmploymentType AS EmploymentType,
		P.MainPhoneID AS MainPhoneID,
		P.MainEmailID AS MainEmailID,
		M.IsApproved AS IsApproved,
		M.IsLockedOut AS IsLockedOut,
		M.CreateDate AS CreationDate,
		P.IndexLastUpdateDate AS IndexLastUpdateDate
FROM    [dbo].[aspnet_Users] AS U
		INNER JOIN [dbo].[USR_Profile] AS P
		ON U.UserId = P.UserID 
		INNER JOIN [dbo].[aspnet_Membership] AS M
		ON U.UserId = M.UserId

GO

CREATE UNIQUE CLUSTERED INDEX PK_View_Users_Normal_UserID ON [dbo].[Users_Normal]
(
	[UserID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO



/****** Object:  View [dbo].[CN_View_Nodes_Normal]    Script Date: 06/22/2012 13:03:22 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS(select * FROM sys.views where name = 'WF_View_CurrentStates')
DROP VIEW [dbo].[WF_View_CurrentStates]
GO

IF EXISTS(select * FROM sys.views where name = 'CN_View_Nodes_Normal')
DROP VIEW [dbo].[CN_View_Nodes_Normal]
GO


CREATE VIEW [dbo].[CN_View_Nodes_Normal] WITH SCHEMABINDING, ENCRYPTION
AS
SELECT  ND.NodeID, 
		ND.Name AS NodeName, 
		ND.[Description],
		ND.AdditionalID AS NodeAdditionalID, 
		ND.NodeTypeID,
		NT.Name AS TypeName, 
		NT.AdditionalID AS TypeAdditionalID, 
        ND.ParentNodeID, 
        ND.Deleted, 
        NT.Deleted AS TypeDeleted,
        ND.Tags AS Tags, 
        ND.CreationDate AS CreationDate,
        ND.CreatorUserID AS CreatorUserID,
        ND.OwnerID AS OwnerID,
        ND.IndexLastUpdateDate
FROM [dbo].[CN_Nodes] AS ND
	INNER JOIN [dbo].[CN_NodeTypes] AS NT
	ON ND.NodeTypeID = NT.NodeTypeID

GO

CREATE UNIQUE CLUSTERED INDEX PX_CN_View_Nodes_Normal ON [dbo].[CN_View_Nodes_Normal]
(
	[NodeID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO




IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[TMP_SetWikiDashboards]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[TMP_SetWikiDashboards]
GO

CREATE PROCEDURE [dbo].[TMP_SetWikiDashboards]
	@UserID uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @OwnerIDs GuidTableType
	
	INSERT INTO @OwnerIDs
	SELECT EX.[NodeID] AS ID
	FROM [dbo].[CN_Experts] AS EX
		INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
		ON EX.[NodeID] = ND.[NodeID] 
	WHERE EX.UserID = @UserID AND (EX.Approved = 1 OR EX.SocialApproved = 1) AND ND.[Deleted] = 0
	
	DECLARE @Now datetime = GETDATE()
	
	INSERT INTO [dbo].[NTFN_Dashboards](
		UserID,
		NodeID,
		RefItemID,
		[Type],
		Removable,
		SendDate,
		Seen,
		Done,
		Deleted
	)
	SELECT	@UserID,
			Ref.Value,
			Ref.Value,
			N'Wiki',
			1,
			MAX(CH.SendDate),
			0,
			0,
			0
	FROM @OwnerIDs AS Ref
		INNER JOIN [dbo].[WK_Titles] AS TT
		ON Ref.Value = TT.OwnerID
		INNER JOIN [dbo].[WK_Paragraphs] AS PG
		ON TT.TitleID = PG.TitleID
		INNER JOIN [dbo].[WK_Changes] AS CH
		ON PG.ParagraphID = CH.ParagraphID
	WHERE TT.Deleted = 0 AND PG.Deleted = 0 AND CH.[Status] = N'Pending' AND CH.Deleted = 0
	GROUP BY Ref.Value
END

GO


DECLARE @UserIDs TABLE (ID int identity(1,1) primary key clustered, UserID uniqueidentifier)
INSERT INTO @UserIDs (UserID)
SELECT UserID 
FROM [dbo].[Users_Normal]

DECLARE @Count int  = (SELECT COUNT(*) FROM @UserIDs)

WHILE @Count > 0 BEGIN
	DECLARE @CurID uniqueidentifier = (SELECT UserID FROM @UserIDs WHERE ID = @Count)
	
	EXEC [dbo].[TMP_SetWikiDashboards] @CurID
	
	SET @Count = @Count - 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[TMP_SetWikiDashboards]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[TMP_SetWikiDashboards]
GO

IF EXISTS(select * FROM sys.views where name = 'Users_Normal')
DROP VIEW [dbo].[Users_Normal]
GO



IF  EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[GFN_Base64Encode]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[GFN_Base64Encode]
GO

CREATE FUNCTION [dbo].[GFN_Base64Encode]
(
	@input	nvarchar(max)
)
RETURNS nvarchar(max)
WITH ENCRYPTION
AS
BEGIN
	IF @input IS NULL OR @input = N'' RETURN @input

	DECLARE @binaryText varbinary(max) = CONVERT(varbinary(max), @input)
	
	RETURN CAST('' AS xml).value('xs:base64Binary(sql:variable("@binaryText"))', 'nvarchar(max)')
END

GO


IF  EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[GFN_Base64Decode]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[GFN_Base64Decode]
GO

CREATE FUNCTION [dbo].[GFN_Base64Decode]
(
	@input	nvarchar(max)
)
RETURNS nvarchar(max)
WITH ENCRYPTION
AS
BEGIN
	IF @input IS NULL OR @input = N'' RETURN @input

	DECLARE @binaryText varbinary(max) = 
		CAST('' AS xml).value('xs:base64Binary(sql:variable("@input"))', 'varbinary(max)')
	
	RETURN CONVERT(nvarchar(max), @binaryText)
END

GO



/****** Object:  View [dbo].[Users_Normal]    Script Date: 05/31/2012 21:31:04 ******/
SET NUMERIC_ROUNDABORT OFF;
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT,
    QUOTED_IDENTIFIER, ANSI_NULLS ON;


IF EXISTS(select * FROM sys.views where name = 'Users_Normal')
DROP VIEW [dbo].[Users_Normal]
GO


CREATE VIEW [dbo].[Users_Normal] WITH SCHEMABINDING, ENCRYPTION
AS
SELECT  U.UserId AS UserID, 
		U.UserName AS UserName, 
		P.FirstName AS FirstName, 
		P.LastName AS LastName, 
		P.BirthDay AS BirthDay,
		P.JobTitle AS JobTitle,
		P.EmploymentType AS EmploymentType,
		P.MainPhoneID AS MainPhoneID,
		P.MainEmailID AS MainEmailID,
		M.IsApproved AS IsApproved,
		M.IsLockedOut AS IsLockedOut,
		M.CreateDate AS CreationDate,
		P.IndexLastUpdateDate AS IndexLastUpdateDate
FROM    [dbo].[aspnet_Users] AS U
		INNER JOIN [dbo].[USR_Profile] AS P
		ON U.UserId = P.UserID 
		INNER JOIN [dbo].[aspnet_Membership] AS M
		ON U.UserId = M.UserId

GO

CREATE UNIQUE CLUSTERED INDEX PK_View_Users_Normal_UserID ON [dbo].[Users_Normal]
(
	[UserID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[TMP_SetWFDashboards]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[TMP_SetWFDashboards]
GO

CREATE PROCEDURE [dbo].[TMP_SetWFDashboards]
	@UserID uniqueidentifier
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @WFDash Table(NodeID uniqueidentifier, HistoryID uniqueidentifier,
		DataNeedInstanceID uniqueidentifier, CreationDate datetime, 
		Removable bit, Info nvarchar(max), StateID uniqueidentifier,
		[StateTitle] nvarchar(1000), WorkFlowID uniqueidentifier, 
		WorkFlowName nvarchar(max))
	
	DECLARE @CreatedNodeIDs GuidTableType
	INSERT INTO @CreatedNodeIDs
	SELECT Ref.ID
	FROM (
			SELECT NodeID AS ID
			FROM [dbo].[CN_Nodes]
			WHERE CreatorUserID = @UserID AND Deleted = 0
			
			UNION ALL
			
			SELECT NC.NodeID
			FROM [dbo].[CN_NodeCreators] AS NC
				INNER JOIN [dbo].[CN_Nodes] AS ND
				ON NC.NodeID = ND.NodeID
			WHERE NC.UserID = @UserID AND NC.Deleted = 0 AND 
				ND.CreatorUserID <> @UserID AND ND.Deleted = 0
		) AS Ref
	
	
	INSERT INTO @WFDash(NodeID, HistoryID, DataNeedInstanceID, CreationDate, 
		Removable, StateID, StateTitle, WorkFlowID, WorkFlowName
	)
	SELECT Ref.NodeID, Ref.HistoryID, Ref.InstanceID, Ref.CreationDate, Ref.Removable,
		Ref.StateID, Ref.StateTitle, Ref.WorkFlowID, Ref.WorkFlowName
	FROM (
		SELECT A.OwnerID AS NodeID,
			   A.HistoryID,
			   NULL AS InstanceID,
			   A.SendDate AS CreationDate,
			   CASE
					WHEN W.[Admin] = 1 AND N.IsAdmin = 0 THEN CAST(1 AS bit)
					ELSE CAST(0 AS bit)
			   END AS Removable,
			   ST.StateID,
			   ST.Title AS StateTitle,
			   WF.WorkFlowID,
			   WF.Name AS WorkFlowName
		FROM [dbo].[WF_History] AS A
			INNER JOIN
			(SELECT OwnerID, MAX(SendDate) AS SendDate
			 FROM [dbo].[WF_History]
			 GROUP BY OwnerID) AS B
			ON A.OwnerID = B.OwnerID AND A.SendDate = B.SendDate
			INNER JOIN [dbo].[WF_WorkFlowStates] AS W
			ON W.StateID = A.StateID
			INNER JOIN [dbo].[CN_NodeMembers] AS N
			ON N.UserID = @UserID AND N.NodeID = A.DirectorNodeID
			INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
			ON A.OwnerID = ND.NodeID
			LEFT JOIN [dbo].[WF_States] AS ST
			ON A.StateID = ST.StateID
			INNER JOIN [dbo].[WF_WorkFlows] AS WF
			ON A.WorkFlowID = WF.WorkFlowID
		WHERE A.DirectorUserID IS NULL AND N.[Status] = 'Accepted' AND 
			--(W.IsAdmin = 0 OR N.IsAdmin = w.IsAdmin) AND 
			N.Deleted = 0 AND A.Terminated = 0 AND A.Deleted = 0 AND ND.Deleted = 0
			
		UNION ALL
		
		SELECT A.OwnerID AS NodeID,
			   A.HistoryID,
			   NULL AS InstanceID,
			   A.SendDate AS CreationDate,
			   CAST(0 AS bit) AS Removable,
			   ST.StateID,
			   ST.Title AS StateTitle,
			   WF.WorkFlowID,
			   WF.Name
		FROM [dbo].[WF_History] AS A
			INNER JOIN
			(SELECT OwnerID, MAX(SendDate) AS SendDate
			 FROM [dbo].[WF_History]
			 GROUP BY OwnerID) AS B
			ON A.OwnerID = B.OwnerID AND A.SendDate = B.SendDate
			INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
			ON A.OwnerID = ND.NodeID
			LEFT JOIN [dbo].[WF_States] AS ST
			ON A.StateID = ST.StateID
			INNER JOIN [dbo].[WF_WorkFlows] AS WF
			ON A.WorkFlowID = WF.WorkFlowID
		--WHERE A.DirectorUserID = @UserID AND 
		WHERE A.DirectorUserID IS NOT NULL AND 
			A.OwnerID IN(SELECT * FROM @CreatedNodeIDs) AND 
			A.Terminated = 0 AND A.Deleted = 0 AND ND.Deleted = 0
			
		UNION ALL
		
		SELECT HS.OwnerID AS NodeID,
			   NULL AS HistoryID,
			   SDNI.InstanceID AS InstanceID,
			   SDNI.CreationDate AS CreationDate,
			   CAST(1 AS bit)  AS Removable,
			   ST.StateID,
			   ST.Title AS StateTitle,
			   WF.WorkFlowID,
			   WF.Name
		FROM [dbo].[WF_StateDataNeedInstances] AS SDNI
			INNER JOIN [dbo].[CN_NodeMembers] AS NM
			ON NM.UserID = @UserID AND NM.NodeID = SDNI.NodeID
			INNER JOIN [dbo].[WF_History] AS HS
			ON SDNI.HistoryID = HS.HistoryID
			INNER JOIN [dbo].[CN_View_Nodes_Normal] AS ND
			ON HS.OwnerID = ND.NodeID
			LEFT JOIN [dbo].[WF_States] AS ST
			ON HS.StateID = ST.StateID
			INNER JOIN [dbo].[WF_WorkFlows] AS WF
			ON HS.WorkFlowID = WF.WorkFlowID
		WHERE NM.[Status] = 'Accepted' AND 
			(SDNI.[Admin] = 0 OR NM.IsAdmin = SDNI.[Admin]) AND
			SDNI.Filled = 0 AND NM.Deleted = 0 AND SDNI.Deleted = 0 AND ND.Deleted = 0
	) AS Ref
	
	
	UPDATE Ref
		SET Info = '{"WorkFlowName":"' + ISNULL([dbo].[GFN_Base64encode](Ref.WorkFlowName), N'') + 
			'","WorkFlowState":"' + ISNULL([dbo].[GFN_Base64encode](Ref.StateTitle), N'') +
			(
				CASE
					WHEN Ref.DataNeedInstanceID IS NULL THEN N''
					ELSE '","DataNeedInstanceID":"' + CAST(Ref.DataNeedInstanceID AS varchar(50))
				END
			) +
			'"}'
	FROM @WFDash AS Ref
	
	
	INSERT INTO [dbo].[NTFN_Dashboards](
		UserID,
		NodeID,
		RefItemID,
		[Type],
		Info,
		Removable,
		SendDate,
		Seen,
		Done,
		Deleted
	)
	SELECT @UserID, Ref.NodeID, ISNULL(Ref.DataNeedInstanceID, Ref.HistoryID), N'WorkFlow', 
		Ref.Info, Ref.Removable, Ref.CreationDate, 0, 0, 0
	FROM @WFDash AS Ref
	ORDER BY Ref.CreationDate
END

GO


DECLARE @UserIDs TABLE (ID int identity(1,1) primary key clustered, UserID uniqueidentifier)
INSERT INTO @UserIDs (UserID)
SELECT UserID 
FROM [dbo].[Users_Normal]

DECLARE @Count int  = (SELECT COUNT(*) FROM @UserIDs)

WHILE @Count > 0 BEGIN
	DECLARE @CurID uniqueidentifier = (SELECT UserID FROM @UserIDs WHERE ID = @Count)
	
	EXEC [dbo].[TMP_SetWFDashboards] @CurID
	
	SET @Count = @Count - 1
END

GO


IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[TMP_SetWFDashboards]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[TMP_SetWFDashboards]
GO

IF EXISTS(select * FROM sys.views where name = 'Users_Normal')
DROP VIEW [dbo].[Users_Normal]
GO


IF  EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[GFN_Base64Encode]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[GFN_Base64Encode]
GO

IF  EXISTS (SELECT * FROM sys.objects 
            WHERE object_id = OBJECT_ID(N'[dbo].[GFN_Base64Decode]') 
            AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[GFN_Base64Decode]
GO


/****** Object:  Table [dbo].[Phrases]    Script Date: 04/26/2013 20:38:36 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER TABLE [dbo].[WF_History]
ADD [PreviousHistoryID] uniqueidentifier NULL,
	[ActorUserID] uniqueidentifier NULL
GO


DECLARE @HIDs Table (ID int IDENTITY(1,1) primary key clustered, HistoryID uniqueidentifier,
	WorkFlowID uniqueidentifier, OwnerID uniqueidentifier, SenderUserID uniqueidentifier)

INSERT INTO @HIDs(HistoryID, WorkFlowID, OwnerID, SenderUserID)
SELECT H.HistoryID, H.WorkFlowID, H.OwnerID, H.SenderUserID
FROM [dbo].[WF_History] AS H
ORDER BY H.SendDate ASC

DECLARE @Count int = (SELECT COUNT(*) FROM @HIDs)

WHILE @Count > 0 BEGIN
	DECLARE @HistoryID uniqueidentifier
	DECLARE @WorkFlowID uniqueidentifier
	DECLARE @OwnerID uniqueidentifier
	DECLARE @SenderUserID uniqueidentifier
	
	DECLARE @PrevHistoryID uniqueidentifier
	DECLARE @PrevWorkFlowID uniqueidentifier
	DECLARE @PrevOwnerID uniqueidentifier
	DECLARE @PrevSenderUserID uniqueidentifier
	
	SET @HistoryID = NULL
	SET @WorkFlowID = NULL
	SET @OwnerID = NULL
	SET @SenderUserID = NULL
	
	SET @PrevHistoryID = NULL
	SET @PrevWorkFlowID = NULL
	SET @PrevOwnerID = NULL
	SET @PrevSenderUserID = NULL
	
	SELECT TOP(1)
			@HistoryID = Ref.HistoryID,
			@WorkFlowID = Ref.WorkFlowID,
			@OwnerID = Ref.OwnerID,
			@SenderUserID = Ref.SenderUserID
	FROM @HIDs AS Ref
	WHERE ID = @Count
	
	SELECT TOP(1)
			@PrevHistoryID = Ref.HistoryID,
			@PrevWorkFlowID = Ref.WorkFlowID,
			@PrevOwnerID = Ref.OwnerID,
			@PrevSenderUserID = Ref.SenderUserID
	FROM @HIDs AS Ref
	WHERE ID < @Count AND Ref.WorkFlowID = @WorkFlowID AND Ref.OwnerID = @OwnerID
	ORDER BY Ref.ID DESC
	
	IF @PrevHistoryID IS NOT NULL AND @PrevSenderUserID IS NOT NULL BEGIN
		UPDATE [dbo].[WF_History]
			SET ActorUserID = @SenderUserID
		WHERE HistoryID = @PrevHistoryID
		
		UPDATE [dbo].[WF_History]
			SET PreviousHistoryID = @PrevHistoryID
		WHERE HistoryID = @HistoryID
	END

	SET @Count = @Count - 1
END

GO


/****** Object:  Table [dbo].[KKnowledges]    Script Date: 04/04/2012 12:34:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



UPDATE [dbo].[AppSetting]
	SET [Version] = 'v24.0.0.0' -- 13930317
GO

