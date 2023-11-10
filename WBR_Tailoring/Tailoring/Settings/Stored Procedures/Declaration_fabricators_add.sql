CREATE PROCEDURE [Settings].[Declaration_fabricators_add]
	@declaration_id  INT,
	@fabricator_id INT
AS

INSERT INTO [Settings].[Declaration_Fabricators]
           ([declaration_id]
           ,[fabricator_id])
     VALUES
           (@declaration_id
           ,@fabricator_id);