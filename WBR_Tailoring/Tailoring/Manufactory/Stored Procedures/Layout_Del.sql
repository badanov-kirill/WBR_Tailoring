CREATE PROCEDURE [Manufactory].[Layout_Del]
	@layout_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON	
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Manufactory.Layout l
	   	WHERE	l.layout_id = @layout_id
	   )
	BEGIN
	    RAISERROR('Раскладки с кодом %d не существует.', 16, 1, @layout_id)
	    RETURN
	END
	
	BEGIN TRY
		UPDATE	Manufactory.Layout
		SET 	dt              = @dt,
				employee_id     = @employee_id,
				is_deleted      = 1
		WHERE	layout_id       = @layout_id
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