CREATE PROCEDURE [Settings].[Declaration_Fabricators_UPD]
	@declaration_id  INT,
	@fabricator_id INT,
	@flag INT --1-добавление, 0-удаление
AS

IF @flag = 1 
BEGIN
	IF NOT EXISTS (SELECT * FROM  Settings.Declaration_Fabricators  WHERE declaration_id = @declaration_id and fabricator_id = @fabricator_id)

	INSERT INTO [Settings].[Declaration_Fabricators]
			   ([declaration_id]
			   ,[fabricator_id])
		 VALUES
			   (@declaration_id
			   ,@fabricator_id)
END

IF @flag = 0 
BEGIN
	IF  EXISTS (SELECT  * FROM Settings.Declaration_Fabricators WHERE declaration_id = @declaration_id and fabricator_id = @fabricator_id)
	DELETE FROM Settings.Declaration_Fabricators WHERE fabricator_id = @fabricator_id AND  declaration_id = @declaration_id 
END