use [EKM_App]
go


INSERT INTO [dbo].[AccessRoles]
           ([ID]
           ,[Role]
           ,[Title])
     VALUES
           (NEWID()
           ,N'ManageOntology'
           ,N'ویرایش آنتالوژی')
GO