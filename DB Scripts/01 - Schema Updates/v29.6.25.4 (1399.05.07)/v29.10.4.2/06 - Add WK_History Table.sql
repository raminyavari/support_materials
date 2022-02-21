USE [EKM_App]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TABLE [dbo].[WK_History](
	[ID] [bigint] IDENTITY(1, 1) NOT NULL,
	[BlockID] [uniqueidentifier] NULL,
	[OwnerID] [uniqueidentifier] NULL,
	[Action] [varchar](20) NOT NULL,
	[Time] [datetime] NOT NULL,
	[Body] [nvarchar](max),
	[UserID] [uniqueidentifier] NOT NULL,
	[ApplicationID] [uniqueidentifier] NOT NULL
 CONSTRAINT [PK_WK_History] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UK_WK_History_BlockID] UNIQUE NONCLUSTERED 
(
	[BlockID] ASC,
	[ID] ASC,
	[OwnerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
CONSTRAINT [UK_WK_History_OwnerID] UNIQUE NONCLUSTERED 
(
	[OwnerID] ASC,
	[BlockID] ASC,
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


ALTER TABLE [dbo].[WK_History]  WITH CHECK ADD  CONSTRAINT [FK_WK_History_aspnet_Applications] FOREIGN KEY([ApplicationID])
REFERENCES [dbo].[aspnet_Applications] ([ApplicationId])
GO

ALTER TABLE [dbo].[WK_History] CHECK CONSTRAINT [FK_WK_History_aspnet_Applications]
GO

ALTER TABLE [dbo].[WK_History]  WITH CHECK ADD  CONSTRAINT [FK_WK_History_aspnet_Users] FOREIGN KEY([UserID])
REFERENCES [dbo].[aspnet_Users] ([UserId])
GO

ALTER TABLE [dbo].[WK_History] CHECK CONSTRAINT [FK_WK_History_aspnet_Users]
GO

ALTER TABLE [dbo].[WK_History]  WITH CHECK ADD  CONSTRAINT [FK_WK_History_WK_Blocks] FOREIGN KEY([BlockID])
REFERENCES [dbo].[WK_Blocks] ([BlockID])
GO

ALTER TABLE [dbo].[WK_History] CHECK CONSTRAINT [FK_WK_History_WK_Blocks]
GO
