﻿CREATE PROCEDURE [Reports].[TimeTracking_StateUpd]
	@tt_id INT,
	@tt_state_id TINYINT,
	@employee_id INT
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @dt DATETIME2(0) = GETDATE()
	
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Settings.EmployeeSetting es
	   	WHERE	es.employee_id = @employee_id
	   )
	BEGIN
	    RAISERROR('Сотрудника с кодом %d не существует', 16, 1, @employee_id)
	    RETURN
	END
	
	IF NOT EXISTS (
	   	SELECT	1
	   	FROM	Reports.TimeTracking tt
	   	WHERE	tt.tt_id = @tt_id
	   )
	BEGIN
	    RAISERROR('Строки с кодом %d не существует', 16, 1, @tt_id)
	    RETURN
	END
	
	BEGIN TRY
		BEGIN TRANSACTION 
		
		UPDATE	Reports.TimeTracking
		SET 	tt_state_id = @tt_state_id,
				dt = @dt,
				employee_id = @employee_id
		WHERE	tt_id = @tt_id
		
		INSERT INTO History.TimeTracking
			(
				tt_id,
				dt,
				employee_id,
				tt_state_id
			)
		VALUES
			(
				@tt_id,
				@dt,
				@employee_id,
				@tt_state_id
			)	
		
		COMMIT TRANSACTION
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