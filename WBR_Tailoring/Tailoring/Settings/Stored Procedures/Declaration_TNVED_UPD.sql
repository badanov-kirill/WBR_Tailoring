CREATE PROCEDURE Settings.Declaration_TNVED_UPD
	@declaration_id INT,
	@tnved_id INT,
	@flag INT
AS

IF EXISTS(Select * from Settings.Declarations_TNVED WHERE declaration_id = @declaration_id and tnved_id = @tnved_id ) AND @flag = 0
DELETE Settings.Declarations_TNVED WHERE declaration_id = @declaration_id and tnved_id = @tnved_id;

IF NOT EXISTS(Select * from Settings.Declarations_TNVED WHERE declaration_id = @declaration_id and tnved_id = @tnved_id ) AND @flag = 1
INSERT INTO [Settings].[Declarations_TNVED]
           ([declaration_id]
           ,[tnved_id])
     VALUES
           (@declaration_id
           ,@tnved_id);