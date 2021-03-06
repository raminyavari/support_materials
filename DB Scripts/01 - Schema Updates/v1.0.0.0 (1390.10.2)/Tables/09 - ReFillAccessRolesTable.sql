USE [EKM_App]
GO

/****** Object:  Table [dbo].[KKnowledges]    Script Date: 04/04/2012 12:34:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



DELETE FROM [dbo].[AccessRoles]
GO


INSERT INTO [dbo].[AccessRoles]
           ([ID]
           ,[Role]
           ,[Title])
     VALUES
           (NEWID()
           ,N'ManagementSystem'
           ,N'مدیریت سیستم')
GO

INSERT INTO [dbo].[AccessRoles]
           ([ID]
           ,[Role]
           ,[Title])
     VALUES
           (NEWID()
           ,N'AssignUsersToClassifications'
           ,N'تخصیص کاربران به سطوح محرمانگی')
GO

INSERT INTO [dbo].[AccessRoles]
           ([ID]
           ,[Role]
           ,[Title])
     VALUES
           (NEWID()
           ,N'AssignUsersToDepartments'
           ,N'تخصیص کاربران به ساختار سازمانی')
GO

INSERT INTO [dbo].[AccessRoles]
           ([ID]
           ,[Role]
           ,[Title])
     VALUES
           (NEWID()
           ,N'AssignUsersToProcesses'
           ,N'تعیین اعضای فرآیندها')
GO

INSERT INTO [dbo].[AccessRoles]
           ([ID]
           ,[Role]
           ,[Title])
     VALUES
           (NEWID()
           ,N'AssignUsersToProjects'
           ,N'تعیین اعضای پروژه ها')
GO

INSERT INTO [dbo].[AccessRoles]
           ([ID]
           ,[Role]
           ,[Title])
     VALUES
           (NEWID()
           ,N'ContentsManagement'
           ,N'مدیریت مستندات')
GO

INSERT INTO [dbo].[AccessRoles]
           ([ID]
           ,[Role]
           ,[Title])
     VALUES
           (NEWID()
           ,N'DepartmentsManipulation'
           ,N'مدیریت ساختار سازمانی')
GO

INSERT INTO [dbo].[AccessRoles]
           ([ID]
           ,[Role]
           ,[Title])
     VALUES
           (NEWID()
           ,N'KDsManagement'
           ,N'مدیریت حوزه های دانش')
GO

INSERT INTO [dbo].[AccessRoles]
           ([ID]
           ,[Role]
           ,[Title])
     VALUES
           (NEWID()
           ,N'Navigation'
           ,N'ناوبری جامع نقشه دانش')
GO
           
INSERT INTO [dbo].[AccessRoles]
           ([ID]
           ,[Role]
           ,[Title])
     VALUES
           (NEWID()
           ,N'NodeScan'
           ,N'عیب یابی نقشه دانش')
GO

INSERT INTO [dbo].[AccessRoles]
           ([ID]
           ,[Role]
           ,[Title])
     VALUES
           (NEWID()
           ,N'OrganizationalProperties'
           ,N'تعیین معیارهای کلی سازمان')
GO

INSERT INTO [dbo].[AccessRoles]
           ([ID]
           ,[Role]
           ,[Title])
     VALUES
           (NEWID()
           ,N'ProjectsManagement'
           ,N'مدیریت پروژه ها')
GO

INSERT INTO [dbo].[AccessRoles]
           ([ID]
           ,[Role]
           ,[Title])
     VALUES
           (NEWID()
           ,N'OrganMetrics'
           ,N'تعیین معیارهای کلی سازمان')
GO

INSERT INTO [dbo].[AccessRoles]
           ([ID]
           ,[Role]
           ,[Title])
     VALUES
           (NEWID()
           ,N'Reports'
           ,N'گزارشات')
GO

INSERT INTO [dbo].[AccessRoles]
           ([ID]
           ,[Role]
           ,[Title])
     VALUES
           (NEWID()
           ,N'UserGroupsManagement'
           ,N'مدیریت گروه های کاربری')
GO

INSERT INTO [dbo].[AccessRoles]
           ([ID]
           ,[Role]
           ,[Title])
     VALUES
           (NEWID()
           ,N'UsersManagement'
           ,N'مدیریت ایجاد و تغییر کاربران')
GO

INSERT INTO [dbo].[AccessRoles]
           ([ID]
           ,[Role]
           ,[Title])
     VALUES
           (NEWID()
           ,N'ManageDepartmentGroups'
           ,N'مدیریت گروه های سازمانی')
GO

INSERT INTO [dbo].[AccessRoles]
           ([ID]
           ,[Role]
           ,[Title])
     VALUES
           (NEWID()
           ,N'ProcessesManagement'
           ,N'مدیریت فرآیندها')
GO

INSERT INTO [dbo].[AccessRoles]
           ([ID]
           ,[Role]
           ,[Title])
     VALUES
           (NEWID()
           ,N'VisualKMap'
           ,N'مشاهده گراف دانش')
GO