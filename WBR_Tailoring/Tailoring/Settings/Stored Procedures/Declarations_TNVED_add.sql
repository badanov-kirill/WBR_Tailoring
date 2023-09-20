CREATE PROCEDURE Settings.Declarations_TNVED_add
	@declaration_id  INT,
	@tnved_id INT
AS

INSERT INTO [Settings].[Declarations_TNVED]
           ([declaration_id]
           ,[tnved_id])
     VALUES
           (@declaration_id
           ,@tnved_id)