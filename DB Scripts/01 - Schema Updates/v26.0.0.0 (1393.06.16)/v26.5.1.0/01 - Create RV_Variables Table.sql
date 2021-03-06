USE [EKM_App]
GO


CREATE TABLE [dbo].[RV_Variables](
	[Name]					VARCHAR(50) NOT NULL,
	[Value]					NVARCHAR (max) NOT NULL,
	[LastModifierUserID]	UNIQUEIDENTIFIER,
	[LastModificationDate]	DATETIME NOT NULL
 CONSTRAINT [PK_RV_Variables] PRIMARY KEY CLUSTERED 
(
	[Name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


ALTER TABLE [dbo].[RV_Variables] WITH CHECK ADD CONSTRAINT [FK_RV_Variables_aspnet_Users] FOREIGN KEY([LastModifierUserID])
REFERENCES [dbo].[aspnet_Users] ([UserID])
GO

ALTER TABLE [dbo].[RV_Variables] CHECK CONSTRAINT [FK_RV_Variables_aspnet_Users]
GO

