USE [EKM_App]
GO

/****** Object:  Table [dbo].[RV_DeletedStates]    Script Date: 08/02/2015 10:49:52 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[RV_DeletedStates](
	[ID] [bigint] IDENTITY(1, 1) NOT NULL,
	[ObjectID] [uniqueidentifier] NOT NULL,
	[ObjectType] [varchar](50),
	[Deleted] [bit] NOT NULL,
	[Date] [datetime] NULL
 CONSTRAINT [PK_RV_DeletedStates] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


CREATE UNIQUE INDEX UX_RV_DeletedStates_ObjectID ON [dbo].[RV_DeletedStates]
(
	[ObjectID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO