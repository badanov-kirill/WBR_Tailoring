CREATE PROCEDURE Settings.Declarations_TNVED_UPD
	@declaration_id  INT,
	@tnved_id INT,
	@flag INT --1-добавление, 0-удаление
AS

IF @flag = 1 
BEGIN
	IF NOT EXISTS (SELECT * FROM  Settings.Declarations_TNVED  WHERE declaration_id = @declaration_id and tnved_id = @tnved_id)

	INSERT INTO [Settings].[Declarations_TNVED]
			   ([declaration_id]
			   ,[tnved_id])
		 VALUES
			   (@declaration_id
			   ,@tnved_id)
END

IF @flag = 0 
BEGIN
	IF  EXISTS (SELECT  * FROM Settings.Declarations_TNVED  WHERE declaration_id = @declaration_id and tnved_id = @tnved_id)
	DELETE FROM Settings.Declarations_TNVED WHERE tnved_id = @tnved_id AND  declaration_id = @declaration_id 
END