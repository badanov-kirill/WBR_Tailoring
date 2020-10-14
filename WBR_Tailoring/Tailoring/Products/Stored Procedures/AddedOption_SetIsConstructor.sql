CREATE PROCEDURE [Products].[AddedOption_SetIsConstructor]
	@ao_id INT,
	@employee_id INT,
	@is_constructor BIT
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	IF NOT EXISTS(
	   	SELECT	1
	   	FROM	Products.AddedOption ao
	   	WHERE	ao.ao_id = @ao_id
	   )
	BEGIN
	    RAISERROR('Дополнительной опции с кодом %d не существует', 16, 1, @ao_id)
	    RETURN
	END
	
	BEGIN TRY
		UPDATE	Products.AddedOption
		SET 	is_constructor     = @is_constructor,
				dt                 = @dt,
				employee_id        = @employee_id
		WHERE	ao_id              = @ao_id
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
		    ROLLBACK TRANSACTION
		
		DECLARE @ErrNum INT = ERROR_NUMBER();
		DECLARE @estate INT = ERROR_STATE();
		DECLARE @esev INT = ERROR_SEVERITY();
		DECLARE @Line INT = ERROR_LINE();
		DECLARE @Mess VARCHAR(MAX) = CHAR(10) + ISNULL('Процедура: ' + ERROR_PROCEDURE(), '') 
		        + CHAR(10) + ERROR_MESSAGE();
		
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) WITH LOG;
	END CATCH 