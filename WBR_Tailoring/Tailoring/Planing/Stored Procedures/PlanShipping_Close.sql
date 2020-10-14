CREATE PROCEDURE [Planing].[PlanShipping_Close]
	@ps_id INT,
	@employee_id INT
AS
	SET NOCOUNT ON
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Planing.PlanShipping ps
	   	WHERE	ps.ps_id = @ps_id
	   )
	BEGIN
	    RAISERROR('Плановой отгрузки с кодом %d не существует', 16, 1, @ps_id)
	    RETURN
	END
	
	BEGIN TRY
		UPDATE	Planing.PlanShipping
		SET 	close_dt              = @dt,
				close_employee_id     = @employee_id
		WHERE	ps_id                 = @ps_id
				AND	close_dt IS NULL
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
		
		RAISERROR('Ошибка %d в строке %d  %s', @esev, @estate, @ErrNum, @Line, @Mess) 
		WITH LOG;
	END CATCH 