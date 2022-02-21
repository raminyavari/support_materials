USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[WK_Blocks](
	[BlockID] [uniqueidentifier] NOT NULL,
	[OwnerID] [uniqueidentifier] NOT NULL,
	[Key] [varchar](20) NOT NULL,
	[Type] [varchar](20) NOT NULL,
	[Body] [nvarchar](max) NULL,
	[ApplicationID] [uniqueidentifier] NOT NULL
 CONSTRAINT [PK_WK_Blocks] PRIMARY KEY CLUSTERED 
(
	[BlockID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UK_WK_Blocks] UNIQUE NONCLUSTERED 
(
	[OwnerID] ASC,
	[BlockID] ASC,
	[Key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


ALTER TABLE [dbo].[WK_Blocks]  WITH CHECK ADD  CONSTRAINT [FK_WK_Blocks_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[WK_Blocks] CHECK CONSTRAINT [FK_WK_Blocks_aspnet_Applications]
GO



