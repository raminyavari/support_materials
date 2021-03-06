USE [EKM_App]
GO

/****** Object:  Table [dbo].[RV_DeletedStates]    Script Date: 08/02/2015 10:49:52 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[RV_ID2Guid](
	[ID] [varchar](100) NOT NULL,
	[Type] [varchar](100) NOT NULL,
	[Guid] [uniqueidentifier] NOT NULL
 CONSTRAINT [PK_RV_ID2Guid] PRIMARY KEY CLUSTERED 
(
	[ID] ASC,
	[Type] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO
