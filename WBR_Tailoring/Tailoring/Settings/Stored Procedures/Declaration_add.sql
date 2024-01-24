CREATE PROCEDURE [Settings].[Declaration_add]
	@declaration_number  VARCHAR(200),
	@start_date DATE,
	@end_date DATE,
	@declaration_type_id INT
AS

IF @start_date > @end_date
	BEGIN
	    RAISERROR('Не корректные даты', 16, 1)
	    RETURN
	END

INSERT INTO [Settings].[Declarations]
           ([declaration_number]
           ,[start_date]
           ,[end_date]
		   ,[declaration_type_id])
     VALUES
           (@declaration_number
           ,@start_date
           ,@end_date
		   ,@declaration_type_id);

SELECT SCOPE_IDENTITY() as id ; --последний вставленный идентификатор в рамках текущего сеанса