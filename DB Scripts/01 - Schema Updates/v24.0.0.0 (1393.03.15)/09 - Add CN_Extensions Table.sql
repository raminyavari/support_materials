USE [EKM_App]
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