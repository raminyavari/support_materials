USE [EKM_App]
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[NTFN_P_SendDashboards]') and 
	OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[NTFN_P_SendDashboards]
GO

IF EXISTS (SELECT * FROM sys.types WHERE is_table_type = 1 AND name = 'DashboardTableType')
DROP TYPE dbo.DashboardTableType
GO